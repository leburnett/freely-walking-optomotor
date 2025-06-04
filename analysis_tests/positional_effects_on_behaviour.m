% Analyse how the physical location of the fly within the arena -
% specifically its distance from the centre/ edge - affects it's turning /
% centring behaviour. 


%% Histograms for values within different frame ranges - no flies removed. 

strain = "ss00297_Dm4_shibire_kir";

condition_n = 1;

% Extract 'data' from the relevant strain / condition.
sex = 'F';
data = DATA.(strain).(sex);

control_strain = "jfrc100_es_shibire_kir";
data_control = DATA.(control_strain).(sex);

data_types = {'IFD_data', 'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta', 'straightness'};
n_data_types = numel(data_types);

control_col = [0.2 0.2 0.2];
target_col = [0.8 0.4 0.8];

for typ_id = 1% :n_data_types

    data_type = data_types{typ_id};

    cond_data_control = combine_timeseries_across_exp(data_control, condition_n, data_type);
    cond_data = combine_timeseries_across_exp(data, condition_n, data_type);

    figure; 

    tiledlayout(5, 1, 'TileSpacing', 'tight')
    nexttile
    % Before stimulus
    frame_rng = 1:300;
    plot_histogram_from_cond_data(cond_data_control, frame_rng, data_type, control_col);
    hold on;
    plot_histogram_from_cond_data(cond_data, frame_rng, data_type, target_col);
    title('10s before stimulus')

    nexttile
    % Entire stimulus
    frame_rng = 300:1200;
    plot_histogram_from_cond_data(cond_data_control, frame_rng, data_type, control_col);
    hold on;
    plot_histogram_from_cond_data(cond_data, frame_rng, data_type, target_col);
    title('During stimulus (30s)')

    nexttile
    % First 5s of stimulus
    frame_rng = 300:450;
    plot_histogram_from_cond_data(cond_data_control, frame_rng, data_type, control_col);
    hold on;
    plot_histogram_from_cond_data(cond_data, frame_rng, data_type, target_col);
    title('First 5s of stimulus')

    nexttile
    % Last 5s of stimulus
    frame_rng = 1000:1150;
    plot_histogram_from_cond_data(cond_data_control, frame_rng, data_type, control_col);
    hold on;
    plot_histogram_from_cond_data(cond_data, frame_rng, data_type, target_col);
    title('Last 5s of stimulus')

    nexttile
    % First 10s of interval
    frame_rng = 1200:1500;
    plot_histogram_from_cond_data(cond_data_control, frame_rng, data_type, control_col);
    hold on;
    plot_histogram_from_cond_data(cond_data, frame_rng, data_type, target_col);
    title('First 10s of interval')

    f = gcf;
    f.Position = [464    75   245   972];
    sgtitle(strrep(data_type, '_', '-'))

end 



%% Scatter plots
% For p27 - screen protocol.
% Only control flies
% Plot scatter plots of the fly's distance from the centre of the arena
% versus the centripetal distance moved by the fly during 5s periods. 

% Stimulus on from 300:1200
condition_n = 1;

bin_size = 150; % 5s
bin_edges = 150:bin_size:1350; % From 5s before the stimulust starts til 5s after the stimulus ends. 
n_bins = length(bin_edges)-1;

for b = 1:n_bins
   
    frame_rng = bin_edges(b):bin_edges(b+1);

    control_strain = "ss00297_Dm4_shibire_kir"; %"jfrc100_es_shibire_kir";
    data_control = DATA.(control_strain).(sex);
    
    data_type = "dist_data"; 
    cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_dist = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
    binned_vals_dist = binned_vals_dist(:);
    
    data_type = "dist_data_delta"; 
    binned_vals_delta = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
    binned_vals_delta = binned_vals_delta(:);

    % Use forward velocity for colour of markers. 
    data_type = "fv_data"; 
    cond_data_control3 = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_fv = bin_data_from_cond_data(cond_data_control3, frame_rng, data_type, bin_size);
    binned_vals_fv = binned_vals_fv(:);
    c_array = (binned_vals_fv - min(binned_vals_fv)) / (max(binned_vals_fv) - min(binned_vals_fv));
    c = 1 - [c_array, c_array, c_array];

    figure; 
    plot([0 120], [0 0], 'Color', [1 0.6 0.6], 'LineWidth', 2); 
    hold on;
    scatter(binned_vals_dist, binned_vals_delta, 50, c, 'filled', 'MarkerEdgeColor', [0.2 0.2 0.2]); 
    title(sprintf('Dist %d-%d', bin_edges(b), bin_edges(b+1)));
    ylim([-100 100])
    f = gcf; 
    f.Position = [683   507   531   526];

end 

%% Scatter plots - angular velocity / turning rate
% For p27 - screen protocol.
% Only control flies
% Plot scatter plots of the fly's distance from the centre of the arena
% versus the centripetal distance moved by the fly during 5s periods. 

% Stimulus on from 300:1200
condition_n = 1;

bin_size = 150; % 5s
bin_edges = 150:bin_size:1350;
n_bins = length(bin_edges)-1;

% control_strain = "jfrc100_es_shibire_kir";
control_strain = "ss00297_Dm4_shibire_kir";
data_control = DATA.(control_strain).(sex);

