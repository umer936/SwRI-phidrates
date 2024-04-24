module Phidrates4

using DelimitedFiles, Printf#, StaticArrays, Profile, PProf, InteractiveUtils

include("rads.jl")
include("common.jl")
include("printfns.jl")

struct BranchProfile{S<:Integer, T<:Real, U<:AbstractString}
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
    flag::Bool=false) where {S<:Integer, T<:Real, U<:AbstractString}

    return BranchProfile{S, T, U}(angstN, angst1, angstL, name1, name2, num, cat, flag)
end

const ANG_EV::Float64 = 12398.5
const MAX_ANGSTS::Int32 = 50000
const MAX_BRANCHES::Int32 = 2000
const MAX_FLUX::Int32 = 1000
const nSA::Int32 = 162

function main()
    #============#
    # INITIALIZE #
    #============#
    run(`/bin/bash /usr/local/var/www/SwRI-phidrates/data_files/bash_cross_sections_jl.cgi`)
    cd(readchomp("/usr/local/var/www/SwRI-phidrates/data_files/photo/NEW_CODE/store.txt"))
    println(pwd())
    input = open("Input", "r")

    #=====#
    # RAD #
    #=====#
    mode = readline(input)
    nF::Int32 = mode == "Sol " ? 324 : 337
    
    # Data file output of solrad, bbrad, or israd
    angstflux = zeros(nF+1)
    fluxes = zeros(nF+1)

    if mode === "Sol"
        SA = parse(Float64, readline(input))::Float64
        nF = 324
        nSA = 162

        solrad!(angstflux, fluxes, SA)
    elseif mode === "BB "
        println(stderr, "dumSA = ", readline(input))

        T = parse(Float64, readline(input))::Float64
        bbrad!(angstflux, fluxes, T)
    elseif mode === "IS "
        israd!(angstflux, fluxes)
    else 
        error("Unrecognized radiation field. Supply a valid radiation field (\"Sol,\" \"BB ,\" \"IS ,\")")
    end

    #========#
    # BRANCH #
    #========#
    brnout::IO = open("BrnOut", "w+") # Wavelengths and cross sections for branches. 2
    ratout::IO = open("RatOut", "w+") # Binned rate coefficients per Angstrom. 3
    fotout::IO = open("FotOut", "w+") # Binned Cross Sections. 15
    eioniz::IO = open("EIoniz", "w+") # Binned rates and excess energies. 9
     eeout::IO = open("EEOut", "w+")  # Binned excess energies per Angstrom. 19


    # Read Parent Molecule Information:
    # Input data (HRec):  Species name, wavelengths, cross sections, branching ratios, etc. 1
    Hrec::IO = open("Hrec", "r") |> seekstart 
    _Hrec = replace(read(Hrec, String), "E 0"=>"E0")
    data::Array{Union{SubString{String}, Int64, Float64}} = readdlm(IOBuffer(_Hrec))
    ln::Int64 = 1

    parent = BranchProfile(data[ln, 1:5]..., 0, 0, false)
    # parent = BranchProfile(data[ln, 1]::Int64, data[ln, 2]::Float64, data[ln, 3]::Float64, String(data[ln, 4]), String(data[ln, 5]), 0, 0, false)
    pangstN::Int64   = parent.angstN
    pangst1::Float64 = parent.angst1
    pangstL::Float64 = parent.angstL
    ln += 1

    # Read References for Parent Molecule:
    println(brnout, "0          References for Cross Section of ", rpad(parent.name1, 8), rpad(parent.name2, 8))
    while data[ln, 1] isa AbstractString
        println(brnout, join(data[ln, :], ' '))
        ln += 1
    end

    # Read Wavelengths and Cross Sections for Parent Molecule
    pangsts = zeros(pangstN)
    pxsctns = zeros(pangstN)
    for i in 1:pangstN
        pangsts[i] = data[ln, 1]::Float64
        pxsctns[i] = data[ln, 2]::Float64
        ln += 1
    end

    fangsts = zeros(nF)
    fxsctns = zeros(nF)

    min_pr = typemax(Int)
    max_pr = zero(min_pr)

    last = 0

    # Read Number of Branching Sets (number of total sets - 1)
    num_sets::Int64 = data[ln, 1] + 1
    bangsts = zeros(MAX_ANGSTS)
    bxsctns = zeros(MAX_ANGSTS)

    # Create data structures
    branches::Vector{BranchProfile} = Vector{BranchProfile}(undef, num_sets) # Branch
    # branch_names = Vector{String}(undef, num_sets)
    
    xsctn_tbl = zeros(pangstN, num_sets) # Branch
    xsctn_fot = zeros(nF, num_sets) # Fotrat
    tot_rates = zeros(pangstN) # Branch
    
    binned_rates = zeros(num_sets) # Convert
    binned_excess_energies = zeros(num_sets) # Convert
    excess_energies = zeros(nF, num_sets) # Convert

    max_bin = 0 

    bangstN::Int64 = 0
    bangst1::Float64 = 0.0
    bangstL::Float64 = 0.0
    if !iszero(num_sets)
        ln += 1
        for s in 1:num_sets
            if s == num_sets
                for i in 1:pangstN # iterate through parent wavelengths
                    temp = 1.0 - tot_rates[i]
                    if temp < -1.0e-6
                        println(stderr, parent.name1, ", temp < -1.0e-6: ", temp, " around wavelength: ", pangsts[i])
                    elseif temp < 0.0
                        temp = 0.0
                    end
                    xsctn_tbl[i, num_sets] = temp * pxsctns[i]
                end

                branch = BranchProfile(pangstN, pangst1, pangstL, parent.name1, data[ln, 5:7]..., false)

                bangstN = parent.angstN
                bangst1 = parent.angst1
                bangstL = parent.angstL
                # branch_names[s] = data[ln, 5]
            else
                branch = BranchProfile(data[ln, 1:7]..., false)

                #=
                bangstN = branch.angstN
                bangst1 = branch.angst1
                bangstL = branch.angstL
                bname1 = branch.name1
                bname2 = branch.name2
                =#
                # branch_names[s] = data[ln, 5]
                bangstN, bangst1, bangstL, bname1, bname2 = data[ln, 1:5]

                ln += 1

                # Write references for branching set to file
                println(brnout, "0          References for Cross Section of ", lpad(bname1, 8), lpad(bname2, 8))
                while data[ln, 1] isa AbstractString
                    println(brnout, join(data[ln, :], ' '))
                    ln += 1
                end
                
                # Redefine parent with new angst1 and angstL
                pangst1 = max(pangst1, bangst1)
                pangstL = min(pangstL, bangstL)

                # Read branch data
                for i in 1:bangstN
                    bangsts[i] = data[ln, 1]::Float64
                    bxsctns[i] = data[ln, 2]::Float64
                    ln += 1
                end
                
                limit = false
                for i in 1:pangstN # iterate thru wavelengths
                    for j in 1:bangstN # iterate thru branch data
                        prob = 0
                        if pangsts[i] > bangsts[j+1] && !limit
                        else
                            if pangsts[i] == bangsts[j+1]
                                prob = bxsctns[j+1]
                            else
                                prob = bxsctns[j] + (bxsctns[j+1] - bxsctns[j]) * (pangsts[i] - bangsts[j]) / (bangsts[j+1] - bangsts[j])
                            end

                            if limit 
                                prob = 0 
                            end

                            tot_rates[i] += prob
                            xsctn_tbl[i, s] = prob * pxsctns[i]
                            break
                        end

                        limit = j + 1 >= bangstN && pangsts[i] > bangsts[bangstN]
                    end
                end
            end
            branches[s] = branch
            
            bangsts::Vector{Float64} = pangsts
            bxsctns = view(xsctn_tbl, :, s)
            if bangst1 - bangstL >= -1.0e-6 || bangst1 < angstflux[1] || bangstL > angstflux[nF] 
                error("Unusable wavelength range. Check the data for this $bname1")
            end
            
            n1 = findlast(ang -> ang - bangst1 <= 1e-6, angstflux[1:nF])
            nL = findlast(ang -> ang < bangstL, angstflux[1:nF])

            #? Reinterpret loop break
            nL <= n1 && error("Invalid wavelength range: $n1:$n1")

            min_pr = min(n1, min_pr)
            max_pr = max(nL, max_pr)
            
            # compute first cross section
            fangsts[1] = bangst1
            fxsctns[1] = max(pxsctns[1] - (pxsctns[2] - pxsctns[1]) * (pangsts[1] - bangst1) / (pangsts[2] - pangsts[1]), 1.0e-30)
            
            j = 1
            n = n1 + 1
            for i in 1:bangstN
                while true
                    j += 1
                    if bangsts[i] - angstflux[n] < -1.0e-6
                        fangsts[j] = bangsts[i]
                        fxsctns[j] = bxsctns[i]
                        break
                    elseif abs(bangsts[i] - angstflux[n]) <= 1.0e-6
                        fangsts[j] = bangsts[i]
                        fxsctns[j] = bxsctns[i]
                        n += 1
                        break
                    else
                        fangsts[j] = angstflux[n]
                        fxsctns[j] = fxsctns[j-1] + (bxsctns[i] - fxsctns[j-1])*(angstflux[n] - fangsts[j-1])/(bangsts[i] - fangsts[j-1])
                        n += 1
                    end
                end
            end

            # fill remaining slots
            if n <= nL
                for i in n:nL
                    j += 1
                    fangsts[j] = angstflux[i]
                    fxsctns[j] = max(bxsctns[bangstN-1] + (bxsctns[bangstN-1] - bxsctns[bangstN]) * (angstflux[i] - bangsts[bangstN-1]) / (bangsts[bangstN] - bangsts[bangstN-1]), 1e-30)
                end
            end

            # compute last cross section
            fangsts[j+1] = bangstL
            fxsctns[j+1] = max(bxsctns[bangstN-1] + (bxsctns[bangstN-1] - bxsctns[bangstN]) * (bangstL - bangsts[bangstN-1]) / (bangsts[bangstN] - bangsts[bangstN-1]), 1e-30)

            n = n1
            xt = 0.0

            # Compute cross section per wavelength per bin
            for k in 1:j
                xt += 0.5(fxsctns[k+1] + fxsctns[k]) * (fangsts[k+1] - fangsts[k])
                
                if k == j
                    tmp_xsctn = xt / (angstflux[n+1] - angstflux[n])

                    if tmp_xsctn <= 1.0e-30
                        last += 1

                        #? this might be problematic
                        if tmp_xsctn < 0.0
                            tmp_xsctn = 0.0
                        elseif tmp_xsctn < 1.0e-30
                            tmp_xsctn = 1.0e-35
                        end
                    end
                    xsctn_fot[n, s] = tmp_xsctn
                    # rate_tbl[n, s] = tmp_xsctn * fluxes[n]
                else
                    if fangsts[k+1] >= angstflux[n+1]
                        tmp_xsctn = xt / (angstflux[n+1] - angstflux[n])
                        xsctn_fot[n, s] = tmp_xsctn
                        # rate_tbl[n, s] = tmp_xsctn * fluxes[n] # can be moved to the output section as xsctn_tbl[n, s] * fluxes[n]
                        
                        if tmp_xsctn > 1.0e-30
                            last = 0 
                        else 
                            last += 1
                        end

                        tot_rates[s] += tmp_xsctn * fluxes[n] # can be moved to the output section val += xsctn_tbl[n, s] * fluxes[n]; print(val)

                        n += 1
                        xt = 0
                    end
                end
            end

            # maxN is the subscript of last non-zero cross section
            maxN = n - last
            max_bin = max(maxN, max_bin)

            # Why?
            branch.flag && continue

            println(eioniz, "Begin EIoniz")
            @printf(eioniz, " %5i%5i           %8s            %8s\n", branch.num, branch.cat, branch.name1, branch.name2)
            println(eioniz, "0   Wavelength Range X-Section    Flux      Rate     E Excess   Sum")

            if num_sets <= 0 
                num_sets = 1 
            end

            s == 1 && println(eeout, lpad(num_sets, 2), " "^49, lpad(parent.name1, 8))

            tot_rate = 0.0
            tot_energy = 0.0

            for i in 1:maxN
                ang1 = angstflux[i] < 1.0e-06 ? 0.1 : min(angstflux[i], bangstL)
                ang2 = min(angstflux[i + 1], bangstL)
                angL = 2ang1*ang2 / (ang1 + ang2)# 2.0*Wave1*Wave2/(Wave1 + Wave2)

                ele_energy = ANG_EV/angL - ANG_EV/bangstL

                rate = xsctn_fot[i, s] * fluxes[i]

                tot_rate += rate
                tot_energy += ele_energy * rate

                excess_energies[i, s] = ele_energy * rate

                @printf(eioniz, " %10.2f%10.2f%10.3e%10.3e%10.3e%10.2f%10.3e\n", ang1, ang2, xsctn_fot[i, s], fluxes[i], rate, ele_energy, tot_energy)
            end

            if tot_rate < 1.0e-265
                tot_rate = 0.0
                ave_energy = 0.0
            else
                ave_energy = tot_energy / tot_rate
            end

            @printf(eioniz, "0%46s  Total Rate =%10.3e\n", " ", tot_rate)
            @printf(eioniz, "%43s Average Energy =%7.3f\n", " ", ave_energy)

            binned_rates[s] = tot_rate
            binned_excess_energies[s] = ave_energy

            map(en -> binned_rates[s] < 1.0e-265 ? 0.0 : en / tot_rate, excess_energies[1:maxN])
            for i in 1:maxN
                excess_energies[i, s] = max(binned_rates[s] < 1.0e-265 ? 0.0 : excess_energies[i, s] / tot_rate, 0)
            end
        end # end branch loop

        #? MIGHT NOT WORK HERE
        parent = BranchProfile(pangstN, 
                                pangst1, 
                                pangstL, 
                                parent.name1, 
                                parent.name2, 
                                parent.num, 
                                parent.cat, 
                                parent.flag)
        branches[1] = parent
    end
    

    write_brnout(brnout, branches, pangsts, xsctn_tbl)

    fmtd_num_sets = lpad(num_sets, 2) * " "^49 * lpad(parent.name1, 8)
    println(fotout, fmtd_num_sets)
    println(ratout, fmtd_num_sets)

    fmtd_names = join(rpad.(map(br -> br.name2, branches), 8),' ')
    println(fotout, " Lambda         ", fmtd_names)
    println(ratout, " Lambda         ", fmtd_names)


    for i in min_pr:max_pr 
        print(fotout, fmtfloat(angstflux[i], 7, 1), "        ")
        print(ratout, fmtfloat(angstflux[i], 7, 1), "        ")
        for j in 1:num_sets
            @printf(fotout, "%9.2e", xsctn_fot[i, j])
            @printf(ratout, "%9.2e", xsctn_fot[i, j] * fluxes[i])
        end
        println(fotout)
        println(ratout)
    end

    print(fotout, fmtfloat(angstflux[max_pr + 1], 7, 1))
    print(ratout, fmtfloat(angstflux[max_pr + 1], 7, 1))

    print(ratout, "\n Rate Coeffs. = ")
    foreach(r -> @printf(ratout, " %8.2f", r < 1.0e-99 ? 0 : r), tot_rates)

    # lpad -> rpad
    println(eeout, " Lambda         ", join(rpad.(map(br -> br.name2, branches), 8), ' '))
    for i in 1:max_bin
        @printf(eeout, "%7.1f         ", angstflux[i])
        for j in 1:num_sets
            @printf(eeout, " %8.2e", excess_energies[i, j])
        end
        println(eeout)
    end

    @printf(eeout, "%7.1f\n", angstflux[max_bin+1])

    print(eeout, " Rate Coeffs. = ")
    for i in 1:num_sets 
        @printf(eeout, " %8.2e", binned_rates[i])
    end
    println(eeout)

    summary = open("Summary", "w+")


    println(summary, lpad("-->"*parent.name1, 13), join(lpad.(map(br -> br.name2, branches), 8), ' '))

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
    
    # Branch
    close(Hrec)
    close(brnout)
    # Fotrat
    close(ratout)
    close(fotout)
    # Convert
    close(eioniz)
    close(eeout)
    close(summary)
