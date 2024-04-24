module Phidrates5

using DelimitedFiles, Printf


function main()
    #============#
    # INITIALIZE #
    #============#
    #===============#
    # RAD FUNCTIONS #
    #===============#
    input = open("Input", "r") # Input parameters:  Sol, BB, IS, AS, T, etc.
    mode = readline(input)
    # define angst_flux and fluxes and pass them into functions, rather than create them inside of functions
    if mode === "Sol"
        SA = parse(Float64, readline(input))
        nF = 324
        @time solrad(SA)
    elseif mode === "BB "
        println(stderr, "dumSA = ", readline(input))
        T = parse(Float64, readline(input))
        @time bbrad(T)
    elseif mode === "IS "
        @time israd()
    else error("Unrecognized radiation field. Supply a valid radiation field (\"Sol,\" \"BB ,\" \"IS ,\")")
    end

        
    #========#
    # BRANCH #
    #========#
    brnout = open("BrnOut", "w+")

    Hrec = open("Hrec", "r")
    _Hrec = replace(read(Hrec, String), "E 0"=>"E0")
    data::Array{Any} = readdlm(IOBuffer(_Hrec))
    ln::Int16 = 2

    pangstN = data[1, 1]
    pangst1 = data[1, 2]
    pangstL = data[1, 3]

    parent1 = data[1, 4]
    parent2 = data[1, 5]

    branch_names[1] = parent2
    thresholds[1] = pangstL

    limit = false
    
    # Read References for Parent Molecule:
    println(brnout, "0          References for Cross Section of ", rpad(parent1, 8), rpad(parent2, 8))
    while data[ln, 1] isa AbstractString
        println(brnout, join(data[ln, :], ' '))
        ln += 1
    end
    tot_rates = Vector{Float64}(undef, pangstN)
    xsctn_table = Matrix{Float64}(undef, pangstN, 16)

    # Read Wavelengths and Cross Sections for Parent Molecule
    angsts = Vector{Float64}(undef, pangstN)
    xsctns = Vector{Float64}(undef, pangstN)
    for i in 1:pangstN
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
        angstsB = Vector{Float64}(undef, pangstN)
        xsctnsB = Vector{Float64}(undef, pangstN)

        ln += 1

        for s in 1:num_sets
            bangstN = data[ln, 1]
            bangst1 = data[ln, 2]
            bangstL = data[ln, 3]
            
            bname1 = data[ln, 4]
            bname2 = data[ln, 5]

            category[s] = data[ln, 7]

            ln += 1

            branch_names[s] = bname2
            thresholds[s] = bangstL

            # Write references for branching set to file
            println(brnout, "0          References for Cross Section of ", lpad(bname1, 8), lpad(bname2, 8))
            while data[ln, 1] isa AbstractString
                println(brnout, join(data[ln, :], ' '))
                ln += 1
            end

            pangst1 = max(pangst1, bangst1)
            pangstL = min(pangstL, bangstL)
            
            for i in 1:bangstN
                angstsB[i] = data[ln, 1]
                xsctnsB[i] = data[ln, 2]
                
                ln += 1
            end

            for i in 1:pangstN # iterate thru wavelengths
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
        end
        num_sets += 1

        thresholds[num_sets] = data[ln, 3]
        prod1 = data[ln, 4]
        lastN = data[ln, 5]
        branch_nums[num_sets] = data[ln, 6]
        category[num_sets] = data[ln, 7]
        
        branch_names[num_sets] = lastN

        for i in 1:pangstN # iterate through parent wavelengths
            temp = 1.0 - tot_rates[i]
            if temp < -1.0E-6
                println(stderr, "$parent1, temp < -1.0e-6: $temp around wavelength: ", angsts[i])
            elseif temp < 0.0
                temp = 0.0
            else
            end
            xsctn_table[i, num_sets] = temp * xsctns[i]
        end
    end
   
    println(brnout, "\n0 Branching ratio for ", lpad(parent1, 8), lpad(parent2, 8), "    ", num_sets, " branches")
    if num_sets < 10
        # first row
        print(brnout, " Lambda  Total")
        for i in 1:num_sets print(brnout, rpad(branch_names[i], 8)) end
        println(brnout)
        # following rows
        for i in 1:pangstN
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
        for i in 1:pangstN
            @printf(brnout, "%7.1f %8.2e", angsts[i], xsctns[i])
            for j in 1:num_sets @printf(brnout, " %8.2e", xsctn_table[i,j]) end
            println(brnout)
        end
    end

    close(Hrec)
    close(brnout)
    
    #========#
    # FOTRAT #
    #========#
    data::Array{Any} = readdlm(fort4)
    ln = 1

    fort16 = open("fort.16", "a+")
    seekstart(fort16)

    last = 0
    maxN = 0

    xsctn_tbl = Matrix{Float64}(undef, MAX_ANGSTS, 16)

    angsts = Vector{Float64}(undef, MAX_ANGSTS + 1)
    xsctns = Vector{Float64}(undef, MAX_ANGSTS + 2)

    fix_xsctns = Vector{Float64}(undef, MAX_ANGSTS)
    fix_angsts = Vector{Float64}(undef, MAX_ANGSTS) # + 2

    rate_tbl = Matrix{Float64}(undef, MAX_ANGSTS, 16)

    rates = zeros(Float64, 16)
    branch_names = fill("", 16)

    min_pr = typemax(Int)
    max_pr = 0

    num_sets = data[ln, 1]
    println(stderr, num_sets, " sets")

    for s in 1:num_sets
        ln += 1
        # Note: in contrast to the variables in branch.jl, these represent the current branch's information
        pangstN::Int16 = data[ln, 1]
        pangst1::Float64 = data[ln, 2]
        pangstL::Float64 = data[ln, 3]
        name1 = data[ln, 4]
        name2 = data[ln, 5]

        branch_names[s] = name2

        for i in 1:pangstN
            ln += 1
            angsts[i] = data[ln, 1]::Float64
            xsctns[i] = data[ln, 2]::Float64
        end

        if pangst1 - pangstL >= -1.0e-6 || pangst1 < angst_flux[1] || pangstL > angst_flux[nF]
            break
        end

        # get ranges of flux angstroms w.r.t min/max angstrom 
        n1 = 0
        nL = 0
        for i in 1:nF
            if angst_flux[i] - pangst1 <= 1e-6
                n1 = i
            end
            if angst_flux[i] < pangstL
                nL = i
            end
        end
        
        min_pr = min(n1, min_pr)
        max_pr = max(nL, max_pr)
        
        nL <= n1 && break
        
        fix_angsts[1] = pangst1
        fix_xsctns[1] = max(xsctns[1] - (xsctns[2] - xsctns[1]) * (angsts[1] - pangst1) / (angsts[2] - angsts[1]), 1.0e-30)

        j = 1
        n = n1 + 1
        for i in 1:pangstN
            while true
                j += 1
                if angsts[i] - angst_flux[n] < -1.0e-6
                    fix_angsts[j] = angsts[i]
                    fix_xsctns[j] = xsctns[i]
                    break
                elseif abs(angsts[i] - angst_flux[n]) <= 1.0e-6
                    fix_angsts[j] = angsts[i]
                    fix_xsctns[j] = xsctns[i]
                    n += 1
                    break
                else
                    fix_angsts[j] = angst_flux[n]
                    fix_xsctns[j] = fix_xsctns[j-1] + (xsctns[i] - fix_xsctns[j-1])*(angst_flux[n] - fix_angsts[j-1])/(angsts[i] - fix_angsts[j-1])
                    n += 1
                end
            end
        end

        # fill remaining slots
        if n <= nL
            for i in n:nL
                j += 1
                fix_angsts[j] = angst_flux[i]
                fix_xsctns[j] = max(xsctns[pangstN-1] + (xsctns[pangstN-1] - xsctns[pangstN]) * (angst_flux[i] - angsts[pangstN-1]) / (angsts[pangstN] - angsts[pangstN-1]), 1e-30)
            end
        end

        # compute last cross section
        fix_angsts[j+1] = pangstL
        xsctns[j+1] = max(xsctns[pangstN-1] + (xsctns[pangstN-1] - xsctns[pangstN]) * (pangstL - angsts[pangstN-1]) / (angsts[pangstN] - angsts[pangstN - 1]), 1E-30)

        n = n1
        maxN = n1 - 1

        # x[n] = 0.0
        xt = 0.0
        xsct1 = 0.5fix_xsctns[1]

        # Compute cross section per wavelength per bin
        for k in 1:j
            xsct2 = 0.5fix_xsctns[k+1]
            xt += 0.5(fix_xsctns[k+1] + fix_xsctns[k]) * (fix_angsts[k+1] - fix_angsts[k])
            xsct1 = xsct2
            if k == j
                tmp_xsctn = xt / (angst_flux[n+1] - angst_flux[n])
                xsctn_tbl[n, s] = tmp_xsctn
                if tmp_xsctn <= 1.0E-30
                    last += 1
                    if tmp_xsctn < 0.0
                        xsctn_tbl[n, s] = 0.0
                    else#if tmp_xsctn < 1.0E-30
                        xsctn_tbl[n, s] = 1.0E-35
                    end
                end
                rate_tbl[n, s] = tmp_xsctn * fluxes[n]
            else
                if fix_angsts[k+1] >= angst_flux[n+1]
                    tmp_xsctn = xt / (angst_flux[n+1] - angst_flux[n])
                    xsctn_tbl[n, s] = tmp_xsctn
                    rate_tbl[n, s] = tmp_xsctn * fluxes[n]

                    if tmp_xsctn > 1.0E-30
                        last = 0 
                    else 
                        last += 1
                    end

                    rates[s] += tmp_xsctn * fluxes[n]

                    n += 1
                    xt = 0
                end
            end
        end
    end

    ratout  = open("RatOut", "w+") # Binned rate coefficients per Angstrom.
    fotout  = open("FotOut", "w+") # Binned Cross Sections.

    fmtd_num_sets = lpad(num_sets, 2) * " "^49 * lpad(name1, 8)
    println(fotout, fmtd_num_sets)
    println(ratout, fmtd_num_sets)

    fmtd_names = join(rpad.(branch_names[1:16], 8),' ')
    println(fotout, " Lambda         ", fmtd_names)
    println(ratout, " Lambda         ", fmtd_names)

    for i in min_pr:max_pr 
        print(fotout, fmtfloat(angst_flux[i], 7, 1), "        ")
        print(ratout, fmtfloat(angst_flux[i], 7, 1), "        ")
        for j in 1:num_sets
            @printf(fotout, "%9.2e", xsctn_tbl[i, j])
            @printf(ratout, "%9.2e", rate_tbl[i, j])
        end
        println(fotout)
        println(ratout)
    end

    print(fotout, fmtfloat(angst_flux[max_pr + 1], 7, 1))
    print(ratout, fmtfloat(angst_flux[max_pr + 1], 7, 1))
    for i in 1:num_sets
        r = rates[i]
        rates[i] = r < 1.0e-99 ? 0 : r
    end

    print(ratout, "\n Rate Coeffs. = ")
    for j in 1:num_sets
        @printf(ratout, " %8.2e", rates[j])
    end

    total_xsctns = Vector{Float64}(undef, nF)

    for i in 1:nF
        for j in 1:16
            total_xsctns[i] += xsctn_tbl[i, j]
        end
    end
    
    close(ratout)
    close(fotout)


    #=========#
    # CONVERT #
    #=========#
    # Declarations
    branch_names = fill("", 16)
    name1 = ""
    name2 = ""
    
    binned_rates = zeros(Float64, 16)
    binned_excess_energies = zeros(Float64, 16)
    xsects = Vector{Float64}(undef, 9999)
    excess_energies = Matrix{Float64}(undef, MAX_ANGSTS, 16)

    # File reading
    eioniz = open("EIoniz", "w+")
    eeout = open("EEOut", "w+") # Binned excess energies per Angstrom.
    summary = open("Summary", "w+")
    
    fort4 = open("fort.4", "a+") |> seekstart
    num_sets::Int16 = parse(Int, readline(fort4))
    close(fort4)

    fort16 = open("fort.16", "a+") |> seekstart
    data = readdlm(fort16)
    ln = 1
    
    maxbin::UInt16 = 0
   
    for s in 1:num_sets
        maxN = data[ln, 1]
        if maxN < 0 return
        elseif maxN > 9999 
            println(stderr, "Stop (maxN > 9999)") 
            return
        end
        ln += 1
        
        maxbin = max(maxN, maxbin)

        flag = flags[s]
        thresh = thresholds[s]
       
        name1 = data[ln, end-1]
        name2 = data[ln, end]
        
        j = 1
        for i in 1:5:maxN
            for k in 1:5
                xsects[j] = data[ln, k+1]
                j += 1
            end
            ln += 1
        end
        
        flag && continue

        println(eioniz, "Begin EIoniz")
        @printf(eioniz, " %5i%5i           %8s            %8s\n", branch_nums[s], category[s], name1, name2)
        println(eioniz, "0   Wavelength Range X-Section    Flux      Rate     E Excess   Sum")

        branch_names[s] = name2

        if num_sets <= 0 
            num_sets = 1 
        end

        isone(s) && println(eeout, lpad(num_sets, 2), " "^49, lpad(name1, 8))

        total_rate = 0.0
        total_energy = 0.0

        for i in 1:maxN
            ang1 = angst_flux[i]
            ang2 = angst_flux[i + 1]

            rate = xsects[i] * fluxes[i]

            ang1 = ang1 < 1.0E-06 ? 0.1 : min(ang1, thresh)
            ang2 = min(ang2, thresh)

            angL = 2ang1*ang2 / (ang1 + ang2)# 2.0*Wave1*Wave2/(Wave1 + Wave2)
            ele_energy = ANG_EV/angL - ANG_EV/thresh
            excess_energies[i, s] = ele_energy * rate
            total_energy += ele_energy * rate
            total_rate += rate
        
            # (1x, 2f10.2, 1p3e10.3, 0pf10.2, 1pe10.3)
            @printf(eioniz, " %10.2f%10.2f%10.3e%10.3e%10.3e%10.2f%10.3e\n", ang1, ang2, xsects[i], fluxes[i], rate, ele_energy, total_energy)
        end

        if total_rate < 1.0e-265
            total_rate = 0.0
            average_energy = 0.0
        else
            average_energy = total_energy / total_rate
        end

        @printf(eioniz, "0%46s  Total Rate =%10.3e\n", " ", total_rate)
        @printf(eioniz, "%43s Average Energy =%7.3f\n", " ", average_energy)

        binned_rates[s] = total_rate
        binned_excess_energies[s] = average_energy

        for i in 1:maxN
            excess_energies[i, s] = max(ifelse(binned_rates[s] < 1.0e-265, 0.0, excess_energies[i, s] / total_rate), 0)
        end
    end

    println(eeout, " Lambda         ", join(lpad.(branch_names, 8), ' '))
    for i in 1:maxbin
        @printf(eeout, "%7.1f         ", angst_flux[i])
        for j in 1:num_sets
            @printf(eeout, " %8.2e", excess_energies[i, j])
        end
        println(eeout)
    end

    @printf(eeout, "%7.1f\n", angst_flux[maxbin+1])

    print(eeout, " Rate Coeffs. = ")
    for i in 1:num_sets 
        @printf(eeout, " %8.2e", binned_rates[i])
    end
    println(eeout)

    println(summary, lpad("-->"*name1, 13), join(lpad.(branch_names[1:num_sets], 8), ' '))

    print(summary, " Rate Coeffs. = ")
    for i in 1:num_sets @printf(summary, " %8.2e", binned_rates[i])
    end
    println(summary)

    print(eeout, " Av. Excess E = ")
    print(summary, " Av. Excess E = ")
    for i in 1:num_sets 
        @printf(eeout, " %8.2e", binned_excess_energies[i])
        @printf(summary, " %8.2e", binned_excess_energies[i])
    end
    println(eeout)
    println(summary)

    close(eioniz)
    close(eeout)
    close(summary)
end

end