function plot_scatter_vel_all_flies(data_to_use, n_flies, title_str, save_str, fig_exp_save_folder, save_figs)
    % Inputs
    % ______

    % data_to_use : double, size [n_conditions x n_flies+2]
    %       Matrix containing the data to be plotted. 
    %       Each row corresponds to one condition. The first column has the
    %       contrast value for each condition and the last column has the
    %       direction of movement. 
    %       The middle columns each represent one fly and their average
    %       angular velocity over the 10s condition.

    % n_flies : int
    %       Number of flies in the experiment.  

    % title_str : str
    %       string used for the title of the plot.

    % save_str : str
    %       string used when saving the figure.

    % fig_exp_save_folder : Path
    %        Path to save the figure.    
    
    % save_figs : bool 
    %        Whether to save the figures and data or not.  
    
    n_cond_to_use = size(data_to_use, 1);
    
    figure
    for idx = 1:n_cond_to_use
    
        contrast_value = data_to_use(idx, 1);
        c_vals = ones(1, n_flies)*contrast_value;
    
        dir_id = data_to_use(idx, n_flies+2);
    
        ang_data_for_c = data_to_use(idx, 2:n_flies+1);
    
        if dir_id == 0 
            if idx == 1 || idx == 33
                col = [0.5 0.5 0.5];
                m_alpha = 0.3; 
            elseif idx == 17 || idx == 32
                col = [0 0 0];
                m_alpha = 0.3;
            else
                col = [1 1 1];
                m_alpha = 1;
            end 
        elseif dir_id == 1
            col = [0 0 1];
            m_alpha = contrast_value*0.75;
        elseif dir_id == -1
            col = [1 0 1];
            m_alpha = contrast_value*0.75;
        end 
    
        scatter(c_vals, ang_data_for_c, 100, 'o', 'MarkerFaceColor', col, 'MarkerFaceAlpha', m_alpha, 'MarkerEdgeColor', [0.7 0.7 0.7], 'XJitter', 'rand', 'XJitterWidth', 0.04);
        hold on;
    end 
        
    plot([0 0], [-2.5 22.5], 'k', 'LineWidth', 0.5);
    plot([1.1 1.1], [-2.5 22.5], 'k', 'LineWidth', 0.5);
    box off
    xlim([-0.3 1.5])
    ylim([0 20])
    set(gcf, "Position", [239  565  1080  466])
    set(gca, "LineWidth", 1, "TickDir", 'out', "FontSize", 12, "TickLength", [0.01 0.01])
    title(strcat(title_str, ' - N=', string(n_flies)))
    xticks(unique(data_to_use(:, 1)))
    xticklabels({'OFF', 'ON', '0.11', '0.20', '0.33', '0.40', '0.56', '0.75', '1', 'FLICKER1','FLICKER2', 'OFF'})
    xtickangle(45)
    ylabel('Velocity')
    xlabel('Condition / Contrast')
    
    if save_figs == true
        savefig(gcf, fullfile(fig_exp_save_folder, strcat('Vel_Scatter_', save_str)))
    end 
    
end 