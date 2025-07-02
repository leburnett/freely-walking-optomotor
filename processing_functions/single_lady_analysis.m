function single_lady_analysis()

load("/Users/burnettl/Documents/Projects/oaky_cokey/results/DATA_ES_Shibire_Kir_group_vs_solo.mat", 'DATA');

% P 25
cond_titles = {"60deg-gratings-4Hz"...
    , "60deg-gratings-8Hz"...
    , "60deg-flicker-4Hz"...
    };

fig_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/single_ladies_p25';

date_str = string(datetime('today','Format','yy_MM_dd'));
fig_date_folder = fullfile(fig_save_folder, date_str);

if ~isfolder(fig_date_folder)
    mkdir(fig_date_folder);
end

save_fig = 0; 

%% Create time series plots after bootstrapping the "grouped" ES data to have the same number of samples as the single ladies. 
sex = 'F';
cond_idx = 3;

data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta'};

for d = 1:numel(data_types)

    data_type = data_types{d};

    if data_type == "dist_data_delta"
        data_type = "dist_data";
        delta = 1;
    else 
        delta = 0;
    end 

    %% Get "cond_data" - array of size [number of flies x time points]
    strain = 'jfrc100_es_shibire_kir';
    cond_data_grp = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);
    cond_data_grp = cond_data_grp(:, 1:1807);
    
    strain = 'jfrc100_es_shibire_kir_solo';
    cond_data_solo = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);
    cond_data_solo = cond_data_solo(:, 1:1807);

    if delta
        cond_data_grp = cond_data_grp - cond_data_grp(:, 300);
        cond_data_solo = cond_data_solo - cond_data_solo(:, 300);
    end 
    
    %% Extract random samples - bootstrapping
    
    % Parameters
    n_samples = 1000;              % Number of bootstrap samples
    n_flies = size(cond_data_solo, 1);  % Number of flies in solo condition
    T = size(cond_data_solo, 2);   % Number of timepoints
    
    % Preallocate
    boot_means = zeros(n_samples, T);
    
    % Bootstrapping
    for i = 1:n_samples
        idx = randperm(size(cond_data_grp, 1), n_flies);  % Randomly sample 34 flies
        sample = cond_data_grp(idx, :);                   % [34 x T]
        boot_means(i, :) = nanmean(sample, 1);               % Mean across flies
    end
    
    % Compute mean and 95% CI across bootstrapped samples
    group_mean = nanmean(boot_means, 1);                     % [1 x T]
    group_ci = prctile(boot_means, [2.5 97.5], 1);         % [2 x T]
    
    % Solo condition stats
    solo_mean = nanmean(cond_data_solo, 1);                  % [1 x T]
    solo_sem = nanstd(cond_data_solo, 0, 1) / sqrt(n_flies);
    solo_ci = [solo_mean - 1.96 * solo_sem;               % Lower 95% CI
               solo_mean + 1.96 * solo_sem];              % Upper 95% CI  [2 x T]
    
    %% Generate the plot
    t = 1:T;  % or use your actual time vector here
    
    figure;
    hold on;
    
    % Plot group mean with shaded 95% CI
    fill([t, fliplr(t)], [group_ci(1,:), fliplr(group_ci(2,:))], ...
         [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    plot(t, group_mean, 'k', 'LineWidth', 2);
    
    % Plot solo mean with ±1 standard deviation
    fill([t, fliplr(t)], [solo_ci(1,:), fliplr(solo_ci(2,:))], ...
         [0.8 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    plot(t, solo_mean, 'Color', [0 0 0.85], 'LineWidth', 2);
    
    ylb = get_ylb_from_data_type(data_type, delta);
    
    % Labels and legend
    ylabel(ylb);
    
    ax = gca;
    ax.XAxis.Visible = 'off';
    ax.TickDir = 'out';
    ax.LineWidth = 1.2;
    ax.FontSize = 12;
    
    rng = ax.YLim;
    
    % Add vertical lines for the beginning, middle and end of the stimulus. 
    plot([300 300], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
    plot([750 750], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5) 
    plot([1200 1200], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)  
    
    xlim([0 T])
    
    f = gcf;
    f.Position = [284   752   475   260];
    
    title(cond_titles{cond_idx})
    % legend({'Group 95% CI', 'Group Mean', 'Solo 95% CI', 'Solo Mean'});
      
    if save_fig
        if delta 
            data_type = "dist_data_delta";
        end
        fname = fullfile(fig_date_folder, strcat("p25_Boot_", string(n_samples), "_Cond", string(cond_idx),"_", cond_titles{cond_idx},"_", data_type, ".png"));
        exportgraphics(f, fname); 
    end 

end 


end 