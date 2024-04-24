module Phidrates4RF

using DelimitedFiles, Printf


include("solrad2.jl")
include("bbrad.jl")
include("israd.jl")
include("common.jl")

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

    MAX_ANGSTS::Int64 = 50000
    MAX_BRANCHES::Int64 = 2000
    MAX_FLUX::Int64 = 1000

    GR_PT_LIM::Int64 = 400

    run(`/bin/bash /usr/local/var/www/SwRI-phidrates/data_files/bash_cross_sections_jl.cgi`)
    cd(readchomp("/usr/local/var/www/SwRI-phidrates/data_files/photo/NEW_CODE/store.txt"))
    println(pwd())
    input = open("Input", "r")
    #=====#
    # RAD #
    #=====#
    mode = readline(input)

    nF::Int64 = mode == "Sol " ? 324 : 337
    nSA::Int64 = 162

    # Data file output of solrad, bbrad, or israd
    λᵩ = Vector{Float64}(undef, nF+1)
    ϕ = Vector{Float64}(undef, nF+1)

    if mode === "Sol"
        SA = parse(Float64, readline(input))
        nF = 324
        nSA = 162

        solrad!(λᵩ, ϕ, SA)
    elseif mode === "BB "
        println(stderr, "dumSA = ", readline(input))
        T = parse(Float64, readline(input))
        bbrad(T)
    elseif mode === "IS "
        israd()
    else error("Unrecognized radiation field. Supply a valid radiation field (\"Sol,\" \"BB ,\" \"IS ,\")")
    end


    #========#
    # BRANCH #
    #========#
    brnout = open("BrnOut", "w+")

    # Read Parent Molecule Information:
    Hrec = open("Hrec", "r") |> seekstart
    _Hrec = replace(read(Hrec, String), "E 0"=>"E0")
    data::Array{Union{SubString{String}, Int64, Float64}} = readdlm(IOBuffer(_Hrec))
    ln::Int64 = 1

    parent = BranchProfile(data[ln, 1:5]..., 0, 0, true)
    
    λₚₙ::Int64 = parent.angstN
    λₚ₁::Float64 = parent.angst1
    λₚₗ::Float64 = parent.angstL
    ln += 1

    # Read References for Parent Molecule:
    println(brnout, "0          References for Cross Section of ", rpad(parent.name1, 8), rpad(parent.name2, 8))
    while data[ln, 1] isa AbstractString
        println(brnout, join(data[ln, :], ' '))
        ln += 1
    end

    # Read Wavelengths and Cross Sections for Parent Molecule
    λₚ = Vector{Float64}(undef, λₚₙ)
    σₚ = Vector{Float64}(undef, λₚₙ)
    for i in 1:λₚₙ
        λₚ[i] = data[ln, 1]
        σₚ[i] = data[ln, 2]
        ln += 1
    end

    λₓ = Vector{Float64}(undef, nF)
    σₓ = Vector{Float64}(undef, nF)

    min_pr::Int64 = typemax(Int64)
    max_pr::Int64 = 0

    # Read Number of Branching Sets (number of total sets - 1)
    num_sets::Int64 = data[ln, 1] + 1

    #? Might be faster to define up here
    λᵦ = Vector{Float64}(undef, MAX_ANGSTS)
    σᵦ = Vector{Float64}(undef, MAX_ANGSTS)

    # Create data structures
    branches::Vector{BranchProfile} = Vector{BranchProfile}(undef, num_sets) # Branch

    σₜ = Matrix{Float64}(undef, λₚₙ, num_sets) # Branch
    σᵨ = Matrix{Float64}(undef, nF, num_sets) # Fotrat

    ks = Vector{Float64}(undef, λₚₙ) # Branch
    kᵦ = zeros(Float64, num_sets) # Convert

    E = Matrix{Float64}(undef, MAX_ANGSTS, num_sets) # Convert
    Eᵦ = zeros(Float64, num_sets) # Convert

    λᵦₙ::Int64 = 0
    λᵦ₁::Float64 = 0.0
    λᵦₗ::Float64 = 0.0
    # Populate parent profiles
    if !iszero(num_sets)
        ln += 1
        for s in 1:num_sets
            if s == num_sets
                for i in 1:λₚₙ # iterate through parent wavelengths
                    temp = 1.0 - ks[i]
                    if temp < -1.0e-6
                        println(stderr, parent.name1, ", temp < -1.0e-6: ", temp, " around wavelength: ", λₚ[i])
                    elseif temp < 0.0
                        temp = 0.0
                    end
                    σₜ[i, num_sets] = temp * σₚ[i]
                end

                branch = BranchProfile(λₚₙ, λₚ₁, λₚₗ, parent.name1, data[ln, 5:7]..., true)
                
                λᵦₙ = λₚₙ
                λᵦ₁ = λₚ₁
                λᵦₗ = λₚₗ
            else
                branch = BranchProfile(data[ln, 1:7]..., true)
                λᵦₙ = branch.angstN
                λᵦ₁ = branch.angst1
                λᵦₗ = branch.angstL

                ln += 1

                # Write references for branching set to file
                println(brnout, "0          References for Cross Section of ", lpad(branch.name1, 8), lpad(branch.name2, 8))
                while data[ln, 1] isa AbstractString
                    println(brnout, join(data[ln, :], ' '))
                    ln += 1
                end
                
                # Redefine parent with new angst1 and angstL
                λₚ₁ = max(λₚ₁, λᵦ₁)
                λₚₗ = min(λₚₗ, λᵦₗ)

                # Read branch data
                for i in 1:λᵦₙ
                    λᵦ[i] = data[ln, 1]
                    σᵦ[i] = data[ln, 2]
                    ln += 1
                end
                
                limit = false
                for i in 1:λₚₙ # iterate thru wavelengths
                    for j in 1:λᵦₙ-1 # iterate thru branch data
                        prob = 0
                        if λₚ[i] > λᵦ[j+1] && !limit
                        else
                            if λₚ[i] == λᵦ[j+1] # dont interpolate, the values are
                                prob = σᵦ[j+1]
                            else
                                prob = σᵦ[j] + (σᵦ[j+1] - σᵦ[j]) * (λₚ[i] - λᵦ[j]) / (λᵦ[j+1] - λᵦ[j])
                            end

                            if limit 
                                prob = 0 
                            end
                            
                            ks[i] += prob
                            σₜ[i, s] = prob * σₚ[i]
                            break
                        end

                        limit = j + 1 >= λᵦₙ && λₚ[i] > λᵦ[λᵦₙ] #! chopping block
                    end
                end
            end
            branches[s] = branch
            
            λᵦ = λₚ
            σᵦ = view(σₜ, :, s)
            λᵦ₁ - λᵦₗ >= -1.0e-6 || λᵦ₁ < λᵩ[1] || λᵦₗ > λᵩ[nF] && error("Unusable wavelength range. Check the data for this $bname1")

            n1 = 0
            nL = 0
            for i in 1:nF
                if λᵩ[i] - λᵦ₁ <= 1e-6
                    n1 = i
                end
                if λᵩ[i] < λᵦₗ
                    nL = i
                end
            end

            #? Reinterpret loop break
            nL <= n1 && error("Invalid range: $nL:$n1")

            min_pr = min(n1, min_pr)
            max_pr = max(nL, max_pr)
            
            # compute first cross section
            λₓ[1] = λᵦ₁
            σₓ[1] = max(σₚ[1] - (σₚ[2] - σₚ[1]) * (λₚ[1] - λᵦ₁) / (λₚ[2] - λₚ[1]), 1.0e-30)
            
            j = 1
            n = n1 + 1
            for i in 1:λₚₙ
                while true
                    j += 1
                    if λᵦ[i] - λᵩ[n] < -1.0e-6
                        λₓ[j] = λᵦ[i]
                        σₓ[j] = σᵦ[i]
                        break
                    elseif abs(λᵦ[i] - λᵩ[n]) <= 1.0e-6
                        λₓ[j] = λᵦ[i]
                        σₓ[j] = σᵦ[i]
                        n += 1
                        break
                    else
                        λₓ[j] = λᵩ[n]
                        σₓ[j] = σₓ[j-1] + (σᵦ[i] - σₓ[j-1])*(λᵩ[n] - λₓ[j-1])/(λᵦ[i] - λₓ[j-1])
                        n += 1
                    end
                end
            end

            # fill remaining slots
            if n <= nL
                for i in n:nL
                    j += 1
                    λₓ[j] = λᵩ[i]
                    σₓ[j] = max(σᵦ[λᵦₙ-1] + (σᵦ[λᵦₙ-1] - σᵦ[λᵦₙ]) * (λᵩ[i] - λᵦ[λᵦₙ-1]) / (λᵦ[λᵦₙ] - λᵦ[λᵦₙ-1]), 1e-30)
                end
            end

            # compute last cross section
            λₓ[j+1] = λᵦₗ
            σₓ[j+1] = max(σᵦ[λᵦₙ-1] + (σᵦ[λᵦₙ-1] - σᵦ[λᵦₙ]) * (λᵦₗ - λᵦ[λᵦₙ-1]) / (λᵦ[λᵦₙ] - λᵦ[λᵦₙ-1]), 1e-30)

            n = n1
            xt = 0.0

            # Compute cross section per wavelength per bin
            for k in 1:j
                xt += 0.5(σₓ[k+1] + σₓ[k]) * (λₓ[k+1] - λₓ[k])
                
                if k == j
                    _σ = xt / (λᵩ[n+1] - λᵩ[n])
                    if _σ <= 1.0e-30
                        if _σ < 0.0
                            _σ = 0.0
                        elseif _σ < 1.0e-30
                            _σ = 1.0e-35
                        end
                    end
                    # σₜ₂
                    σᵨ[n, s] = _σ
                    # rate_tbl[n, s] = tmp_xsctn * fluxes[n]
                else
                    if λₓ[k+1] >= λᵩ[n+1]
                        _σ = xt / (λᵩ[n+1] - λᵩ[n])
                        
                        σᵨ[n, s] = _σ
                        # rate_tbl[n, s] = tmp_xsctn * fluxes[n] # can be moved to the output section as xsctn_tbl[n, s] * fluxes[n]

                        ks[s] += _σ * ϕ[n] # can be moved to the output section val += xsctn_tbl[n, s] * fluxes[n]; print(val)

                        n += 1
                        xt = 0
                    end
                end
            end
        end # end branch loop

        #? MIGHT NOT WORK HERE
        parent = BranchProfile(λₚₙ, 
                                λₚ₁, 
                                λₚₗ, 
                                parent.name1, 
                                parent.name2, 
                                parent.num, 
                                parent.cat, 
                                parent.flag)
        branches[1] = parent
    end

    close(Hrec)

    write_brnout(brnout, branches, λₚ, σₜ)
    close(brnout)

    ratout  = open("RatOut", "w+") # Binned rate coefficients per Angstrom.
    fotout  = open("FotOut", "w+") # Binned Cross Sections.

    fmtd_num_sets = lpad(num_sets, 2) * " "^49 * lpad(branches[1].name1, 8)
    println(fotout, fmtd_num_sets)
    println(ratout, fmtd_num_sets)

    fmtd_names = join(rpad.(map(br -> br.name2, branches[2:end]), 8),' ')
    println(fotout, " Lambda         ", fmtd_names)
    println(ratout, " Lambda         ", fmtd_names)

    for i in min_pr:max_pr 
        print(fotout, fmtfloat(λᵩ[i], 7, 1), "        ")
        print(ratout, fmtfloat(λᵩ[i], 7, 1), "        ")
        for j in 1:num_sets
            @printf(fotout, "%9.2e", σᵨ[i, j])
            @printf(ratout, "%9.2e", σᵨ[i, j] * ϕ[i])
        end
        println(fotout)
        println(ratout)
    end

    print(fotout, fmtfloat(λᵩ[max_pr + 1], 7, 1))
    print(ratout, fmtfloat(λᵩ[max_pr + 1], 7, 1))

    print(ratout, "\n Rate Coeffs. = ")
    foreach(r -> @printf(ratout, " %8.2f", r < 1.0e-99 ? 0 : r), ks)

    close(ratout)
    close(fotout)


    #=========#
    # CONVERT #
    #=========#
    #=
    xsects = Vector{Float64}(undef, 9999)
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
            ang1 = angstflux[i]
            ang2 = angstflux[i + 1]

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
        @printf(eeout, "%7.1f         ", angstflux[i])
        for j in 1:num_sets
            @printf(eeout, " %8.2e", excess_energies[i, j])
        end
        println(eeout)
    end

    @printf(eeout, "%7.1f\n", angstflux[maxbin+1])

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
    =#
