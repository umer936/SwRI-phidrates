using DelimitedFiles, Printf

struct Branch{S<:AbstractString, T<:Integer, U<:AbstractFloat}
    name1::S
    name2::S

    angstN::T
    angst1::U
    angstL::U

    λ::Vector{U}
    xsctns::Vector{U}

    num::Integer
    cat::Integer
    flag::Bool
end

function Branch(name1::S, 
    name2::S, 
    angstN::T, 
    angst1::U, 
    angstL::U; 
    num::T=0, 
    cat::T=0,
    flag::Bool=true) where {S<:AbstractString, T<:Integer, U<:AbstractFloat}

    return Branch{S, T, U}(name1, name2, angstN, angst1, angstL, Vector{U}(undef, angstN), Vector{U}(undef, angstN), num, cat, flag)
end

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

function branch()
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
    bprofs::Vector{BranchProfile} = Vector{BranchProfile}(undef, num_sets+1)

    # Populate parent profiles
    # bprofs[num_sets+1] = BranchProfile(0, NaN, NaN, parent.name1, parent.name2, 0, 0, true)

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
            bprofs[s] = branch
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

        bprofs[num_sets+1] = BranchProfile(parent.angstN, parent.angst1, parent.angstL, parent.name1, data[ln, 5:7]..., true)
    end

    close(Hrec)

    write_brnout(brnout, bprofs, angsts, xsctn_tbl)
    close(brnout)

    return (angsts, xsctn_tbl, bprofs)
end

function calculations!(rates::AbstractVector{T}, λ::AbstractVector{T}, σ::AbstractVector{T}, 
    λ₁::AbstractVector{T}, σ₁::AbstractVector{T}) where {T<:AbstractFloat}

    limit = false
    j = 1
    for i in eachindex(λ) # iterate thru wavelengths
        while true # iterate thru branch data
            prob = 0
            if λ[i] > λ₁[j + 1] && !limit
            else
                if λ[i] == λ₁[j + 1] # dont interpolate, the values are
                    prob = σ₁[j + 1]
                else
                    prob = σ₁[j] + (σ₁[j + 1] - σ₁[j]) * (λ[i] - λ₁[j]) / (λ₁[j+1] - λ₁[j])
                end

                if limit 
                    prob = 0 
                end

                rates[i] += prob
                σ₁[i] = prob * σ[i]
                break
            end
            j += 1
            
            limit = j + 1 >= length(λ₁) && λ[i] > λ₁[length(λ₁)]
        end
    end
end

function write_brnout(brnout::IO, bprofs::AbstractVector{BranchProfile}, λ::Vector{Float64}, xsctn_tbl::Matrix{Float64})

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
end