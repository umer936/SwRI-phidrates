using DelimitedFiles, Printf

struct Branch
    name::AbstractString
    num::Integer
    cat::Integer
    flag::Integer
    thresh::AbstractFloat
end

function branch()
    fort4 = open("fort.4", "w+") # Temporary file for wavelengths and cross sections.
    brnout = open("BrnOut", "w+")

    # Read Parent Molecule Information:
    Hrec = open("Hrec", "r")
    _Hrec = replace(read(Hrec, String), "E 0"=>"E0")
    data::Array{Any} = readdlm(IOBuffer(_Hrec))
    ln::Int16 = 2
    
    angstN = data[1, 1]
    angst1 = data[1, 2]
    angstL = data[1, 3]

    parent1 = data[1, 4]
    parent2 = data[1, 5]

    branch_names[1] = parent2
    thresholds[1] = angstL

    limit = false
    
    # Read References for Parent Molecule:
    println(brnout, "0          References for Cross Section of ", rpad(parent1, 8), rpad(parent2, 8))
    while data[ln, 1] isa AbstractString
        println(brnout, join(data[ln, :], ' '))
        ln += 1
    end
    tot_rates = Vector{Float64}(undef, angstN)
    xsctn_table = Matrix{Float64}(undef, angstN, 16)

    # Read Wavelengths and Cross Sections for Parent Molecule
    angsts = Vector{Float64}(undef, angstN)
    xsctns = Vector{Float64}(undef, angstN)
    for i in 1:angstN
        angsts[i] = data[ln, 1]
        xsctns[i] = data[ln, 2]

        ln += 1
    end

    # Read Number of Branching Sets
    num_sets = data[ln, 1]

    branch_names[num_sets + 2] = parent1
    branch_nums[num_sets + 2] = 0
    category[num_sets + 2] = 0
    flags[num_sets + 2] = true

    if num_sets != 0
        println(fort4, num_sets + 1)

        angstsB = Vector{Float64}(undef, angstN)
        xsctnsB = Vector{Float64}(undef, angstN)

        ln += 1

        for s in 1:num_sets
            bangstN = data[ln, 1]
            bangst1 = data[ln, 2]
            bangstL = data[ln, 3]
            
            prod1 = data[ln, 4]
            prod2 = data[ln, 5]

            category[s] = data[ln, 7]

            ln += 1

            branch_names[s] = prod2
            thresholds[s] = bangstL

            # Write references for branching set to file
            println(brnout, "0          References for Cross Section of ", lpad(prod1, 8), lpad(prod2, 8))
            while data[ln, 1] isa AbstractString
                println(brnout, join(data[ln, :], ' '))
                ln += 1
            end

            angst1 = max(angst1, bangst1)
            angstL = min(angstL, bangstL)
            
            for i in 1:bangstN
                angstsB[i] = data[ln, 1]
                xsctnsB[i] = data[ln, 2]
                
                ln += 1
            end

            for i in 1:angstN # iterate thru wavelengths
                for j in 1:bangstN # iterate thru branch data
                    branch_prob = 0
                    if angsts[i] > angstsB[j + 1] && !limit
                    else
                        if angsts[i] == angstsB[j + 1] # dont interpolate, the values are
                            branch_prob = xsctnsB[j + 1]
                        else
                            branch_prob = xsctnsB[j] + (xsctnsB[j + 1] - xsctnsB[j]) * (angsts[i] - angstsB[j]) / (angstsB[j+1] - angstsB[j])
                        end

                        if limit 
                            branch_prob = 0 
                        end

                        tot_rates[i] += branch_prob
                        xsctn_table[i, s] = branch_prob * xsctns[i]
                        break
                    end

                    limit = j + 1 >= bangstN && angsts[i] > angstsB[bangstN]
                end
            end

            @printf(fort4, "%10d%10.2f%10.2f%8s  %8s\n", angstN, angst1, angstL, parent1, prod2)
            for i in 1:angstN @printf(fort4, "%10.2f%10.2e\n", angsts[i], xsctn_table[i, s]) end
        end
        num_sets += 1

        thresholds[num_sets] = data[ln, 3]
        prod1 = data[ln, 4]
        lastN = data[ln, 5]
        branch_nums[num_sets] = data[ln, 6]
        category[num_sets] = data[ln, 7]
        
        branch_names[num_sets] = lastN

        for i in 1:angstN # iterate through parent wavelengths
            temp = 1.0 - tot_rates[i]
            if temp < -1.0E-6
                println(stderr, "$parent1, temp < -1.0e-6: $temp around wavelength: ", angsts[i])
            elseif temp < 0.0
                temp = 0.0
            else
            end
            xsctn_table[i, num_sets] = temp * xsctns[i]
        end

        # Temp file for wavelengths and cross Sections
        @printf(fort4, "%10i%10.2f%10.2f%8s  %8s\n", angstN, angst1, angstL, parent1, lastN)
        for i in 1:angstN @printf(fort4, "%10.2f%10.2e\n", angsts[i], xsctn_table[i, num_sets]) end
    else
        print(fort4, lpad(num_sets, 3))
        @printf(fort4, "%10i%10.2f%10.2f%8s  %8s\n", angstN, angst1, angstL, parent1, parent2)
        for i in 1:angstN @printf(fort4, "%10.2f%10.2e\n", angsts[i], xsctn_table[i, num_sets]) end
    end
   
    println(brnout, "\n0 Branching ratio for ", lpad(parent1, 8), lpad(parent2, 8), "    ", num_sets, " branches")
    if num_sets < 10
        # first row
        print(brnout, " Lambda  Total")
        for i in 1:num_sets print(brnout, rpad(branch_names[i], 8)) end
        println(brnout)
        # following rows
        for i in 1:angstN
            @printf(brnout, "%7.1f %8.2e", angsts[i], xsctns[i])
            for j in 1:num_sets @printf(brnout, " %8.2e", xsctn_table[i,j]) end
            println(brnout)
        end
    else
        # first row
        print(brnout, rpad("  Lambda "*parent2, 14))
        for i in 1:num_sets print(brnout, rpad(branch_names[i], 8)) end
        println(brnout)
        # following rows
        for i in 1:angstN
            @printf(brnout, "%7.1f %8.2e", angsts[i], xsctns[i])
            for j in 1:num_sets @printf(brnout, " %8.2e", xsctn_table[i,j]) end
            println(brnout)
        end
    end

    close(fort4)
    close(Hrec)
    close(brnout)
end