end

function solrad!(angstflux, fluxes, SA::AbstractFloat)
    nSA = 162
    nF = 324

    photoflux = Vector{Float64}(undef, 2nF+1)
    fluxratio = Vector{Float64}(undef, nSA)
    
    open("PhFlux.dat", "r") do phflux
        data::Array{Union{SubString{String}, Int64, Float64}} = readdlm(phflux)
        ln = 1

        # Populate photoflux
        for i in 1:2:2nF
            photoflux[i] = data[ln, 1]
            photoflux[i+1] = data[ln, 2]
    
            ln += 1
        end
        photoflux[2nF+1] = data[ln, 1]
        ln += 1

        # Populate fluxratio
        j = 1 # index of fluxratio in row
        for i in 1:nSA
            fluxratio[i] = data[ln, j]
            
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
end

function write_brnout(brnout::IO, bprofs::AbstractVector{BranchProfile}, λ::Vector{Float64}, xsctn_tbl::Matrix{Float64})

    parent = bprofs[1]
    num_sets = length(bprofs)

    println(brnout, "\n0 Branching ratio for ", lpad(parent.name1, 8), lpad(parent.name2, 8), "    ", length(bprofs), " branches")
    print(brnout, num_sets < 10 ? " Lambda  Total" : rpad("  Lambda "*parent.name2, 14))

    for s in 2:num_sets 
        print(brnout, rpad(bprofs[s].name2, 8)) end
    println(brnout)

    for i in 1:parent.angstN
        @printf(brnout, "%7.1f", λ[i])
        for s in 1:num_sets @printf(brnout, " %8.2e", xsctn_tbl[i, s]) end
        println(brnout)
    end
end

@time main()

end