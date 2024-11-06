function plot_pink_blue_rects(LOG, protocol, min_val, max_val)
% Plot pink and blue rectangles on a plot corresponding to when the
% gratings are moving clockwise or counterclockwise. 

    if protocol == "protocol_10"

        log_names = fieldnames(LOG);

        h = max_val - min_val;
        
        % acclim off1 end 
        off1_f = LOG.acclim_off1.stop_f;
        plot([off1_f, off1_f], [min_val, max_val], 'k', 'LineWidth', 1)
        hold on
        % static pattern off
        pat_f = LOG.acclim_patt.stop_f;
        plot([pat_f, pat_f], [min_val, max_val], 'k', 'LineWidth', 1)

        for l_idx = 4:length(log_names)-1

            Log = LOG.(log_names{l_idx});
            n_conditions = numel(Log.trial);
    
            for ii = 1:n_conditions
            
                % Get the timing of each condition
                st_fr = Log.start_f(ii);
                stop_fr = Log.stop_f(ii)-1;
                w = stop_fr - st_fr;
            
                % Use the Log.dir value to get the stimulus direction.
                dir_id = Log.dir(ii);
                con_val = 1; %Log.contrast(ii);
                if con_val > 1.2
                    con_val = 1;
                end 
            
                if dir_id == 0 
                    col = [0.9 0.9 0.9];
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
        end

        % acclim off2 end 
        off2_f = LOG.acclim_off2.stop_f;
        plot([off2_f, off2_f], [min_val, max_val], 'k', 'LineWidth', 1)

    else

        h = max_val - min_val;
        n_conditions = length(Log);
    
        for ii = 1:n_conditions
        
            % Get the timing of each condition
            st_fr = Log.start_f(ii);
            stop_fr = Log.stop_f(ii)-1;
            w = stop_fr - st_fr;
        
            % Use the Log.dir value to get the stimulus direction.
            dir_id = Log.dir(ii);
            con_val = 1;
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
    end 
end 