for b = 1:n_bins
   
    frame_rng = bin_edges(b):bin_edges(b+1);

    data_type = "dist_data"; 
    cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_dist = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
    binned_vals_dist = binned_vals_dist(:);
    
    data_type = "curv_data"; 
    cond_data_control_curv = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_curv = bin_data_from_cond_data(cond_data_control_curv, frame_rng, data_type, bin_size);
    binned_vals_curv = binned_vals_curv(:);

    % Use forward velocity for colour of markers. 
    data_type = "fv_data"; 
    cond_data_control3 = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_fv = bin_data_from_cond_data(cond_data_control3, frame_rng, data_type, bin_size);
    binned_vals_fv = binned_vals_fv(:);
    c_array = (binned_vals_fv - min(binned_vals_fv)) / (max(binned_vals_fv) - min(binned_vals_fv));
    % c = 1 - [zeros(size(c_array)), c_array, c_array];
    c = 1 - [c_array, c_array, c_array];

            % % Plot timeseries of binned values with a given bin size:
            % figure; plot(mean(binned_vals_delta))
            % ylabel('Distance moved towards centre (mm)')
            % xticks('')
            % title(strcat("Bin size: ", string(bin_size/30), "s"))
            % f = gcf;
            % f.Position = [171   535   920   405];
   
    figure; 
    plot([0 120], [0 0], 'Color', [1 0.8 0.8]); 
    hold on;
    scatter(binned_vals_dist, binned_vals_curv, 50, c, 'filled', 'MarkerEdgeColor', [0.2 0.2 0.2]); 
    % scatter(binned_vals_dist, binned_vals_curv, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2]); 
    title(sprintf('Dist %d-%d', bin_edges(b), bin_edges(b+1)));
    ylim([-450 450])
    ylabel('Turning rate (deg mm^-^1)')
    % ylabel('Angular velocity (deg s^-^1)')
    xlabel('Distance from the centre of the arena (mm)')
    % yscale log
    f = gcf; 
    f.Position = [683   507   531   526];

end 


%% Over the entire stimulus:


% Stimulus on from 300:1200
condition_n = 1;

bin_size = 150; % 5s

n_bins = length(bin_edges)-1;

frame_rng = 300:1200;

control_strain = "jfrc100_es_shibire_kir";
data_control = DATA.(control_strain).(sex);

data_type = "dist_data"; 
cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
binned_vals_dist = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
binned_vals_dist = binned_vals_dist(:);

data_type = "dist_data_delta"; 
binned_vals_delta = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
binned_vals_delta = binned_vals_delta(:);

figure; 
plot([0 120], [0 0], 'Color', [1 0.8 0.8]); 
hold on;
scatter(binned_vals_dist, binned_vals_delta, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2]); 
ylim([-100 100])
f = gcf; 
f.Position = [683   507   531   526];




%% QUESTION - can flies that are turning at a high turning rate also be walking forward at a high rate?

frame_rng = 300:1200; % Just look at the beginning of the stimulus
control_strain = "jfrc100_es_shibire_kir";
data_control = DATA.(control_strain).(sex);

data_type = "fv_data"; 
cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
binned_vals1 = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
binned_vals1 = binned_vals1(:);

data_type = "curv_data"; 
cond_data_control2 = combine_timeseries_across_exp(data_control, condition_n, data_type);
binned_vals2 = bin_data_from_cond_data(cond_data_control2, frame_rng, data_type, bin_size);
binned_vals2 = binned_vals2(:);

figure; 
plot([0 30], [0 0], 'Color', [1 0.6 0.6], 'LineWidth', 2); 
hold on
plot([0 30], [90 90], 'Color', [1 0.6 0.6], 'LineWidth', 1); 
plot([0 30], [-90 -90], 'Color', [1 0.6 0.6], 'LineWidth', 1); 
scatter(binned_vals1, binned_vals2, 30, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2])
xlabel('Forward velocity (mm s^-^1)')
ylabel('Turning rate (deg mm^-^1)')
box off
ax = gca;
ax.TickDir = 'out';
ax.LineWidth = 1.2;
ax.FontSize = 12;
title(strcat("Frame range: ", string(frame_rng(1)), ":", string(frame_rng(end))))


%%







figure; scatterhist(binned_vals_dist, binned_vals_delta)
%%

% Plot histograms of amount moved towards centre based on location in the
% arena. 

% 8 different distance bins (120/8 = 15mm)
dist_bins = 0:20:120;
bin_idx = discretize(binned_vals_dist, dist_bins);

figure;
for i = 1:length(dist_bins)-1

    % subplot(6,1,i)

    % Get the values in binned_vals_delta corresponding to the current bin
    delta_in_bin = binned_vals_delta(bin_idx == i);

    % Plot histogram in a subplot
    histogram(delta_in_bin,'Normalization', 'probability', 'BinWidth', 1);
    hold on;
    plot([mean(delta_in_bin), mean(delta_in_bin)], [0 0.25], 'r')
    
    % Label the plot
    title(sprintf('Dist %d-%d', dist_bins(i), dist_bins(i+1)));
    xlabel('Delta');
    ylabel('Count');
    xlim([-30 75])
end



