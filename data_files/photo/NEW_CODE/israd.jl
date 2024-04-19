using DelimitedFiles, Printf

function israd()
    num_pts = 337
    if num_pts > GR_PT_LIM
        println(stderr, " *** Increase GrPtLim. ***")
    end

    # isgrid
    angst_flux = zeros(Float64, GR_PT_LIM)
    open("BBGrid.dat", "a") do bbgrid
        angst_flux[i] = parse.(Float32, readlines(bbgrid))
    end
    
    open("ISFlux.dat", "w") do isflux
        # Read basic wavelength grid for IS wavelength grid
        NIS1 = 0.0
        
        # nF = 1
        # angst_flux[1] = isgrid[1]   # Lower wavelength of a bin
        # angst_flux[2] = isgrid[2] # Upper wavelength of a bin
        
        for i in 1:num_pts
            if angst_flux[i+1] < 911
                NIS2 = 0
            elseif angst_flux[i+1] < 2000
                NIS2 = 1.0E15 * (3.2028 - 5154.2 / angst_flux[i+1] + 2054600 / angst_flux[i+1]^2) / angst_flux[i+1]^3
            elseif angst_flux[i+1] == 2000
                NIS2 = 1.0E15 * ((3.2028 - 5154.2 / angst_flux[i+1] + 2054600 / angst_flux[i+1]^2) / angst_flux[i+1]^3 +
                        732.26angst_flux[i+1]^0.7) / 2
            else
                NIS2 = 732.26angst_flux[i+1]^0.7
            end
            
            fluxes[i] = (NIS1 + NIS2) * (angst_flux[i+1] - angst_flux[i]) / 2
            
            # Interstellar photon flux
            @printf(isflux, "%10.2f%10.2e\n", angst_flux[i], fluxes[i])
         
            # nF += 1
            # angst_flux[i+1] = isgrid[i+1]
            
            NIS1 = NIS2
        end
        @printf(isflux, "%10.2f\n", angst_flux[nF])
        
        open("Summary", "a") do summary
            println(summary, "The radiation field is interstellar.")
        end
    end

    return num_pts
end