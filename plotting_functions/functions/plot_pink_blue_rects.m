function plot_pink_blue_rects(Log, protocol, min_val, max_val)

    h = max_val - min_val;
    n_conditions = height(Log);

    for ii = 1:n_conditions
    
        % Get the timing of each condition
        st_fr = Log.start_f(ii);
        stop_fr = Log.stop_f(ii)-1;
        w = stop_fr - st_fr;
    
        % Use the Log.dir value to get the stimulus direction.
        dir_id = Log.dir(ii);
        con_val = Log.contrast(ii);
        if con_val > 1.2
            con_val = 1;
        end 
    
        if dir_id == 0 

            if protocol == "protocol_v1"
                if ii == 1 || ii == 33
                    col = [0.5 0.5 0.5 0.3];
                elseif ii == 17 || ii == 32
                    col = [0 0 0 0.5];
                else
                    col = [1 1 1];
                end 
            else
                if ii == 1 || ii == 21
                    col = [0.5 0.5 0.5 0.3];
                elseif ii == 11 || ii == 20
                    col = [0 0 0 0.5];
                else
                    col = [1 1 1];
                end 
            end 
    
        elseif dir_id == 1
            col = [0.2 0.2 1 con_val*0.75];
        elseif dir_id == -1
            col = [1 0.2 1 con_val*0.75];
        end 
    
        % Plot rectangles in the background of when the stimulus changes. 
        rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
        ylim([min_val, max_val])
        hold on 
        box off
        ax = gca;
        ax.XAxis.Visible = 'off';
    end 














