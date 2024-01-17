# physical constants
const kB::Float128 = 1.3806505e-23
const  ħ::Float128 = 6.6260755e-34 # \hbar
const  c::Float128 = 2.99792458e+08

"""
This program calculates the number of photons emitted per unit area per unit time per unit 
wavelength for a blackbody (BB).  From this it calculates the number of photons in each wavelength 
in per unit area.  NBB_lambda = 2*pi*c/[lambda**4*[e**[h*c/[(k*lambda*T)] - 1].
Then it calculates the BB rate coefficients.  BBGrid is based on solar flux grid, except one grid 
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
function bbrad(temp::Float64) # AbstractFloat param?
    const limA = 50000
    const limB = 2000
    const limF = 1000
    # nmax = 300
    const lim_grid_pts = 400
    const num_grid_pts = 337

    #=
    xsctplt = zeros(Float64, limB+1)
    ratepl = zeros(Float64, limB+1)
    angplt = zeros(Float64, limB+1)
    angsts = zeros(Float64, limA+1)
    angpl = zeros(Float64, limA+1)
    sigpl = zeros(Float64, limA+1)
    =#

    flux = zeros(Float64, limF)
    # consolidate black_body_grid to be angstf
    angstf = zeros(Float64, limF+1)
    black_body_grid = zeros(Float64, lim_grid_pts)

    const c₁ = 2π*c # 1.8836516e+09 m/s
    const c₂ = ħ*c/kB # 1.4387765e-02 Kelvin m
    # angstc = 
    
    i = 1
    NBB1 = 0.0

    angstf[i] = black_body_grid[i]
    angstf[i+1] = black_body_grid[i+1]

    while i < num_grid_pts
        # some calculation stuff!?
        if c₂ / (temp * angstf[nF+1]) < 7.0E-8
            NBB2 = 1.0E-4c₁ / (1.0E-10angstf[nF+1]) ^ 4 / expm1(c₂ / (1.0E-10temp * angstf[nF+1]))
            flux[nF] = 5.0E-11(NBB1 + NBB2)*(angstf[nF+1] - angstf[nF])
        else
            flux[nF] = 0.0 # might want to ensure type safety
        end

        i += 1

        angstf[i+1] = black_body_grid[i+1]
        NBB1 = NBB2
    end

    return flux
end

# 11/7/23 8:30-9:45