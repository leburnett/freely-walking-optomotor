function generate_scatter_traj_subplot(binned_data, cmap_array, flyId, fig_save_folder)

    figure;
    % Top subplot = Scatter plot of forward velocity versus rotational
    % velocity. Colorscale = time. 
    subplot(1,2,1)
    plot_Vf_Va_scatter(binned_data.Vf, binned_data.Va, cmap_array, 1, flyId)
    
    % Bottom subplot = trajectory of the fly during the grating stimulus. 
    % Coloscale = time.
    subplot(1,2,2)
    plot_coloured_trajectory(binned_data.x, binned_data.y, cmap_array, flyId)
    axis tight
    
    f = gcf;
    f.Position = [178   480   960   397]; % [620   546   486   421];
    
    % Add fly number as title
    sgtitle(strcat("Fly ", string(flyId)))

    % Save the plot as a pdf
    save_str = strcat("Fly_", string(flyId), ".pdf");
    fname = fullfile(fig_save_folder, save_str);
    exportgraphics(f ...
        , fname ...
        , 'ContentType', 'vector' ...
        , 'BackgroundColor', 'none' ...
        ); 

end 