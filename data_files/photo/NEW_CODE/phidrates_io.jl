using Printf

## BrnOut
print_ref_header(io::IO, name1, name2) = println(io, "0          References for Cross Section of ", rpad(name1, 8), rpad(name2, 8))

## EIoniz
function print_eioniz_subtitle(io::IO, branch)
    println(io, "Begin EIoniz")
    @printf(io, " %5i%5i           %8s            %8s\n", branch.num, branch.cat, branch.name1, branch.name2)
    println(io, "0   Wavelength Range X-Section    Flux      Rate     E Excess   Sum")
end

## EEOut, Summary, RatOut
function print_rates(io::IO, rates; stop=typemax(Int))
    print(io, " Rate Coeffs. = ")
    for i in 1:min(length(rates), stop) @printf(io, " %8.2e", rates[i])
    end
    println(io)
end

## EEOut, Summary
function print_energies(io::IO, energies; stop=typemax(Int))
    print(io, " Av. Excess E = ")
    for i in 1:min(length(energies), stop) 
        @printf(io, " %8.2e", energies[i])
    end
    println(io)
end

function print_title(io::IO, name, num_sets)
    println(io, lpad(num_sets, 2), " "^49, lpad(name, 8))
end

function print_names(io::IO, branches; right=false)
    fmtd_names = if right
        join(rpad.(map(br -> br.name2, branches), 8),' ')
    else
        join(lpad.(map(br -> br.name2, branches), 8), ' ')
    end
    println(io, " Lambda         ", fmtd_names)
end


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

function print_references(io::IO, iter, name1, name2)
    println(brnout, "0          References for Cross Section of ", lpad(name1, 8), lpad(name2, 8))
    while !isempty(iter.nextvalstate[1])
        println(io, popfirst!(iter))
    end 
    popfirst!(iter)
end

function parse_header(header::AbstractString)
    types = (Int, Float64, Float64, String, String, Int, Int)
    data = split(header, " "; keepempty=false)

    return BranchProfile(parse.(types, data)..., false)
end

function parse_header(header::SubArray; default::Union{BranchProfile, Nothing}=nothing)
    types = (Int, Float64, Float64, String, String, Int, Int)

    idxs = only(header.indices)

    defs = if !isnothing(field)
        ntuple(field -> getfield(default, fieldnames(BranchProfile)[i]), 8)
    else 
        (0, NaN, NaN, "", "", 0, 0, 0, false)
    end


    for i in 1:8
        if any(∋(i), idxs)
            parse(types[i], header[i])
        else

        end
    end
end
