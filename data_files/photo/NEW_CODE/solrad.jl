
"""
Calculates solar photon flux for the activity level of the sun

    0.00 = quiet sun, 1.00 = active sun
"""
function solrad(SA::Float64)
    limB = 2000
    limF = 1000
    nSA = 162
    nf = 324

    fluxplot  = zeros(Float64, limB)
    angplot   = zeros(Float64, limB+1)
    photoflux = zeros(Float64, limB+1)

    flux   = zeros(Float64, limF)
    angstf = zeros(Float64, limF+1)

    fluxratio = zeros(Float64, nSA)

    photofluxdat = open("PhFlux.dat")

    for i in 1:nF
        j = 2i # ensure type efficiency thing!

        angstf[i] = photoflux[j-1]

        angplot[j-1] = ifelse(j != 2, log10(photoflux[j-1]), 0)
        angplot[j]   = log10(photoflux[j+1])

        fluxplot[j], fluxplot[j-1] = log10(photoflux[j] / (photoflux[j+1] - photoflux[j-1]))

        flux[i] = photoflux[j]
        if i <= nSA
            flux[i] += SA * (fluxratio[i] - 1) * flux[i]
        end
    end
    
    angstf[nf+1] = photoflux[2nf-1]

    return;
end


