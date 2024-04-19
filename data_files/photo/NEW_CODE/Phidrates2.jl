module Phidrates2

using DelimitedFiles, Printf, Profile, PProf

set_zero_subnormals(true)
#===========#
# CONSTANTS #
#===========#
const MAX_ANGSTS = 50000
const MAX_BRANCHES = 2000
const MAX_FLUX = 1000

const nSA = 162
const GR_PT_LIM = 400

#=======#
# FILES #
#=======#
run(`/bin/bash /usr/local/var/www/SwRI-phidrates/data_files/bash_cross_sections_jl.cgi`)
cd(readchomp("/usr/local/var/www/SwRI-phidrates/data_files/photo/NEW_CODE/store.txt"))
println(pwd())
input = open("Input", "r") # Input parameters:  Sol, BB, IS, AS, T, etc.
#============#
# INITIALIZE #
#============#
nF = 0

#==========#
# INCLUDES #
#==========#
include("common.jl")

include("branch2.jl")

include("solrad2.jl")
include("bbrad.jl")
include("israd.jl")

include("fotrat2.jl")
include("convert2.jl")

#========#
# BRANCH #
#========#

@time angsts::Vector{Float64}, xsctn_tbl::Matrix{Float64}, bprofs::Vector{BranchProfile} = branch()

#==============#
# CALCULATIONS #
#==============#
mode = readline(input)
nF = 324
# nSA = 162
angst_flux = Vector{Float64}(undef, nF+1)
fluxes = Vector{Float64}(undef, nF+1)

if mode === "Sol"
    SA = parse(Float64, readline(input))

    nF = 324
    nSA = 162
    # angst_flux = Vector{Float64}(undef, nF+1)
    # fluxes = Vector{Float64}(undef, nF+1)
    
    @time angst_flux, fluxes = solrad(SA)
elseif mode === "BB "
    println(stderr, "dumSA = ", readline(input))
    T = parse(Float64, readline(input))
    @time bbrad(T)
elseif mode === "IS "
    @time israd()
else error("Unrecognized radiation field. Supply a valid radiation field (\"Sol,\" \"BB ,\" \"IS ,\")")
end

@time fotrat!(bprofs, angsts, xsctn_tbl, angst_flux) # Rate constants, binned cross sections
# @time convert() # Excess energies

#=============#
# CLOSE FILES #
#=============#
close(input)

end;
