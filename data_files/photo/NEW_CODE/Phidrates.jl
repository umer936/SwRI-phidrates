module Phidrates

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

# parentbranch(data::Array{Any}) = makebranch(data[4], data[5], data[1], data[2], data[3], )
# global nSum = 0

global branch_names = fill("", 16)
global branch_nums = Vector{UInt16}(undef, 16)
global flags = zeros(Bool, 16)
global category = Vector{UInt16}(undef, 16)
global thresholds = Vector{Float64}(undef, 16)

global nF = 0

global angst_flux = Vector{Float64}(undef, MAX_FLUX + 1)
global fluxes = Vector{Float64}(undef, MAX_FLUX)

#==========#
# INCLUDES #
#==========#
include("common.jl")

include("branch.jl")

include("solrad2.jl")
include("bbrad.jl")
include("israd.jl")

include("fotrat.jl")
include("convert.jl")

#========#
# BRANCH #
#========#

@time branch()

#==============#
# CALCULATIONS #
#==============#
# Read some input information
mode = readline(input)
skipchars(isspace, input) #? do I need this?
if mode === "Sol"
    SA = parse(Float64, readline(input))
    nF = 324
    @time solrad(SA)
elseif mode === "BB "
    println(stderr, "dumSA = ", readline(input))
    T = parse(Float64, readline(input))
    @time bbrad(T)
elseif mode === "IS "
    @time israd()
else error("Unrecognized radiation field. Supply a valid radiation field (\"Sol,\" \"BB ,\" \"IS ,\")")
end

@time fotrat() # Rate constants, binned cross sections
@time convert() # Excess energies

#=============#
# CLOSE FILES #
#=============#
close(input)

end;
