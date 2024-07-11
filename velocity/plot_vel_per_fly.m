function plot_vel_per_fly(Log, feat, n_flies, n_conditions, title_str, save_str, fig_exp_save_folder, save_figs)

    
    figure
    for idx = 1:n_flies
        subplot(n_flies, 1, idx)
        V = feat.data(idx,:,1);
        max_val = max(V);
        min_val = min(V);
        h = max_val - min_val;
        
        
        for ii = 1:n_conditions
        
            % create the plot
            st_fr = Log.start_f(ii);
            stop_fr = Log.stop_f(ii)-1;
            w = stop_fr - st_fr;
            dir_id = Log.dir(ii);
    
            if dir_id == 0 
                if ii == 1 || ii == 33
                    col = [0.5 0.5 0.5 0.3];
                elseif ii == 17 || ii == 32
                    col = [0 0 0 0.3];
                else
                    col = [1 1 1];
                end 
            elseif dir_id == 1
                col = [0 0 1 Log.contrast(ii)*0.75];
            elseif dir_id == -1
                col = [1 0 1 Log.contrast(ii)*0.75];
            end 
            
            % Add rectangles denoting the different types of experiment.
            rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6]);
            ylim([min_val, max_val])
            hold on 
            box off
            ax = gca;
            ax.XAxis.Visible = 'off';
        end 

        plot(V, 'k', 'LineWidth', 1)

    end 

    sgtitle(strcat(title_str, ' - N=', string(n_flies)))
    f = gcf; 
    f.Position = [2162  -476  794  1520];
    
    if save_figs == true
        savefig(gcf, fullfile(fig_exp_save_folder, strcat('Vel_perfly_', save_str)))
    end 

end 