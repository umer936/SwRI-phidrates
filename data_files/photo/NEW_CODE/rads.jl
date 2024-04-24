using DelimitedFiles, Printf

const global kB::Float64 = 1.3806505e-23
const global  ħ::Float64 = 6.6260755e-34 # \hbar
const global  c::Float64 = 2.99792458e+08
const global c₁::Float64 = 2π*c # 1.8836516e+09 m/s
const global c₂::Float64 = ħ*c/kB # 1.4387765e-02 Kelvin m

const GR_PT_LIM::Int32 = 400

function solrad!(angstflux::AbstractVector{T}, fluxes::AbstractVector{T}, SA::T) where {T<:Real}
    local nSA = 162
    local nF = 324

    photoflux = similar(angstflux, 2nF+1)
    fluxratio = similar(angstflux, nSA)
    
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

function bbrad!(angstflux::AbstractVector{T}, fluxes::AbstractVector{T}, temp::T) where {T <: Real}
    num_pts::Int64 = 337
    if num_pts > GR_PT_LIM
        println(stderr, " *** Increase GrPtLim. ***")
    end

    # bbgrid
    open("BBGrid.dat", "r") do bbgrid
        data::Array{Union{SubString{String}, Int64, Float64}} = readdlm(bbgrid)
        for i in 1:num_pts
            angstflux[i] = data[i, 1]::Float64
        end
    end


    open("BBFlux.dat", "rw") do bbflux
        NBB1 = 0.0 # Number of photons emitted per unit area per unit wavelength at lower wavelength 
                   # of first bin.

        for i in 1:num_pts
            if c₂ / (1E-10temp * angstflux[i+1]) < 700
                NBB2 = 1.0E-4c₁ / (1.0E-10angst_flux[i+1]) ^ 4 / expm1(c₂ / (1.0E-10temp * angstflux[i+1]))
                fluxes[i] = 5.0E-11(NBB1 + NBB2) * (angstflux[i+1] - angstflux[i])
            else
                fluxes[i] = 0.0
            end
            NBB1 = NBB2

            @printf(bbflux, "%10.2f%10.2e\n", angstflux[i], fluxes[i])
        end

        @printf(bbflux, "%10.2f\n", angstflux[num_pts])
        @printf(summary, "The radiation field is from a blackbody at T =%11.2fK.\n", T)
    end

    nothing
end


function israd!(angstflux::AbstractVector{T}, fluxes::AbstractVector{T}) where {T <: Real}
    num_pts::Int64 = 337
    if num_pts > GR_PT_LIM
        println(stderr, " *** Increase GrPtLim. ***")
    end

    # isgrid
    open("/usr/local/var/www/SwRI-phidrates/data_files/photo/NEW_CODE/BBGrid.dat", "r") do bbgrid
        data::Array{Union{SubString{String}, Int64, Float64}} = readdlm(bbgrid)
        for i in 1:num_pts
            angstflux[i] = data[i, 1]::Float64
        end
    end
    
    open("ISFlux.dat", "w") do isflux
        # Read basic wavelength grid for IS wavelength grid
        NIS1 = 0.0
        
        # nF = 1
        # angstflux[1] = isgrid[1]   # Lower wavelength of a bin
        # angstflux[2] = isgrid[2] # Upper wavelength of a bin
        
        for i in 1:num_pts
            if angstflux[i+1] < 911
                NIS2 = 0
            elseif angstflux[i+1] < 2000
                NIS2 = 1.0E15 * (3.2028 - 5154.2 / angstflux[i+1] + 2054600 / angstflux[i+1]^2) / angstflux[i+1]^3
            elseif angstflux[i+1] == 2000
                NIS2 = 1.0E15 * ((3.2028 - 5154.2 / angstflux[i+1] + 2054600 / angstflux[i+1]^2) / angstflux[i+1]^3 +
                        732.26angst_flux[i+1]^0.7) / 2
            else
                NIS2 = 732.26angst_flux[i+1]^0.7
            end
            
            fluxes[i] = (NIS1 + NIS2) * (angstflux[i+1] - angstflux[i]) / 2
            
            # Interstellar photon flux
            # @printf(isflux, "%10.2f%10.2e\n", angstflux[i], fluxes[i])
         
            # nF += 1
            # angstflux[i+1] = isgrid[i+1]
            
            NIS1 = NIS2
        end
        @printf(isflux, "%10.2f\n", angstflux[nF])
        
        open("Summary", "a") do summary
            println(summary, "The radiation field is interstellar.")
        end
    end

    nothing
end