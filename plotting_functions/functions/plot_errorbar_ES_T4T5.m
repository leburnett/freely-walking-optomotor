function plot_errorbar_ES_T4T5()
% Protocol 10 - tuning curve - T4T5 Kir - ES Kir.

% cond 3 = 60 deg - 4Hz
% cond 2 = 60 deg - 8 Hz
% cond 7 = 30 deg - 4Hz
% cond 6 = 30 deg - 8Hz
% cond 11 = 15 deg - 4Hz
% cond 10 = 15 deg - 8Hz

% Plot "curv_data" - turning rate. 

    gp_data = {
        'jfrc49_es_kir', 'F'; 
        'ss324_t4t5_kir', 'F';
        };
    
    for temp_freq = ["slow", "fast"]
    
        if temp_freq == "fast"
            save_ttl = "T4T5_8Hz";
            cond_to_plot = [10,6,2];
            col = [0.7 0.7 0.7; 0.6 0.8 0.6];
        elseif temp_freq == "slow"
            save_ttl = "T4T5_4Hz";
            cond_to_plot = [11,7,3];
            col = [0.3 0.3 0.3; 0.5 0.6 0.5];
        end 
    
        % Set the groups to plot and the conditions to plot. 
        groups_to_plot = [1,2];
        n_groups = numel(groups_to_plot);
        n_cond = numel(cond_to_plot);
        
        ebar_data = zeros(n_groups, n_cond);
        sem_bar_data = zeros(n_groups, n_cond);
        
        for grpId = 1:n_groups
        
            gp = groups_to_plot(grpId);
            strain = gp_data{gp, 1};
            sex = gp_data{gp, 2}; 
        
            data = DATA.(strain).(sex); 
            n_exp = length(data);
        
            for condId = 1:n_cond
        
                idx2 = cond_to_plot(condId); % condition 
                disp(strcat("Cond - ", string(idx2), " - Group ", string(gp)))
    
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
        
                    % Mean and SEM of the data
                    mean_data = nanmean(cond_data);
                    sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
        
                    n_datapoints = size(mean_data, 2);
                    n_flies_in_cond = size(cond_data, 1);
                    disp(strcat("N flies - ", string(n_flies_in_cond)))
                    window_size = 15;
                    step_size = 5;
                    n_bins = floor((n_datapoints - 1 - window_size) / step_size) + 1;
        
                    % Bin the data 
                    mean_data_dwn = nan(1, n_bins);
                    sem_data_dwn = nan(1, n_bins);
        
                    for b = 1:n_bins
                        start_idx = (b-1) * step_size+1;  % Start of the window
                        end_idx = start_idx + window_size - 1;        % End of the window
                        mean_data_dwn(1, b) = nanmean(mean_data(1, start_idx:end_idx), 2);
                        sem_data_dwn(1, b) = nanmean(sem_data(1, start_idx:end_idx), 2);
                    end 
                    
                    % Frame for the beginning of the interval after condition.
                    fl = int16(mean(fl_start_f))+10;
        
                    mean_stim = nanmean(abs(mean_data(300/step_size:fl/step_size)));
                    sem_stim = nanmean(abs(sem_data(300/step_size:fl/step_size)));
        
                    % Mean and SEM across groups and conditions
                    ebar_data(grpId, condId) = mean_stim;
                    sem_bar_data(grpId, condId) = sem_stim;
                end 
            end 
        end 
        
        
        % figure
    
        errorbar(1:n_cond, ebar_data(1, :), sem_bar_data(1, :), 'Color', col(1, :), 'LineWidth', 1.2)
        hold on
        scatter(1:n_cond, ebar_data(1, :), 120, col(1, :), 'Marker', 'o', 'LineWidth', 2)
        errorbar(1:n_cond, ebar_data(2, :), sem_bar_data(2, :), 'Color', col(2, :), 'LineWidth', 1.2)
        scatter(1:n_cond, ebar_data(2, :), 120, col(2, :), 'Marker', 'o', 'LineWidth', 2)
        
        ylim([-3 25])
        xlim([0.5 3.5])
        box off
        ax = gca; 
        ax.XTick = [1,2,3];
        ax.XTickLabel = {'15', '30', '60'};
        ax.TickDir = 'out'; 
        ax.TickLength = [0.015 0.015]; 
        ax.LineWidth = 1; 
        ax.FontSize = 16;
            
        ylabel("Turning rate (deg mm^-^1)")
        xlabel("Spatial freq. (deg)")
        f = gcf;
        f.Position = [620   650   236   317];
        
        fig_save_folder = "/Users/burnettl/Documents/Projects/oaky_cokey/figures/examples/p10_T4T5_ES_Kir";
        fname = fullfile(fig_save_folder, strcat("Errorbar_", save_ttl, ".png"));
        exportgraphics(f, fname); 
        
        fname_pdf = fullfile(fig_save_folder, strcat("Errorbar_", save_ttl, ".pdf"));
        exportgraphics(f, fname_pdf ...
                        , 'ContentType', 'vector' ...
                        , 'BackgroundColor', 'none' ...
                        ); 
    end 
    
end 

















