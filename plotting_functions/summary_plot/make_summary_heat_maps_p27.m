function DATA = make_summary_heat_maps_p27()

    ROOT_DIR = 'C:\Users\burnettl\Documents\oakey-cokey'; 
    
    % Move to the directory to where the results per experiment are saved:
    protocol_dir = fullfile(ROOT_DIR, 'results', 'protocol_27');
    cd(protocol_dir);

    DATA = comb_data_across_cohorts_cond(protocol_dir);

    pvals_all_cond = [];
    target_all = [];
    control_all = [];

    for condition_n = 1:12

        %% Make summary heat map
        [pvals_cond, target_mean_all, control_mean_all, strain_names] = make_pvalue_heatmap_across_strains(DATA, condition_n);
    
        pvals_all_cond = vertcat(pvals_all_cond, pvals_cond);
        target_all = vertcat(target_all, target_mean_all);
        control_all = vertcat(control_all, control_mean_all);
        % plot_pval_heatmap(pvals_all, target_mean_all, control_mean_all, strain_names, condition_n);

    end 

    %% Perform FDR adjustment to p-values.
    [h_01, crit_p_all, adj_p_all]=fdr_bh(pvals_all_cond, 0.001, 'dep', 'yes');
    % adj_p_all is of the size [n_strains*n_conditions, n_metrics]

    %% Plot the heat maps for each condition with the adjusted p values.

        % cond_titles = {"60deg-gratings-4Hz"...
        % , "60deg-gratings-8Hz"...
        % , "narrow-ON-bars-4Hz"...
        % , "narrow-OFF-bars-4Hz"...
        % , "ON-curtains-8Hz"...
        % , "OFF-curtains-8Hz"...
        % , "reverse-phi-2Hz"...
        % , "reverse-phi-4Hz"...
        % , "60deg-flicker-4Hz"...
        % , "60deg-gratings-static"...
        % , "60deg-gratings-0-8-offset"...
        % , "32px-ON-single-bar"...
        % };

        % f = tiledlayout(12, 1);
        % f.Padding = "tight";
        % 
        % for condition_n = 1:12
        %     % close
        %     % condition_n = condition_n+1;
        %     nexttile
        % 
        %     range_start = (condition_n - 1) * 11 + 1;
        %     range_end = condition_n * 11;
        % 
        %     adj_p = adj_p_all(range_start:range_end, :);
        %     t_all = target_all(range_start:range_end, :);
        %     c_all = control_all(range_start:range_end, :);
        % 
        %     plot_pval_heatmap(adj_p, t_all, c_all, strain_names, condition_n);
        %     title(cond_titles{condition_n})
        % end 


    %% Plot the heatmap divided up by STRAIN 

        n_strains = numel(strain_names);
        f = tiledlayout(n_strains, 1);
        f.Padding = "tight";
        multi = 1;

        h_all = height(pvals_all_cond);

       for strain_n = 1:n_strains
    
            nexttile

            rng = strain_n:n_strains:h_all;
    
            adj_p = adj_p_all(rng, :);
            t_all = target_all(rng, :);
            c_all = control_all(rng, :);
    
            if strain_n <n_strains
                plot_x = 0;
            else
                plot_x = 1;
            end 

            plot_pval_heatmap_strains(adj_p, t_all, c_all, plot_x, multi)

            grid on
            ax = gca;
            xt = ax.XTick;
            ax.XTick = xt + 0.5; 
            yt = ax.YTick;
            ax.YTick = yt + 0.5;

            ax.XAxis.TickLength = [0 0];
            ax.YAxis.TickLength = [0 0]; 

            title(strrep(strain_names{strain_n}, '_', '-'))
        end 

        f = gcf;
        f.Position = [2612  -522  373  1588]; %[564    73   362   974];

        if multi % Generate separate figure of the colour bar - p values.

            figure;
            c_array(1, : , :) = [...
            1 0 0; ...
            1 0.2 0.2; ...
            1 0.4 0.4; ...
            1 0.6 0.6; ...
            1 0.8 0.8; ...
            1 1 1; ...
            0.8 0.8 1; ...
            0.6 0.6 1; ...
            0.4 0.4 1; ...
            0.2 0.2 1; ...
            0 0 1;...
            ];

            imagesc(flip(c_array)); % Flip to go from blue to red
            hold on
            text(1,1,'<= 0.00001', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight','bold')
            text(2,1,'< 0.0001', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight','bold')
            text(3,1,'< 0.001', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight','bold')
            text(4,1,'< 0.01', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight','bold')
            text(5,1,'< 0.05', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight','bold')
            text(6,1,'NS', 'HorizontalAlignment', 'center', 'Color', 'k', 'FontWeight','bold')
            text(7,1,'< 0.05', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight','bold')
            text(8,1,'< 0.01', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight','bold')
            text(9,1,'< 0.001', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight','bold')
            text(10,1,'< 0.0001', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight','bold')
            text(11,1,'<= 0.00001', 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight','bold')
 
            ax = gca; ax.LineWidth = 1.4;
            xticks([])
            yticks([])
            f = gcf;
            f.Position = [495 916 1021 51]; %[1229  317  94    730];


        end 





end 