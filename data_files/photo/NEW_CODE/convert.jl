using DelimitedFiles, Printf

const ANG_EV = 12398.5
function convert()

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