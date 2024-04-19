using DelimitedFiles, Printf
# include("vars.jl")


const kB::Float64 = 1.3806505e-23
const  ħ::Float64 = 6.6260755e-34 # \hbar
const  c::Float64 = 2.99792458e+08
const c₁::Float64 = 2π*c # 1.8836516e+09 m/s
const c₂::Float64 = ħ*c/kB # 1.4387765e-02 Kelvin m

"""
This program calculates the number of photons emitted per unit area per unit time per unit 
wavelength for a blackbody (BB).  From this it calculates the number of photons in each wavelength 
in per unit area.  NBB_lambda = 2*pi*c/[lambda**4*[e**[h*c/[(k*lambda*T)] - 1].
Then it calculates the BB rate coefficients.  BBGrid is based on solar fluxes grid, except one grid 
point is inserted where the BB function is near its maximum for various temperatures.  A few 
additional grid points have been added at long wavelengths.

# Physical constants:
Avogadro constant N0 = 6.0221415E+23 atoms/(g-mol)
Boltzmann constant kB = 1.3806505E-23 J/K
Planck constant ħ = 6.6260755E-34 J s 
Speed of light c = 2.99792458E+08 m/s

# Mathematical constants:
e = 2.718281828459045d+00
pi = 3.141592653589793d+00

lambda is the photon wavelength in Angstrom (1 A = 1.E-10 m). 
temp is the blackbody temperature in K.
"""
function bbrad!(angst_flux::AbstractVector, temp::AbstractFloat)

    bbflux = open("BBFlux.dat", "rw")

    #? consolidate num_pts and nF into one variable
    num_pts = 337
    if num_pts > GR_PT_LIM
        println(stderr, " *** Increase GrPtLim. ***")
    end

    # bbgrid
    angst_flux = zeros(Float64, lim_grid_pts)
    open("BBGrid.dat", "a") do bbgrid
        angst_flux[i] = parse.(Float32, readlines(bbgrid))
    end


    open("BBFlux.dat", "rw") do bbflux
        NBB1 = 0.0 # Number of photons emitted per unit area per unit wavelength at lower wavelength 
                   # of first bin.

        #? num_pts - 1?
        for i in 1:num_pts
            if c₂ / (1E-10temp * angst_flux[i+1]) < 700
                NBB2 = 1.0E-4c₁ / (1.0E-10angst_flux[i+1]) ^ 4 / expm1(c₂ / (1.0E-10temp * angst_flux[i+1]))
                fluxes[i] = 5.0E-11(NBB1 + NBB2) * (angst_flux[i+1] - angst_flux[i])
            else
                fluxes[i] = 0.0
            end
            @printf(bbflux, "%10.2f%10.2e\n", angst_flux[i], fluxes[i])
            NBB1 = NBB2
        end

        @printf(bbflux, "%10.2f\n", angst_flux[num_pts])
        @printf(summary, "The radiation field is from a blackbody at T =%11.2fK.\n", T)
    end
    #? make this (nF) a variable, pass to functions!
    return num_pts
end
