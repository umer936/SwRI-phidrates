function print_rates(io::IO, rates::AbstractVector{Real})
    print(io, " Rate Coeffs. = ")
    foreach(r -> @printf(io, " %8.2e", r), rates[i])
    println(io)
end

function print_energies(io::IO, energies::AbstractVector{Real})
    print(io, " Av. Excess E = ")
    foreach(en -> @printf(io, " %8.2e", en), energies[i])
    println(io)
end