function plotxsctn(na, angst_plot, xsctn_plot)
    NAME = ["        ", "        "]
    ndxx = zeros(Int, 3001)
    
    ymin = 1000.0
    ymax = -100.0
    
    xmin = min(angst_plot[1], 10000.0)
    xmax = max(angst_plot[na], 0.0)
    
    for i in 1:na
        xsctn_plot[i] < -22 && continue

        ymin = min(xsctn_plot[i], ymin)
        ymax = max(xsctn_plot[i], ymax)
    end
    
    ymin -= 0.1
    ymax += 0.1
    
    for i in 1:na
        smax = -1.0
        for j in 1:na
            xsctn_plot[j] < ymin && continue
            sminp = ymax - xsctn_plot[j]
            sminm = xsctn_plot[j] - ymin
            if sminp * sminm < smax || ndxx[j] > 890
                continue
            end
            
            smax = sminp * sminm
        end
        
        smax < -1.0e50 &&  continue
    end
    
    
    return; 
    
    return
end