% Protocol 10 - tuning curve - T4T5 Kir - ES Kir.


% cond 3 = 60 deg - 4Hz
% cond 2 = 60 deg - 8 Hz
% cond 7 = 30 deg - 4Hz
% cond 6 = 30 deg - 8Hz
% cond 11 = 15 deg - 4Hz
% cond 10 = 15 deg - 8Hz

% Plot "curv_data" - turning rate. 
% Timeseries  / errorbar plot (tuning).

gp_data_fast = {'jfrc49_es_kir', 'F', [0.7 0.7 0.7]; 
    'ss324_t4t5_kir', 'F', [0.6 0.8 0.6];
    };

gp_data_slow = {'jfrc49_es_kir', 'F', [0.3 0.3 0.3]; 
    'ss324_t4t5_kir', 'F', [0.3 0.4 0.3];
    };

rng = [-50 50];
ttl = "T4T5 - 8Hz";
save_ttl = "T4T5_Hz";

figure
for gp = [2]

    strain = gp_data_slow{gp, 1};
    sex = gp_data_slow{gp, 2}; 

    data = DATA.(strain).(sex); 

    n_exp = length(data);

    for idx2 = [2,6,10] % condition 

        if ismember(idx2, [3,7,11])
            col = gp_data_slow{gp, 3};
        else
            col = gp_data_fast{gp, 3};
        end

        rep1_str = strcat('R1_condition_', string(idx2));   
        rep2_str = strcat('R2_condition_', string(idx2));  

        if isfield(data, rep1_str)

             cond_data = [];
             nf_comb = size(cond_data, 2);
             fl_start_f = [];

             for idx = 1:n_exp
                rep1_data = data(idx).(rep1_str);
        
                if ~isempty(rep1_data) % check that the row is not empty.
    
                    rep1_data_fv = rep1_data.fv_data;
                    rep2_data_fv = data(idx).(rep2_str).fv_data;
                    rep1_data_dcent = rep1_data.dist_data;
                    rep2_data_dcent = data(idx).(rep2_str).dist_data;
    
                    % Extract the relevant data
                    rep1_data = rep1_data.(data_type);
                    rep2_data = data(idx).(rep2_str).(data_type);
        
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
        
                    if idx == 1 || nf_comb == 0
                            [rep_data, rep_data_fv] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent);
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
    
                        [rep_data, rep_data_fv] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent);
                        cond_data = vertcat(cond_data, rep_data);
                    end
    
                    fl_start = data(idx).(rep1_str).start_flicker_f;
                    fl_start_f = [fl_start_f, fl_start];
      
                end 
             end 

            mean_data = nanmean(cond_data);
            n_datapoints = size(mean_data, 2);
            % mean_data = movmean(mean_data, 15);
            % mean_data(2:end-1) = conv(mean_data,smooth_kernel,'valid');
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

            % mean_data_dwn = downsample(mean_data, dwn_factor);
    
            % sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
            % sem_data_dwn = downsample(sem_data, 10);

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
            fl = int16(mean(fl_start_f))+10;

            plot([fl/step_size fl/step_size], rng, 'k', 'LineWidth', 0.5)
            plot([300/step_size 300/step_size], rng, 'k', 'LineWidth', 0.5) % beginning of stim
            plot([760/step_size 760/step_size], rng, 'Color', 'k', 'LineWidth', 0.3) % change of direction   
            
            plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
            xlim([0 nf_comb])
            ylim(rng)

            box off
            ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; ax.TickLength = [0.015 0.015]; ax.LineWidth = 1; ax.FontSize = 12;
        end 

    end 
end 

title(ttl)
ylabel("Turning rate (deg mm^-^1)")
f = gcf;
f.Position = [620   701   550   266];


fig_save_folder = "/Users/burnettl/Documents/Projects/oaky_cokey/figures/examples/p10_T4T5_ES_Kir";
fname = fullfile(fig_save_folder, strcat("Timeseries_", save_ttl, ".png"));
exportgraphics(f, fname); 

fname_pdf = fullfile(fig_save_folder, strcat("Timeseries_", save_ttl, ".pdf"));
exportgraphics(f, fname_pdf ...
                , 'ContentType', 'vector' ...
                , 'BackgroundColor', 'none' ...
                ); 


















