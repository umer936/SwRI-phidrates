module Phidrates3

using DelimitedFiles, Printf

include("rads.jl")
include("common.jl")

struct Branch
    angstN::Int
    angst1::Float64
    angstL::Float64
    name1::String
    name2::String
    num::Int
    cat::Int
    flag::Bool
end

function Branch(
    angstN::Int, 
    angst1::Float64, 
    angstL::Float64,
    name1::String, 
    name2::String; 
    num::Int=0, 
    cat::Int=0,
    flag::Bool=true)

    return Branch(angstN, angst1, angstL, name1, name2, num, cat, flag)
end

const global ANG_EV::Float64 = 12398.5
const global MAX_ANGSTS::Int32 = 50000
const global MAX_BRANCHES::Int32 = 2000
const global MAX_FLUX::Int32 = 1000
const global nSA::Int32 = 162

function init()
    # Creates a temporary directory in /var/tmp (/phidrates_images is this directory's alias)
    temp_dir = mktempdir(parent=prefix, prefix="fileXXXXXX")
    chmod(temp_dir, 0755)

    # Copies molecule data and standard data files into the supplied temp directory
    cp("$amop_cgi_bin_dir/photo/hrecs/$molecule.dat", "$temp_dir/Hrec")
    cp("$amop_cgi_bin_dir/photo/NEW_CODE/BBGrid.dat", "$temp_dir/BBGrid.dat")
    cp("$amop_cgi_bin_dir/photo/NEW_CODE/PhFlux.dat", "$temp_dir/PhFlux.dat")

    #! write_input_file is obsolete, since all info can be stored as variables w/o writing a file
end

function write_gnuinfo(use_semi_log, xlabel, ylabel, title, set_ytics, filename)
    println(filename, "set terminal png size 800,600 font \"/usr/share/fonts/dejavu/DejaVuLGCSans.ttf\" 12")
    if !use_semi_log
        println(filename, "set logscale x")
        println(filename, "set logscale y 10")
        println(filename, "set format y '%g'")
    else
        println(filename, "set logscale y")
    end

    println(filename,
"""
# Line style for axes
set style line 80 lt 0

# Line style for grid
set style line 81 lt 3  # dashed
set style line 81 lw 0.5  # grey

# set grid back linestyle 81
# set xtics nomirror
# set ytics nomirror

#set log x
set mxtics 10    # Makes logscale look good.

# Line styles: try to pick pleasing colors, rather
# than strictly primary colors or hard-to-see colors
# like gnuplot's default yellow.  Make the lines thick
# so they're easy to see in small plots in papers.
set style line 1 lt 1
set style line 2 lt 1
set style line 3 lt 1
set style line 4 lt 1
set style line 1 lt 1 lw 6 pt 7
set style line 2 lt 2 lw 6 pt 9
set style line 3 lt 3 lw 6 pt 5
set style line 4 lt 4 lw 6 pt 13
set origin 0, 0.01

set xlabel \"$xlabel\"
set ylabel \"$ylabel\"
set title \"$title\"
""")


    if set_ytics println(filename, "set mytics 5")
    end
end

get_input_name(branch) = split(findfirst(startswith(branch), readlines("/usr/local/var/www/SwRI-phidrates/data_files/LUTOutOnly.txt")), "=")[2]
get_output_name(branch) = split(findfirst(startswith(branch), readlines("/usr/local/var/www/SwRI-phidrates/data_files/LUTOutOnly.txt")), "=")[2]

