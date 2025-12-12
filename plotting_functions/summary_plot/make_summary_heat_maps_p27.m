function DATA = make_summary_heat_maps_p27(zscore, compare_to_ES, DATA)

%   Inputs
%   ______
%           zscore : bool   
%               If positive, find the z-scored value per metric within a
%               strain. 
%           compare_to_ES : bool
%               If positive, the heatmaps show the p-values of the 
%               statistical tests comparing the target strain versus the    
%               empty split control flies. 
%               TODO - bootstrapping for the statistics  - compare the 
%               same number of ES flies as the target line.  


    % ROOT_DIR = 'C:\Users\burnettl\Documents\oakey-cokey'; % Processing computer
    ROOT_DIR = "/Users/burnettl/Documents/Projects/oaky_cokey";
    
    if ~exist('DATA', 'var') == 1
        % Move to the directory to where the results per experiment are saved:
        protocol_dir = fullfile(ROOT_DIR, 'results', 'protocol_27');
        cd(protocol_dir);
    
        DATA = comb_data_across_cohorts_cond(protocol_dir);
    end 

    % Add the matrices "dist_dt" - centring rate - for each experiment. 
    % This is not currently included in the standard processing pipeline
    % and so has to be added later here.
    DATA = add_dist_dt(DATA);

     cond_titles = {"60deg-gratings-4Hz"...
        , "60deg-gratings-8Hz"...
        , "narrow-ON-bars-4Hz"...
        , "narrow-OFF-bars-4Hz"...
        , "ON-curtains-8Hz"...
        , "OFF-curtains-8Hz"...
        , "reverse-phi-2Hz"...
        , "reverse-phi-4Hz"...
        , "60deg-flicker-4Hz"...
        , "60deg-gratings-static"...
        , "60deg-gratings-0-8-offset"...
        , "32px-ON-single-bar"...
        };

    % Heatmap = p-values of comparison between ES and strains based on raw
    % (not z-score) values of metrics. 

    pvals_all_cond = [];
    target_all = [];
    control_all = [];

    % Combine the data across the conditions
    for condition_n = 9 %1:12 % [1,2,9,10]

        [pvals_cond, target_mean_all, control_mean_all, strain_names] = make_pvalue_heatmap_across_strains(DATA, condition_n);
    
        pvals_all_cond = vertcat(pvals_all_cond, pvals_cond);
        target_all = vertcat(target_all, target_mean_all);
        control_all = vertcat(control_all, control_mean_all);
    end 
    
    % Strains on the y axis 
    % Only 4Hz gratings. 

    [~, ~, adj_p_all]=fdr_bh(pvals_all_cond, 0.001, 'dep', 'yes');

    figure
    plot_pval_heatmap(adj_p_all, target_all, control_all, strain_names, condition_n);


    % Format the plot.
    grid on
    ax = gca;
    xt = ax.XTick;
    ax.XTick = xt + 0.5; 
    yt = ax.YTick;
    ax.YTick = yt + 0.5;
    ax.XAxis.TickLength = [0 0];
    ax.YAxis.TickLength = [0 0]; 
    ax.FontSize = 12;

    title(strrep(cond_titles{condition_n}, '_', '-'))

    f = gcf;
    f.Position = [118   469   467   466]; % [2612  -522  373  1588]; %[564    73   362   974];

 
    
    % if zscore == 0 && compare_to_ES == 1
    %     %% Perform FDR adjustment to p-values.
    %     [~, ~, adj_p_all]=fdr_bh(pvals_all_cond, 0.001, 'dep', 'yes');
    %     % adj_p_all is of the size [n_strains*n_conditions, n_metrics]
    % 
    %     %% Plot the heatmap divided up by STRAIN 
    %     n_strains = numel(strain_names);
    %     f = tiledlayout(n_strains, 1);
    %     f.Padding = "tight";
    %     multi = 1;
    % 
    %     h_all = height(pvals_all_cond);
    % 
    %     for strain_n = 1:n_strains
    % 
    %         nexttile
    % 
    %         % Extract the interleaved values
    %         rng = strain_n:n_strains:h_all;
    % 
    %         adj_p = adj_p_all(rng, :);
    %         t_all = target_all(rng, :);
    %         c_all = control_all(rng, :);
    % 
    %         if strain_n <n_strains
    %             plot_x = 0;
    %         else
    %             plot_x = 1;
    %         end 
    % 
    %         % Plot the data: 
    %         plot_pval_heatmap_strains(adj_p, t_all, c_all, plot_x, multi)
    % 
    %         % Format the plot.
    %         grid on
    %         ax = gca;
    %         xt = ax.XTick;
    %         ax.XTick = xt + 0.5; 
    %         yt = ax.YTick;
    %         ax.YTick = yt + 0.5;
    %         ax.XAxis.TickLength = [0 0];
    %         ax.YAxis.TickLength = [0 0]; 
    %         title(strrep(strain_names{strain_n}, '_', '-'))
    %      end 
    % 
    %      f = gcf;
    %      % f.Position = [2612  -522  373  1588]; %[564    73   362   974];
    %      f.Position = [2578  161  238  905]; % 4 conditions only
    % 
    %      if multi % Generate separate figure of the colour bar - p values.
    %         % plot_colour_bar_for_summary_plot()
    %      end 
    % 
    % elseif zscore == 0 && compare_to_ES == 0 
    %     % plot heatmap of the absolute values
    %     % normalised by metric across all strains - white = lowest, black =
    %     % highest. 
    % 
    %     % 1 - normalise each column.
    % 
    %     xmin = min(target_all);           % Minimum of each column
    %     xmax = max(target_all);           % Maximum of each column
    % 
    %     % Standard normalisation: (X - xmin) ./ (xmax - xmin) gives 0→min, 1→max
    %     X_norm = (target_all - xmin) ./ (xmax - xmin);
    % 
    %     % Invert so min→1 and max→0
    %     target_all_norm = 1 - X_norm;
    % 
    %     %% Plot the heatmap divided up by STRAIN 
    %     n_strains = numel(strain_names);
    %     f = tiledlayout(n_strains, 1);
    %     f.Padding = "tight";
    %     multi = 1;
    % 
    %     h_all = height(pvals_all_cond);
    % 
    %     for strain_n = 1:n_strains
    % 
    %         nexttile
    % 
    %         % Extract the interleaved values
    %         rng = strain_n:n_strains:h_all;
    % 
    %         % Extract just the data for this strain
    %         t_all = target_all_norm(rng, :);
    % 
    %         if strain_n <n_strains
    %             plot_x = 0;
    %         else
    %             plot_x = 1;
    %         end 
    % 
    %         % Plot the data: 
    %         plot_val_heatmap_strains(t_all, plot_x, multi)
    % 
    %         % Format the plot.
    %         grid on
    %         ax = gca;
    %         xt = ax.XTick;
    %         ax.XTick = xt + 0.5; 
    %         yt = ax.YTick;
    %         ax.YTick = yt + 0.5;
    %         ax.XAxis.TickLength = [0 0];
    %         ax.YAxis.TickLength = [0 0]; 
    %         title(strrep(strain_names{strain_n}, '_', '-'))
    %      end 
    % 
    %      f = gcf;
    %      % f.Position = [2612  -522  373  1588]; %[564    73   362   974];
    %      f.Position = [2578         103         246         963]; % 4 cond, with ES
    %      % f.Position = [2578  161  238  905]; % 4 conditions only
    % 
    % end 

end 