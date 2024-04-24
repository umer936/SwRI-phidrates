using Printf, DelimitedFiles

function fotrat!(branches, angsts, xsctn_data, angst_flux)
    ratout  = open("RatOut", "w+") # Binned rate coefficients per Angstrom.
    fotout  = open("FotOut", "w+") # Binned Cross Sections.

    num_sets = length(branches)

    fix_xsctns = Vector{Float64}(undef, MAX_ANGSTS)
    fix_angsts = Vector{Float64}(undef, MAX_ANGSTS) # + 2

    xsctn_tbl = Matrix{Float64}(undef, MAX_ANGSTS, num_sets)
    # rate_tbl = Matrix{Float64}(undef, MAX_ANGSTS, num_sets)
    
    tot_rates = zeros(Float64, num_sets)

    min_pr = typemax(Int)
    max_pr = 0

    for s in 1:num_sets
        # Note: in contrast to the variables in branch.jl, these represent the current branch's information
        angstN = branches[s].angstN
        angst1 = branches[s].angst1
        angstL = branches[s].angstL

        xsctns = xsctn_data[:, s]

        angst1 - angstL >= -1.0e-6 || angst1 < angst_flux[1] || angstL > angst_flux[nF] && break

        tot_rates[s] = 0

        # get ranges of flux angstroms w.r.t min/max angstrom 
        n1 = 0
        nL = 0
        for i in 1:nF
            if angst_flux[i] - angst1 <= 1.0e-6
                n1 = i
            end
            if angst_flux[i] < angstL
                nL = i
            end
        end
        # n1 = findfirst(ang -> ang - angst1 <= 1.0E-6, angst_flux)
        # nL = findlast(ang -> ang < angstL, angst_flux)
        nL <= n1 && break

        min_pr = min(n1, min_pr)
        max_pr = max(nL, max_pr)
        
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
                xsctn_tbl[n, s] = tmp_xsctn
                # rate_tbl[n, s] = tmp_xsctn * fluxes[n]
            else
                if fix_angsts[k+1] >= angst_flux[n+1]
                    tmp_xsctn = xt / (angst_flux[n+1] - angst_flux[n])
                    xsctn_tbl[n, s] = tmp_xsctn
                    # rate_tbl[n, s] = tmp_xsctn * fluxes[n] # can be moved to the output section as xsctn_tbl[n, s] * fluxes[n]

                    tot_rates[s] += tmp_xsctn * fluxes[n] # can be moved to the output section val += xsctn_tbl[n, s] * fluxes[n]; print(val)

                    n += 1
                    xt = 0
                end
            end
        end
    end

    #=
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
            @printf(fotout, "%9.2e", xsctn_tbl[i, j])
            @printf(ratout, "%9.2e", rate_tbl[i, j])
        end
        println(fotout)
        println(ratout)
    end

    print(fotout, fmtfloat(angst_flux[max_pr + 1], 7, 1))
    print(ratout, fmtfloat(angst_flux[max_pr + 1], 7, 1))
    =#

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
            @printf(fotout, "%9.2e", xsctn_tbl[i, j])
            @printf(ratout, "%9.2e", xsctn_tbl[i, j] * fluxes[i])
        end
        println(fotout)
        println(ratout)
    end

    print(fotout, fmtfloat(angst_flux[max_pr + 1], 7, 1))
    print(ratout, fmtfloat(angst_flux[max_pr + 1], 7, 1))

    # write_output(fotout, branches, angst_flux, xsctn_tbl, min_pr:max_pr)
    # write_output(ratout, branches, angst_flux, rate_tbl, min_pr:max_pr)
    
    print(ratout, "\n Rate Coeffs. = ")
    foreach(r -> @printf(ratout, " %8.2f", r < 1.0e-99 ? 0 : r), tot_rates)

    close(ratout)
    close(fotout)

    # total_xsctns
    return reduce(+, xsctn_tbl, dims=1)
end

function write_output(io::IO, 
        branches::AbstractVector{BranchProfile}, 
        x::AbstractVector{T}, 
        y::AbstractMatrix{T}, 
        r::AbstractRange) where {T<:AbstractFloat}
    
    num_sets = length(branches)

    println(io, lpad(num_sets, 2) * " "^49 * lpad(branches[1].name1, 8))
    println(io, " Lambda         ", join(rpad.(map(br -> br.name2, branches[2:end]), 8),' '))

    for i in r
        print(io, fmtfloat(x[i], 7, 1), "        ")
        for j in 1:num_sets
            @printf(io, "%9.2e", y[i, j])
        end
        println(io)
    end

    print(io, fmtfloat(x[r.stop + 1], 7, 1))
end