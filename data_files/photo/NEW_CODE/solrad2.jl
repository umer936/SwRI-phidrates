
"""
Calculates solar photon fluxes for the activity level of the sun

    0.00 = quiet sun, 1.00 = active sun
"""
function solrad(SA::AbstractFloat)
    nSA = 162
    nF = 324

    photoflux = Vector{Float64}(undef, 2nF+1)
    fluxratio = Vector{Float64}(undef, nSA)
    
    open("PhFlux.dat", "r") do phflux
        data = readdlm(phflux)
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

        angst_flux[i] = photoflux[j-1]
        if i <= nSA
            fluxes[i] = photoflux[j] + SA * (fluxratio[i] - 1) * photoflux[j]
        else
            fluxes[i] = photoflux[j]
        end
    end
    
    angst_flux[nF+1] = photoflux[2nF+1]
    
    open("Summary", "w") do summary
        println(summary, "The radiation field is that of the Sun at 1 AU heliocentric distance.")
        @printf(summary, "The solar activity =%5.2f.\n", SA)
        println(summary, "(The quiet Sun has solar activity 0.00, the active Sun has solar activity 1.00)")
    end

    return (angst_flux, fluxes)
end