end
#=
function solrad!(angstflux::AbstractVector{T}, fluxes::AbstractVector{T}, SA::T) where {T<:Real}
    local nSA = 162
    local nF = 324

    photoflux = similar(angstflux, 2nF+1)
    fluxratio = similar(angstflux, nSA)
    # photoflux = Vector{T}(undef, 2nF+1)
    # fluxratio = Vector{T}(undef, nSA)
    
    open("PhFlux.dat", "r") do phflux
        data = readdlm(phflux)
        ln::Int64 = 1

        # Populate photoflux
        for i in 1:2:2nF
            photoflux[i] = data[ln, 1]::Float64
            photoflux[i+1] = data[ln, 2]::Float64
    
            ln += 1
        end
        photoflux[2nF+1] = data[ln, 1]::Float64
        ln += 1

        # Populate fluxratio
        j = 1 # index of fluxratio in row
        for i in 1:nSA
            fluxratio[i] = data[ln, j]::Float64
            
            j += 1
            # there are 10 entries per row. go to next line and reset entry index if reached
            if j > 10
                j = 1
                ln += 1
            end
        end
    end

    for i in 1:nF
        j = 2i

        angstflux[i] = photoflux[j-1]
        if i <= nSA
            fluxes[i] = photoflux[j] + SA * (fluxratio[i] - 1) * photoflux[j]
        else
            fluxes[i] = photoflux[j]
        end
    end
    
    angstflux[nF+1] = photoflux[2nF+1]
    
    open("Summary", "w") do summary
        println(summary, "The radiation field is that of the Sun at 1 AU heliocentric distance.")
        @printf(summary, "The solar activity =%5.2f.\n", SA)
        println(summary, "(The quiet Sun has solar activity 0.00, the active Sun has solar activity 1.00)")
    end

    nothing
end
=#

function write_brnout(brnout::IO, bprofs::AbstractVector{BranchProfile}, λ::AbstractVector{T}, xsctn_tbl::AbstractMatrix{T}) where {T<:Real}

    parent = bprofs[1]
    num_sets = length(bprofs)

    println(brnout, "\n0 Branching ratio for ", lpad(parent.name1, 8), lpad(parent.name2, 8), "    ", length(bprofs), " branches")
    print(brnout, num_sets < 10 ? " Lambda  Total" : rpad("  Lambda "*parent.name2, 14))

    for s in 2:num_sets print(brnout, rpad(bprofs[s].name2, 8)) end
    println(brnout)

    for i in 1:parent.angstN
        @printf(brnout, "%7.1f", λ[i])
        for s in 1:num_sets @printf(brnout, " %8.2e", xsctn_tbl[i, s]) end
        println(brnout)
    end

    nothing
end

@time main()

end