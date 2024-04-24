module Phidrates3

using DelimitedFiles, Printf

include("print_values.jl")

struct BranchProfile{S<:Integer, T<:AbstractFloat, U<:AbstractString}
    angstN::S
    angst1::T
    angstL::T

    name1::U
    name2::U

    num::S
    cat::S
    flag::Bool
end

function BranchProfile(
    angstN::S, 
    angst1::T, 
    angstL::T,
    name1::U, 
    name2::U; 
    num::S=0, 
    cat::S=0,
    flag::Bool=true) where {S<:Integer, T<:AbstractFloat, U<:AbstractString}

    return BranchProfile{S, T, U}(angstN, angst1, angstL, name1, name2, num, cat, flag)
end

function main()
    #============#
    # INITIALIZE #
    #============#

    #========#
    # BRANCH #
    #========#
    brnout = open("BrnOut", "w+")

    # Read Parent Molecule Information:
    Hrec = open("Hrec", "r") |> seekstart
    _Hrec = replace(read(Hrec, String), "E 0"=>"E0")
    data::Array{Any} = readdlm(IOBuffer(_Hrec))
    ln::Int16 = 1

    parent = BranchProfile(data[ln, 1:5]..., 0, 0, true)
    ln += 1

    # Read References for Parent Molecule:
    println(brnout, "0          References for Cross Section of ", rpad(parent.name1, 8), rpad(parent.name2, 8))
    while data[ln, 1] isa AbstractString
        println(brnout, join(data[ln, :], ' '))
        ln += 1
    end

    # Read Wavelengths and Cross Sections for Parent Molecule
    angsts = Vector{Float64}(undef, parent.angstN)
    xsctns = Vector{Float64}(undef, parent.angstN) # Temporary!
    for i in 1:parent.angstN
        angsts[i] = data[ln, 1]
        xsctns[i] = data[ln, 2]
        ln += 1
    end

    # Read Number of Branching Sets (number of total sets - 1)
    num_sets = data[ln, 1]

    # Create data structures
    tot_rates = Vector{Float64}(undef, parent.angstN)
    xsctn_tbl = Matrix{Float64}(undef, parent.angstN, num_sets+1)
    branches::Vector{BranchProfile} = Vector{BranchProfile}(undef, num_sets+1)

    # Populate parent profiles
    if !iszero(num_sets)
        ln += 1
        for s in 1:num_sets
            branch = BranchProfile(data[ln, 1:7]..., true)
            ln += 1

            # Write references for branching set to file
            println(brnout, "0          References for Cross Section of ", lpad(branch.name1, 8), lpad(branch.name2, 8))
            while data[ln, 1] isa AbstractString
                println(brnout, join(data[ln, :], ' '))
                ln += 1
            end
            
            # Redefine parent with new angst1 and angstL
            parent = BranchProfile(parent.angstN, 
                                max(parent.angst1, branch.angst1), 
                                min(parent.angstL, branch.angstL), 
                                parent.name1, 
                                parent.name2, 
                                parent.num, 
                                parent.cat, 
                                parent.flag)
            
            # Read branch data
            bangsts = Vector{Float64}(undef, branch.angstN)
            bxsctns = Vector{Float64}(undef, branch.angstN)
            for i in 1:branch.angstN
                bangsts[i] = data[ln, 1]
                bxsctns[i] = data[ln, 2]
                ln += 1
            end

            limit = false
            for i in 1:parent.angstN # iterate thru wavelengths
                for j in 1:branch.angstN-1 # iterate thru branch data
                    prob = 0
                    if angsts[i] > bangsts[j + 1] && !limit
                    else
                        if angsts[i] == bangsts[j + 1] # dont interpolate, the values are
                            prob = bxsctns[j + 1]
                        else
                            prob = bxsctns[j] + (bxsctns[j + 1] - bxsctns[j]) * (angsts[i] - bangsts[j]) / (bangsts[j+1] - bangsts[j])
                        end

                        if limit 
                            prob = 0 
                        end

                        tot_rates[i] += prob
                        xsctn_tbl[i, s] = prob * xsctns[i]
                        break
                    end

                    limit = j + 1 >= branch.angstN && angsts[i] > bangsts[branch.angstN] #! chopping block
                end
            end
            branches[s] = branch
        end

        for i in 1:parent.angstN # iterate through parent wavelengths
            temp = 1.0 - tot_rates[i]
            if temp < -1.0e-6
                println(stderr, parent.name1, ", temp < -1.0e-6: ", temp, " around wavelength: ", angsts[i])
            elseif temp < 0.0
                temp = 0.0
            end
            xsctn_tbl[i, num_sets+1] = temp * xsctns[i]
        end

        branches[num_sets+1] = BranchProfile(parent.angstN, parent.angst1, parent.angstL, parent.name1, data[ln, 5:7]..., true)
    end

    close(Hrec)

    write_brnout(brnout, branches, angsts, xsctn_tbl)
    close(brnout)


    #=====#
    # RAD #
    #=====#
    angst_flux = Vector{Float64}(undef, nF+1)
    fluxes = Vector{Float64}(undef, nF+1)
    if mode === "Sol"
        SA = parse(Float64, readline(input))
        nF = 324
        nSA = 162

        @time angst_flux, fluxes = solrad(SA)
    elseif mode === "BB "
        println(stderr, "dumSA = ", readline(input))
        T = parse(Float64, readline(input))
        @time bbrad(T)
    elseif mode === "IS "
        @time israd()
    else error("Unrecognized radiation field. Supply a valid radiation field (\"Sol,\" \"BB ,\" \"IS ,\")")
    end


    #========#
    # FOTRAT #
    #========#

    fix_xsctns = Vector{Float64}(undef, nF)
    fix_angsts = Vector{Float64}(undef, nF) # + 2

    fot_xsctn = Matrix{Float64}(undef, nF, num_sets)

    tot_rates = zeros(Float64, num_sets)

    min_pr = typemax(Int)
    max_pr = 0

    for s in 1:num_sets
        angstN = branches[s].angstN
        angst1 = branches[s].angst1
        angstL = branches[s].angstL

        angst1 - angstL >= -1.0e-6 || angst1 < angst_flux[1] || angstL > angst_flux[nF] && break

        xsctns = xsctn_tbl[:, s]

        n1 = findlast(ang -> ang - angst1 <= 1.0E-6, angst_flux)
        nL = findlast(ang -> ang < angstL, angst_flux)

        nL <= n1 && break

        min_pr = min(n1, min_pr)
        max_pr = max(nL, max_pr)
        # min_pr, max_pr = extremes(n1, min_pr, max_pr, nL)
        
        # compute first cross section
        fix_angsts[1] = angst1
        fix_xsctns[1] = max(xsctns[1] - (xsctns[2] - xsctns[1]) * (angsts[1] - angst1) / (angsts[2] - angsts[1]), 1.0e-30)

        j = 1
        n = n1 + 1
        for i in 1:angstN
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
                fix_xsctns[j] = max(xsctns[angstN-1] + (xsctns[angstN-1] - xsctns[angstN]) * (angst_flux[i] - angsts[angstN-1]) / (angsts[angstN] - angsts[angstN-1]), 1e-30)
            end
        end

        # compute last cross section
        fix_angsts[j+1] = angstL
        fix_xsctns[j+1] = max(xsctns[angstN-1] + (xsctns[angstN-1] - xsctns[angstN]) * (angstL - angsts[angstN-1]) / (angsts[angstN] - angsts[angstN-1]), 1e-30)

        n = n1
        xt = 0.0

        # Compute cross section per wavelength per bin
        for k in 1:j
            xt += 0.5(fix_xsctns[k+1] + fix_xsctns[k]) * (fix_angsts[k+1] - fix_angsts[k])
            
            if k == j
                tmp_xsctn = xt / (angst_flux[n+1] - angst_flux[n])
                if tmp_xsctn <= 1.0e-30
                    if tmp_xsctn < 0.0
                        tmp_xsctn = 0.0
                    elseif tmp_xsctn < 1.0e-30
                        tmp_xsctn = 1.0e-35
                    end
                end
                fot_xsctn[n, s] = tmp_xsctn
                # rate_tbl[n, s] = tmp_xsctn * fluxes[n]
            else
                if fix_angsts[k+1] >= angst_flux[n+1]
                    tmp_xsctn = xt / (angst_flux[n+1] - angst_flux[n])
                    fot_xsctn[n, s] = tmp_xsctn
                    # rate_tbl[n, s] = tmp_xsctn * fluxes[n] # can be moved to the output section as xsctn_tbl[n, s] * fluxes[n]

                    tot_rates[s] += tmp_xsctn * fluxes[n] # can be moved to the output section val += xsctn_tbl[n, s] * fluxes[n]; print(val)

                    n += 1
                    xt = 0
                end
            end
        end
    end

    ratout  = open("RatOut", "w+") # Binned rate coefficients per Angstrom.
    fotout  = open("FotOut", "w+") # Binned Cross Sections.

    fmtd_num_sets = lpad(num_sets, 2) * " "^49 * lpad(branches[1].name1, 8)
    println(fotout, fmtd_num_sets)
    println(ratout, fmtd_num_sets)

    fmtd_names = join(rpad.(map(br -> br.name2, branches[2:end]), 8),' ')
    println(fotout, " Lambda         ", fmtd_names)
    println(ratout, " Lambda         ", fmtd_names)

    for i in min_pr:max_pr 
        print(fotout, fmtfloat(angst_flux[i], 7, 1), "        ")
        print(ratout, fmtfloat(angst_flux[i], 7, 1), "        ")
        for j in 1:num_sets
            @printf(fotout, "%9.2e", fot_xsctn[i, j])
            @printf(ratout, "%9.2e", fot_xsctn[i, j] * fluxes[i])
        end
        println(fotout)
        println(ratout)
    end

    print(fotout, fmtfloat(angst_flux[max_pr + 1], 7, 1))
    print(ratout, fmtfloat(angst_flux[max_pr + 1], 7, 1))

    print(ratout, "\n Rate Coeffs. = ")
    foreach(r -> @printf(ratout, " %8.2f", r < 1.0e-99 ? 0 : r), tot_rates)

    close(ratout)
    close(fotout)


    #=========#
    # CONVERT #
    #=========#
    binned_rates = zeros(Float64, num_sets)
    binned_excess_energies = zeros(Float64, num_sets)

    xsects = Vector{Float64}(undef, 9999)
    excess_energies = Matrix{Float64}(undef, MAX_ANGSTS, num_sets)

    eioniz = open("EIoniz", "w+")

    maxbin = 0

    for s in 1:num_sets
        branch = branches[s+1]

        maxbin = max(maxN, maxbin)

        name1 = branch.name1
        name2 = branch.name2

        flag = branch.flag
        thresh = branch.angstL
        
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
            total_rate += rate
            excess_energies[i, s] = ele_energy * rate
            total_energy += ele_energy * rate

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

    eeout = open("EEOut", "w+") # Binned excess energies per Angstrom.
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

    summary = open("Summary", "w+")

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