function pos_data = get_pos_data_nflies(xpos, rng, data_type, delta, gp, gps2plot)

    if rng(1)==0 && data_type~="fv_data"
        if gp == gps2plot(1)
            pos_data = [xpos, rng(2)*0.1]; 
        elseif gp == gps2plot(2)
            pos_data = [xpos, rng(2)*0.2];
        elseif gp == gps2plot(3)
            pos_data = [xpos, rng(2)*0.3];
        elseif gp == gps2plot(4)
            pos_data = [xpos, rng(2)*0.4];
        elseif gp == gps2plot(5)
            pos_data = [xpos, rng(2)*0.5];
        end 
    elseif data_type == "fv_data"
        if gp == gps2plot(1)
            pos_data = [xpos, rng(2)*0.9]; 
        elseif gp == gps2plot(2)
            pos_data = [xpos, rng(2)*0.8];
        elseif gp == gps2plot(3)
            pos_data = [xpos, rng(2)*0.7];
        elseif gp == gps2plot(4)
            pos_data = [xpos, rng(2)*0.6];
        elseif gp == gps2plot(5)
            pos_data = [xpos, rng(2)*0.5];
        end 
    elseif data_type == "dist_data" && delta == 1
        if gp == gps2plot(1)
            pos_data = [xpos, rng(1)*0.9]; 
        elseif gp == gps2plot(2)
            pos_data = [xpos, rng(1)*0.7];
        elseif gp == gps2plot(3)
            pos_data = [xpos, rng(1)*0.5];
        elseif gp == gps2plot(4)
            pos_data = [xpos, rng(1)*0.3];
        elseif gp == gps2plot(5)
            pos_data = [xpos, rng(1)*0.1];
        end 
    else
        if gp == gps2plot(1)
            pos_data = [xpos, rng(2)*0.9]; 
        elseif gp == gps2plot(2)
            pos_data = [xpos, rng(2)*0.7];
        elseif gp == gps2plot(3)
            pos_data = [xpos, rng(2)*0.5];
        elseif gp == gps2plot(4)
            pos_data = [xpos, rng(2)*0.3];
        elseif gp == gps2plot(5)
            pos_data = [xpos, rng(2)*0.1];
        end 
    end 

end 