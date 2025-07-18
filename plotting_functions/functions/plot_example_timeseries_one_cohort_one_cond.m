function plot_example_timeseries_one_cohort_one_cond(DATA, data_type, strain, sex, cond_n, cohort_n, new_fig, save_fig)
% This function can be used to plot a time series plot of the data of
% "data_type" for a single cohort (experimental vial, run of the protocol)
% for a single condition. Currently, this does not include the
% acclimatisation periods. 

% cond 3 = 60 deg - 4Hz
% cond 2 = 60 deg - 8 Hz
% cond 7 = 30 deg - 4Hz
% cond 6 = 30 deg - 8Hz
% cond 11 = 15 deg - 4Hz
% cond 10 = 15 deg - 8Hz

data = DATA.(strain).(sex); 

col = 'k';
   
% % % % % Generate 'cond_data' - combine data across flies.

rep1_str = strcat('R1_condition_', string(cond_n));   
rep2_str = strcat('R2_condition_', string(cond_n));  

cond_data = [];
fl_start_f = [];
    
if isfield(data, rep1_str)

    rep1_data = data(cohort_n).(rep1_str);

    if ~isempty(rep1_data) % check that the row is not empty.

        rep1_data_fv = rep1_data.fv_data;
        rep2_data_fv = data(cohort_n).(rep2_str).fv_data;
        rep1_data_dcent = rep1_data.dist_data;
        rep2_data_dcent = data(cohort_n).(rep2_str).dist_data;

        % Extract the relevant data
        rep1_data = rep1_data.(data_type);
        rep2_data = data(cohort_n).(rep2_str).(data_type);

        % Number of frames in each rep
        nf1 = size(rep1_data, 2);
        nf2 = size(rep2_data, 2);

        if nf1>nf2
            nf = nf2;
        elseif nf2>nf1
            nf = nf1;
        else 
            nf = nf1;
        end 

        % Trim data to same length
        rep1_data = rep1_data(:, 1:nf);
        rep2_data = rep2_data(:, 1:nf);

        rep1_data_fv = rep1_data_fv(:, 1:nf);
        rep2_data_fv = rep2_data_fv(:, 1:nf);

        nf_comb = size(cond_data, 2);

        if cohort_n == 1 || nf_comb == 0
                [rep_data, ~] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent);
                cond_data = vertcat(cond_data, rep_data);
        else
            if nf>nf_comb % trim incoming data
                rep1_data = rep1_data(:, 1:nf_comb);
                rep2_data = rep2_data(:, 1:nf_comb);
            elseif nf_comb>nf % Add NaNs to end
                diff_f = nf_comb-nf+1;
                n_flies = size(rep1_data, 1);
                rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
            end 

            [rep_data, ~] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent);
            cond_data = vertcat(cond_data, rep_data);
        end

        fl_start = data(cohort_n).(rep1_str).start_flicker_f;
        fl_start_f = [fl_start_f, fl_start];

    end 
end 

% % % % % % % % 

fl = int16(mean(fl_start_f))+10; % Find frame for end of stimulus and beginning of interval. 
mean_data = nanmean(cond_data(:, 1:fl+300)); % 10s before and 10s after. 

% % % % % Bin the data
n_datapoints = size(mean_data, 2);
n_flies_in_cond = size(cond_data, 1);
window_size = 15;
step_size = 5;
n_bins = floor((n_datapoints - 1 - window_size) / step_size) + 1;
sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));

mean_data_dwn = nan(1, n_bins);
sem_data_dwn = nan(1, n_bins);

for b = 1:n_bins
    start_idx = (b-1) * step_size+1;  % Start of the window
    end_idx = start_idx + window_size - 1;        % End of the window
    mean_data_dwn(1, b) = nanmean(mean_data(1, start_idx:end_idx), 2);
    sem_data_dwn(1, b) = nanmean(sem_data(1, start_idx:end_idx), 2);
end 

% % % % % % % Plot the data 

if new_fig
    figure
end 

y1 = mean_data_dwn+sem_data_dwn;
y2 = mean_data_dwn-sem_data_dwn;
nf_comb = size(mean_data_dwn, 2);
x = 1:1:nf_comb;
lw = 1;

plot(x, y1, 'w', 'LineWidth', 1)
hold on
plot(x, y2, 'w', 'LineWidth', 1)
patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none')
plot(mean_data_dwn, 'Color', col, 'LineWidth', lw);

if data_type == "dist_data"
    rng = [20 120];
    if delta 
        rng = [-40 20];
    end 
elseif data_type == "fv_data"
    rng = [0 20];
else
    rng = [];
    maxx_y = max(max_y_vals(idx2, :));
    if maxx_y < 0
        rng(2) = maxx_y*1.1;
    elseif maxx_y >=0 
        rng(2) = maxx_y*0.9;
    end
    minn_y = min(min_y_vals(idx2, :));
    if minn_y < 0
        rng(1) = minn_y*1.1;
    elseif minn_y >=0 
        rng(1) = minn_y*0.9;
    end 
end 

plot([(fl/step_size)-5 (fl/step_size)-5], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
plot([(300/step_size)-2.5 (300/step_size)-2.5], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5) % beginning of stim
plot([(760/step_size)-4 (760/step_size)-4], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5) % change of direction   

if data_type == "av_data" || data_type == "curv_data"
    plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
elseif data_type == "dist_data"
    plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
end 

xlim([0 nf_comb])
ylim(rng)

box off
ax = gca; 
ax.XAxis.Visible = 'off'; 
ax.TickDir = 'out'; 
ax.TickLength = [0.015 0.015]; 
ax.LineWidth = 1; 
ax.FontSize = 16;

switch data_type
    case "dist_data"
        if d_fv == 1
            ylb = 'Distance from centre / fv-data - delta (s)';
        elseif delta == 1
            ylb = 'Distance from centre - delta (mm)';
        else
            ylb = 'Distance from centre (mm)';
        end

    case "dist_trav"
        ylb = 'Distance travelled (mm)';

    case "av_data"
        ylb = "Angular velocity (deg s-1)";

    case "heading_data"
        ylb = "Heading (deg)";

    case "vel_data"
        ylb = "Velocity (mm s-1)";

    case "fv_data"
        ylb = "Forward velocity (mm s-1)";

    case "curv_data"
        ylb = "Turning rate (deg mm-1)";

    case "IFD_data"
        ylb = "Distance to nearest fly (mm)";

    otherwise
        error("Unknown data_type: %s", data_type);
end

f = gcf;
ylabel(ylb)
f.Position = [314 714  1083  252];

if save_fig 
    fig_save_folder = "/Users/burnettl/Documents/Projects/oaky_cokey/figures/examples/2025_02_28_mmd_p19_11_37";
    fname = fullfile(fig_save_folder, strcat("Timeseries_", save_ttl, ".png"));
    exportgraphics(f, fname); 
    
    fname_pdf = fullfile(fig_save_folder, strcat("Timeseries_", save_ttl, ".pdf"));
    exportgraphics(f, fname_pdf ...
                    , 'ContentType', 'vector' ...
                    , 'BackgroundColor', 'none' ...
                    ); 
end 

end 

















