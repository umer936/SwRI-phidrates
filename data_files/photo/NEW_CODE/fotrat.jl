using Printf, DelimitedFiles
# include("vars.jl")

#=
path = "/usr/local/var/www/SwRI-phidrates/tmp/file785JPu"
new = "/usr/local/var/www/SwRI-phidrates/tmp/new"
_new = "new/*"

# Clean up some files
run(`rm -rf $new/fort.16`)
run(`rm -rf $new/RatOut`)
run(`rm -rf $new/FotOut`)

ratout  = open("$new/RatOut", "w+") # Binned rate coefficients per Angstrom.
fotout  = open("$new/FotOut", "w+") # Binned Cross Sections.

summary = open("$new/Summary", "w+") # Summary of rate coefficients and average excess energies.
=#


function fotrat()
    ratout  = open("RatOut", "w+") # Binned rate coefficients per Angstrom.
    fotout  = open("FotOut", "w+") # Binned Cross Sections.
    
    fort4 = open("fort.4", "a+") |> seekstart
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

    # flux_ratio = zeros(Float64, nSA)
    # flux_ratio_plot = zeros(Float64, 2nSA)

    rate_tbl = Matrix{Float64}(undef, MAX_ANGSTS, 16)
    
    rates = zeros(Float64, 16)
    branch_names = fill("", 16)

    min_pr = typemax(Int)
    max_pr = 0

    num_sets = data[ln, 1]
    println(stderr, num_sets, " sets")

    angst_plot = Vector{Float64}(undef, MAX_BRANCHES + 1)
    xsctn_plot = Vector{Float64}(undef, MAX_BRANCHES + 1)
    rate_plot = Vector{Float64}(undef, MAX_BRANCHES + 1)

    name1 = ""
    name2 = ""

    
    for s in 1:num_sets
        ln += 1
        # Note: in contrast to the variables in branch.jl, these represent the current branch's information
        angstN::Int16 = data[ln, 1]
        angst1::Float64 = data[ln, 2]
        angstL::Float64 = data[ln, 3]
        name1 = data[ln, 4]
        name2 = data[ln, 5]

        branch_names[s] = name2

        for i in 1:angstN
            ln += 1
            angsts[i] = data[ln, 1]::Float64
            xsctns[i] = data[ln, 2]::Float64
            xsctn_plot[i] = xsctns[i] <= 1.0e-30 ? -30 : log10(xsctns[i])
        end

        if angst1 - angstL >= -1.0e-6 || angst1 < angst_flux[1] || angstL > angst_flux[nF]
            break
        end

        rates[s] = 0

        # get ranges of flux angstroms w.r.t min/max angstrom 
        n1 = 0
        nL = 0
        for i in 1:nF
            if angst_flux[i] - angst1 <= 1e-6
                n1 = i
            end
            if angst_flux[i] < angstL
                nL = i
            end
        end
        
        min_pr = min(n1, min_pr)
        max_pr = max(nL, max_pr)
        
        nL <= n1 && break
        
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
        xsctns[j+1] = max(xsctns[angstN-1] + (xsctns[angstN-1] - xsctns[angstN]) * (angstL - angsts[angstN-1]) / (angsts[angstN] - angsts[angstN - 1]), 1E-30)

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
        maxN = n - last
        i = 1
        #=
        for n in n1:nL
            angst_plot[i] = angst_flux[n]
            angst_plot[i + 1] = angst_flux[n + 1]

            if xsctn_tbl[n, s] > 1.0E-30 && xsctn_tbl[n, s] * fluxes[n] > 1.0E-30
                xsctn_plot[i] = log10(xsctn_tbl[n, s])
                rate_plot[i] = log10(xsctn_tbl[n, s] * fluxes[n] / (angst_plot[i+1] - angst_plot[i]))
            else
                xsctn_plot[i] = -30.0
                rate_plot[i] = -30.0
            end

            xsctn_plot[i + 1] = xsctn_plot[i]
            rate_plot[i + 1] = rate_plot[i]

            i += 2
        end
        =#
        #=
        num_plots = i - 1

        idyaxs = 1
        plotxsect(angstN, angst_plot, xsctn_plot)
        plotxsect(num_plots, angst_plot, xsctn_plot)

        idyaxs = 0
        plotxsect(num_plots, angst_plot, rate_plot)
        =#
        #? use LinearIndexing
        println(fort16, lpad(maxN, 6))
        for i in 1:5:maxN
            ij = i + 4
            @printf(fort16, "%6.0f.   ", angst_flux[i])
            for j in i:ij
                @printf(fort16, "%10.3e", xsctn_tbl[j, s])
            end
            println(fort16, lpad(name1, 8), "  ", lpad(name2, 8))
        end
    end

    fmtd_num_sets = lpad(num_sets, 2) * " "^49 * lpad(name1, 8)
    println(fotout, fmtd_num_sets)
    println(ratout, fmtd_num_sets)

    fmtd_names = join(rpad.(branch_names[1:16], 8),' ')
    println(fotout, " Lambda         ", fmtd_names)
    println(ratout, " Lambda         ", fmtd_names)
    
    for i in min_pr:max_pr 
        print(fotout, fmtfloat(angst_flux[i], 7, 1), "        ")
        print(ratout, fmtfloat(angst_flux[i], 7, 1), "        ")
        # @printf(fotout, "%7.1f        ", angst_flux[i])
        # @printf(ratout, "%7.1f        ", angst_flux[i])
        for j in 1:num_sets
            @printf(fotout, "%9.2e", xsctn_tbl[i, j])
            @printf(ratout, "%9.2e", rate_tbl[i, j])
        end
        println(fotout)
        println(ratout)
    end

    print(fotout, fmtfloat(angst_flux[max_pr + 1], 7, 1))
    print(ratout, fmtfloat(angst_flux[max_pr + 1], 7, 1))
    # @printf(fotout, "%7.1f", angst_flux[max_pr+1])
    # @printf(ratout, "%7.1f", angst_flux[max_pr+1])
    for i in 1:num_sets
        r = rates[i]
        rates[i] = r < 1.0e-99 ? 0 : r
    end

    print(ratout, "\n Rate Coeffs. = ")
    for j in 1:num_sets
        @printf(ratout, " %8.2e", rates[j])
    end

    total_xsctns = Vector{Float64}(undef, nF+4)

    aLast = 0
    for i in 1:nF
        #? will vectorizing this be faster?
        for j in 1:16
            total_xsctns[i] += xsctn_tbl[i, j]
        end
        
        if iszero(total_xsctns[i]) || isnan(total_xsctns[i]) || issubnormal(total_xsctns[i])
            if aLast < 1.0E-40 || isnan(aLast) || issubnormal(aLast)
                maxN = i - 1
            end
        else
            aLast = total_xsctns[i]
        end
        
    end
    println(maxN)
    println(fort16, lpad(maxN, 6))
    #? use LinearIndexing
    for i in 1:5:maxN
        checkbounds(Bool, angst_flux, i) || break
        print(fotout, fmtfloat(angst_flux[i], 6, 0), ".   ")
        # @printf(fort16, "%6.0f.   ", angst_flux[i])
        for j in i:i+4
            @printf(fort16, "%10.3e ", total_xsctns[j])
        end
        println(fort16, " "^10, lpad(name1, 8))
    end
    min_pr = 10000
    max_pr = 0
    
    #=
    write(unit = 15, fmt = "(1x, 2(a8, 2x), 1x, a12/a12, 9x, a13,
    1  f10.2, a18, f10.2/22x, a5, i5/a31, f10.2, a11, f10.2/ 22x, a5, 
    2  i5, a7, i5, a7, i5)") 
    3  (Name(i), i=1,2), "input error", "Flux values: ", 
    4  "AngstF(1) = ", AngstF(1), ", AngstF(nF + 1) = ", 
    5  AngstF(nF + 1), "nF = ", nF, "Cross section values: Angst1 = ", 
    6  Angst1, ", AngstL = ", AngstL, "nS = ", nS, ", n1 = ", n1, ", 
    7  nL = ", nL
    =#

    close(fort4)
    close(fort16)
    close(ratout)
    close(fotout)
end

function calc_rate_constant()

end
# fotrat(0)