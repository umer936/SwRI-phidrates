using Base.Filesystem

amop_site="https://phidrates.space.swri.edu/"
amop_cgi_bin_dir="/web/phidrates/data_files"
amop_gif_alias="/phidrates_images/"
prefix="/web/phidrates/tmp/"
reg_exp_prefix="/web/phidrates/tmp"

function read_vars()

end

function convert_canonical_branch_name()

end

struct GnuplotVars 
    title
    xlabel
    ylabel
    issemilog
end

const TEST_GP::GnuplotVars = GnuplotVars("TEST_TITLE", "TEST_X", "TEST_Y", false)

function prepare_env(gp::GnuplotVars=TEST_GP)
    temp_dir = mktempdir()
    run(``)
    return temp_dir
end


"""
Calculate the excess energies for the interstellar radiation field
"""
function excess_energy(target)

end

"""
Calculate the excess energies for the solar radiation field, given a solar activity
"""
function excess_energy(target, solaractivity)

end

"""
Calculate the excess energies for a blackbody radiation field, given a temperature in Kelvin between _________
"""
function excess_energy(target, temp)
    @assert temp in 0:10000

    target_file = "../hrecs/$target.dat"
end

function create_plot()
    
end

temp_dir = mktempdir()
