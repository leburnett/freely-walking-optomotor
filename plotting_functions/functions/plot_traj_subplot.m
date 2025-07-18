function plot_traj_subplot(DATA, strain, condition_n, save_folder)

    % Plot trajectories of the different strains and different conditions
    data = DATA.(strain).F;
    
    data_type = "x_data"; 
    cond_data_x = combine_timeseries_across_exp(data, condition_n, data_type);
    
    data_type = "y_data"; 
    cond_data_y = combine_timeseries_across_exp(data, condition_n, data_type);
    
    % Define the center of the arena
    cx = 122.8079; %calib.centroids(1)/calib.PPM; 
    cy = 124.7267; %calib.centroids(2)/calib.PPM;
    
    frame_rng_stim = 300:1200;
    
    total_n_flies = height(cond_data_x);
    n_plots_per_fig = 35;
    
    n_plots = ceil(total_n_flies/n_plots_per_fig);

    for p = 1:n_plots

        flies_to_plot = (p*n_plots_per_fig)-(n_plots_per_fig-1):1:(p*n_plots_per_fig); 
        if p == n_plots 
            flies_to_plot = (p*n_plots_per_fig)-(n_plots_per_fig-1):1:total_n_flies;
        end 
        
        figure; 
        tiledlayout('flow', 'TileSpacing', 'compact')
        
        for i = flies_to_plot
            nexttile
            x_data = cond_data_x(i, :);
            y_data = cond_data_y(i, :);    
        
            x = x_data(frame_rng_stim); % x position over time (1 x n)
            y = y_data(frame_rng_stim); % y position over time (1 x n)
            
            plot_trajectory_simple(x, y, cx, cy)
            axis off
            if i ~= flies_to_plot(end)
                legend off
            else
                lgd = legend;
                lgd.Position = [0.8309    0.1333    0.0562    0.0445];
            end 
        end 
    
        sgtitle(strcat(strrep(strain, '_', '-'), "- Condition ", string(condition_n), " - ", string(flies_to_plot(1)), ":", string(flies_to_plot(end))))
    
        f = gcf;
        f.Position = [2577        -150        1218        1112];

        % Save the figure:
        f_name = fullfile(save_folder, strcat("Traj_fig", string(p),"_", strain, "_Condition", string(condition_n), ".pdf"));
        
        exportgraphics(f ...
                , f_name ...
                , 'BackgroundColor', 'none' ...
                , 'Resolution', 90 ...
                );
        %                % , 'ContentType', 'vector' ... % Use if you want
        %                to generate high quality figures.
        close
    end 
end 