function main()
    #============#
    # INITIALIZE #
    #============#
    run(`/bin/bash /usr/local/var/www/SwRI-phidrates/data_files/bash_cross_sections_jl.cgi`)
    cd(readchomp("/usr/local/var/www/SwRI-phidrates/data_files/photo/NEW_CODE/store.txt"))
    # println(pwd())
    input = open("Input", "r")
    
    #=====#
    # RAD #
    #=====#
    mode = readline(input)

    nF::Int32 = mode == "Sol " ? 324 : 337
    angstflux = zeros(nF+1)
    fluxes    = zeros(nF+1)

    if mode === "Sol"
        SA = parse(Float64, readline(input))::Float64
        nF  = 324
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

    #======#
    # OPEN #
    #======#
    brnout::IO = open("BrnOut", "w+") # Wavelengths and cross sections for branches. 2
    ratout::IO = open("RatOut", "w+") # Binned rate coefficients per Angstrom. 3
    fotout::IO = open("FotOut", "w+") # Binned Cross Sections. 15
    eioniz::IO = open("EIoniz", "w+") # Binned rates and excess energies. 9
     eeout::IO = open("EEOut", "w+")  # Binned excess energies per Angstrom. 19

    # Configure iterator
    _Hrec::IO = open("Hrec", "r") |> seekstart
    Hrec::IO = replace(read(_Hrec, String), "E 0"=>"E0") |> IOBuffer
    iter = Base.Iterators.Stateful(readlines(Hrec))

    # Read parent branch header
    header = split(popfirst!(iter), " "; keepempty=false)

    pangstN::Int64   = parse(Int, header[1])
    pangst1::Float64 = parse(Float64, header[2])
    pangstL::Float64 = parse(Float64, header[3])
    pname1::String = header[4]
    pname2::String = header[5]

    parent = Branch(pangstN, pangst1, pangstL, pname1, pname2, 0, 0, false)

    # Read references for parent molecule data
    println(brnout, "0          References for Cross Section of ", rpad(pname1, 8), rpad(pname2, 8))
    while !isempty(iter.nextvalstate[1]) println(brnout, popfirst!(iter)) # Copies info until an empty line 
    end 
    popfirst!(iter)
    
    # Read wavelengths and cross sections for parent molecule
    pangsts = zeros(pangstN)
    pxsctns = zeros(pangstN)
    for i in 1:pangstN
        pangsts[i], pxsctns[i] = parse.(Float64, split(popfirst!(iter), " "; keepempty=false))
    end

    # Read number of branching sets (number of total sets - 1)
    num_sets::Int64 = parse(Int, popfirst!(iter)) + 1

    branches::Vector{Branch} = Vector{Branch}(undef, num_sets)

    # Initialize branch data
    bxsctns = zeros(MAX_ANGSTS)
    bangsts = zeros(MAX_ANGSTS)

    # Data interpolated onto angstflux
    fangsts = zeros(MAX_ANGSTS)
    fxsctns = zeros(MAX_ANGSTS)
    
    # Output data
    tot_rates = zeros(pangstN) # Branch
    xsctn_tbl = zeros(pangstN, num_sets) # Branch
    fot_xsctn = zeros(MAX_ANGSTS, num_sets) # Fotrat
    fot_rate = zeros(MAX_ANGSTS, num_sets) # Fotrat
    
    binned_rates = zeros(num_sets) # Convert
    binned_excess_energies = zeros(num_sets) # Convert
    excess_energies = zeros(nF, num_sets) # Convert

    # Placeholder variables
    bangstN::Int64 = 0
    bangst1::Float64 = 0.0
    bangstL::Float64 = 0.0

    max_bin = 0 

    if num_sets > 1
        for set in 1:num_sets-1
            header = split(popfirst!(iter), " "; keepempty=false)

            bangstN = parse(Int, header[1])
            bangst1 = parse(Float64, header[2])
            bangstL = parse(Float64, header[3])

            bname1 = header[4]
            bname2 = header[5]

            # bnum = parse(Int, header[6])
            # bcat = parse(Int, header[7])

            # branches[s] = Branch(bangstN, bangst1, bangstL, bname1, bname2, 0, 0, false)
            branches[set] = Branch(pangstN, bangst1, bangstL, bname1, bname2, 0, 0, false)
            
            # Write references for branching set to file
            println(brnout, "0          References for Cross Section of ", lpad(bname1, 8), lpad(bname2, 8))
            while !isnothing(iter.nextvalstate) && !isempty(iter.nextvalstate[1]) println(brnout, popfirst!(iter))
            end 
            popfirst!(iter)
            
            # Redefine parent with new angst1 and angstL
            pangst1 = max(pangst1, bangst1)
            pangstL = min(pangstL, bangstL)

            # Read branch data
            for i in 1:bangstN
                bangsts[i], bxsctns[i] = parse.(Float64, split(popfirst!(iter), " "; keepempty=false))
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
                        xsctn_tbl[i, set] = prob * pxsctns[i]
                        break
                    end

                    limit = j + 1 >= bangstN && pangsts[i] > bangsts[bangstN]
                end
            end
        end
        
        # Calculate final cross section bin
        for i in 1:pangstN
            temp = 1.0 - tot_rates[i]
            if temp < -1.0e-6
                println(stderr, pname1, ", temp < -1.0e-6: ", temp, " around wavelength: ", pangsts[i])
            elseif temp < 0.0
                temp = 0.0
            end
            xsctn_tbl[i, num_sets] = temp * pxsctns[i]
        end

        # Read final branch header
        header = split(popfirst!(iter), " "; keepempty=false)

        bangstN = pangstN
        bangst1 = pangst1
        bangstL = pangstL

        bname1 = pname1
        bname2 = header[5]

        branches[num_sets] = Branch(bangstN, bangst1, bangstL, bname1, bname2, 0, 0, false)
    else
        branches[num_sets] = Branch(pangstN, pangst1, pangstL, pname1, pname2, 0, 0, false)
        xsctn_tbl[:, num_sets] = pxsctns
    end

    parent = Branch(
        pangstN, 
        pangst1, 
        pangstL, 
        pname1, 
        pname2, 
        parent.num, 
        parent.cat, 
        parent.flag
    )

    #========#
    # FOTRAT #
    #========#
    min_pr = typemax(Int)
    max_pr = 0

    for s in 1:num_sets
        branch = branches[s]
        bangstN = pangstN
        bangst1 = branch.angst1
        bangstL = branch.angstL

        bxsctns = view(xsctn_tbl, :, s)
        if bangst1 - bangstL >= -1.0e-6 || bangst1 < angstflux[1] || bangstL > angstflux[nF] 
            error("Unusable wavelength range. Check the data for this $bname1")
        end

        n1 = findlast(ang -> ang - bangst1 <= 1.0e-6, view(angstflux, 1:nF))
        nL = findlast(ang -> ang < bangstL, view(angstflux, 1:nF))

        nL <= n1 && error("Invalid wavelength range: $n1:$nL")

        min_pr = min(n1, min_pr)
        max_pr = max(nL, max_pr)

        # compute first cross section
        fangsts[1] = bangst1
        fxsctns[1] = max(bxsctns[1] - (bxsctns[2] - bxsctns[1]) * (pangsts[1] - bangst1) / (pangsts[2] - pangsts[1]), 1.0e-30)

        j = 1
        n = n1 + 1
        for i in 1:bangstN
            while true
                j += 1
                if pangsts[i] - angstflux[n] < -1.0e-6
                    fangsts[j] = pangsts[i]
                    fxsctns[j] = bxsctns[i]
                    break
                elseif abs(pangsts[i] - angstflux[n]) <= 1.0e-6
                    fangsts[j] = pangsts[i]
                    fxsctns[j] = bxsctns[i]
                    n += 1
                    break
                else
                    fangsts[j] = angstflux[n]
                    fxsctns[j] = fxsctns[j-1] + (bxsctns[i] - fxsctns[j-1])*(angstflux[n] - fangsts[j-1])/(pangsts[i] - fangsts[j-1])
                    n += 1
                end
            end
        end

        # fill remaining slots
        if n <= nL
            for i in n:nL
                j += 1
                fangsts[j] = angstflux[i]
                fxsctns[j] = max(bxsctns[bangstN-1] + (bxsctns[bangstN-1] - bxsctns[bangstN]) * (angstflux[i] - pangsts[bangstN-1]) / (pangsts[bangstN] - pangsts[bangstN-1]), 1e-30)
            end
        end

        # compute last cross section
        fangsts[j+1] = bangstL
        fxsctns[j+1] = max(bxsctns[bangstN-1] + (bxsctns[bangstN-1] - bxsctns[bangstN]) * (bangstL - pangsts[bangstN-1]) / (pangsts[bangstN] - pangsts[bangstN-1]), 1e-30)

        n = n1
        xt = 0.0

        last = 0
        # Compute cross section per wavelength per bin
        for k in 1:j
            xt += 0.5(fxsctns[k+1] + fxsctns[k]) * (fangsts[k+1] - fangsts[k])
            
            if k == j
                tmp_xsctn = xt / (angstflux[n+1] - angstflux[n])
                
                if tmp_xsctn <= 1.0e-30
                    last += 1
                    if tmp_xsctn < 0.0
                        tmp_xsctn = 0.0
                    elseif tmp_xsctn < 1.0e-30
                        tmp_xsctn = 1.0e-35
                    end
                end
                fot_xsctn[n, s] = tmp_xsctn
                fot_rate[n, s] = tmp_xsctn * fluxes[n]
            elseif fangsts[k+1] >= angstflux[n+1]
                tmp_xsctn = xt / (angstflux[n+1] - angstflux[n])
                fot_xsctn[n, s] = tmp_xsctn
                fot_rate[n, s] = tmp_xsctn * fluxes[n]

                if tmp_xsctn > 1.0e-30
                    last = 0 
                else 
                    last += 1
                end

                tot_rates[s] += tmp_xsctn * fluxes[n]

                n += 1
                xt = 0
            end
        end

        maxN = n - last
        
        bname1 = branch.name1
        bname2 = branch.name2

        max_bin = max(maxN, max_bin)

        # Why?
        branch.flag && continue

        println(eioniz, "Begin EIoniz")
        @printf(eioniz, " %5i%5i           %8s            %8s\n", branch.num, branch.cat, bname1, bname2)
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
            angL = 2.0 * ang1 * ang2 / (ang1 + ang2)

            ele_energy = ANG_EV / angL - ANG_EV / bangstL

            rate = fot_xsctn[i, s] * fluxes[i]

            tot_rate += rate
            tot_energy += ele_energy * rate

            excess_energies[i, s] = ele_energy * rate

            @printf(eioniz, " %10.2f%10.2f%10.3e%10.3e%10.3e%10.2f%10.3e\n", ang1, ang2, fot_xsctn[i, s], fluxes[i], rate, ele_energy, tot_energy)
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

        map(en -> max(binned_rates[s] < 1.0e-265 ? 0.0 : en / tot_rate, 0), view(excess_energies, 1:maxN, s))
    end

    #===================#
    # WRITE OUTPUT DATA #
    #===================#
    println(brnout, "\n0 Branching ratio for ", lpad(pname1, 8), lpad(pname2, 8), "    ", num_sets, " branches")
    if num_sets > 1
        print(brnout, " Lambda  Total")
        println(brnout, lpad.(getproperty.(branches, :name2), 8)...)
        for i in 1:pangstN
            @printf(brnout, "%7.1f %8.2e", pangsts[i], sum(view(xsctn_tbl, i, :)))
            for s in 1:num_sets @printf(brnout, " %8.2e", xsctn_tbl[i, s]) end
            println(brnout)
        end
    else
        println(brnout, rpad("  Lambda "*pname2, 14))
        for i in 1:pangstN @printf(brnout, "%8.2f %9.2e\n", pangsts[i], pxsctns[i])
        end
    end

    fmtd_num_sets = lpad(num_sets, 2) * " "^49 * lpad(pname1, 8)
    println(fotout, fmtd_num_sets)
    println(ratout, fmtd_num_sets)

    fmtd_names = join(rpad.(getproperty.(branches, :name2), 8),' ')
    println(fotout, " Lambda         ", fmtd_names)
    println(ratout, " Lambda         ", fmtd_names)

    for i in min_pr:max_pr 
        print(fotout, fmtfloat(angstflux[i], 7, 1), "        ")
        print(ratout, fmtfloat(angstflux[i], 7, 1), "        ")
        for s in 1:num_sets
            @printf(fotout, "%9.2e", fot_xsctn[i, s])
            @printf(ratout, "%9.2e", fot_rate[i, s])
        end
        println(fotout)
        println(ratout)
    end

    print(fotout, fmtfloat(angstflux[max_pr + 1], 7, 1))
    print(ratout, fmtfloat(angstflux[max_pr + 1], 7, 1))

    print(ratout, "\n Rate Coeffs. = ")
    foreach(r -> @printf(ratout, " %8.2f", r < 1.0e-99 ? 0 : r), tot_rates)

    println(eeout, " Lambda         ", join(rpad.(getproperty.(branches, :name2), 8), ' '))
    for i in 1:max_bin
        @printf(eeout, "%7.1f         ", angstflux[i])
        for j in 1:num_sets
            @printf(eeout, " %8.2e", excess_energies[i, j])
        end
        println(eeout)
    end

    @printf(eeout, "%7.1f\n", angstflux[max_bin+1])

    print(eeout, " Rate Coeffs. = ")
    for i in 1:num_sets @printf(eeout, " %8.2e", binned_rates[i])
    end
    println(eeout)

    summary = open("Summary", "w+")


    println(summary, lpad("-->"*pname1, 13), join(lpad.(getproperty.(branches, :name2), 8), ' '))

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
    
    #=============#
    # CLOSE FILES #
    #=============#
    # Initialize
    close(input)

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

function write_brnout(brnout::IO, parent::Branch, branches::AbstractVector{Branch}, angsts::AbstractVector{T}, xsctn_tbl::AbstractMatrix{T}) where{T<:Real}
    num_sets = length(branches)

    println(brnout, "\n0 Branching ratio for ", lpad(parent.name1, 8), lpad(parent.name2, 8), "    ", length(branches), " branches")
    print(brnout, num_sets < 10 ? " Lambda  Total" : rpad("  Lambda "*parent.name2, 14))

    println(brnout, lpad.(getproperty.(branches, :name2), 8)...)

    for i in 1:parent.angstN
        @printf(brnout, "%7.1f %8.2e", angsts[i], sum(view(xsctn_tbl, i, :)))
        for s in 1:num_sets @printf(brnout, " %8.2e", xsctn_tbl[i, s]) end
        println(brnout)
    end

    nothing
end

end