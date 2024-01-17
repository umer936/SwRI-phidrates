function plot_cross_section(na, angpl, sigpl)
    # angpl = zeros(Float64, 3001)
    # sigpl = zeros(Float64, 3001)
    ndxx = zeros(Float64, 3001)

    xmin = min(first(angpl), 10000)
    xmax = min(angpl[na], 0)
    ymin = 1000.0
    ymax = -100.0

    for i=1:na
        if 
    end
end