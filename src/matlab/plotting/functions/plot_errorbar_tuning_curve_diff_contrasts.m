function f = plot_errorbar_tuning_curve_diff_contrasts(DATA, strain, col, data_type)

    if data_type == "dist_data_delta"
        data_type = "dist_data";
        delta = 1;
        d_fv = 0 ;
    elseif data_type == "dist_data_fv"
        data_type = "dist_data";
        delta = 1;
        d_fv = 1;
    else 
        delta = 0;
        d_fv = 0;
    end 

    % Generate new figure
    % figure;

    % % Eventually have this as the input to the function 
    sex = 'F';
    landing = 'none';
    data = DATA.(strain).(landing).(sex); 
    n_exp = length(data);

    val_stim = zeros(1, 7);
    sem_stim = zeros(1, 7);

    % Run through the different conditions: 
    for cond_n = 1:7

        rep1_str = strcat('R1_condition_', string(cond_n));   
        rep2_str = strcat('R2_condition_', string(cond_n));  

        if isfield(data, rep1_str)

            cond_data = [];
            if d_fv 
                cond_data_fv = [];
            end 
            nf_comb = size(cond_data, 2);
    
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
    
                        if d_fv
                            cond_data_fv = vertcat(cond_data_fv, rep_data_fv);
                        end 
                    else
                        if nf>nf_comb % trim incoming data
                            rep1_data = rep1_data(:, 1:nf_comb);
                            rep2_data = rep2_data(:, 1:nf_comb);
    
                            if d_fv
                                rep1_data_fv = rep1_data_fv(:, 1:nf_comb);
                                rep2_data_fv = rep2_data_fv(:, 1:nf_comb);
                            end 
    
                        elseif nf_comb>nf % Add NaNs to end
    
                            diff_f = nf_comb-nf+1;
                            n_flies = size(rep1_data, 1);
                            rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                            rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                            if d_fv 
                                rep1_data_fv(:, nf:nf_comb) = NaN(n_flies, diff_f);
                                rep2_data_fv(:, nf:nf_comb) = NaN(n_flies, diff_f);
                            end 
                        end 
    
                        [rep_data, rep_data_fv] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent);
                        cond_data = vertcat(cond_data, rep_data);
    
                            if d_fv
                                cond_data_fv = vertcat(cond_data_fv, rep_data_fv);
                            end 
                    end
                end 
            end 
    
            % Mean +/- SEM
            mean_data = nanmean(cond_data);
            if delta == 1
                mean_data = mean_data - mean_data(300);
                if d_fv
                    mean_data_fv = nanmean(cond_data_fv);
                    mean_data = mean_data./mean_data_fv;
                end 
            end 
    
            % smooth data if velocity / distance travelled. 
            if data_type == "dist_trav" || data_type == "vel_data" 
                mean_data = movmean(mean_data, 5);
            end 
    
            sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
    
            if data_type == "dist_data"
                buffer_t = 30*7;
            else
                buffer_t = 1;
            end 
    
             if data_type == "av_data" || data_type == "curv_data" % flip the second half of the stimulus to be +ve. 
                 mm = [mean_data(1:761), mean_data(761:end)*-1];
                 mean_data = mm;
            end 
    
            % Add values to be plotted as errorbar to "val_stim" and
            % "sem_stim".
            if data_type == "dist_data"
                val_stim(1, cond_n) = min(mean_data(300:1200));
            else
                val_stim(1, cond_n) = nanmean(mean_data(300:1200)); % % % % % % % % consider changing this to prctile.. 
            end 
            sem_stim(1, cond_n) = nanmean(sem_data(300:1200));
        end 
    end % end of 7 cond. 

%% % % % % % % % % % % % % % % %
 
% Find mean / sem during acclim period. 

acclim1_comb_data = [];
acclim2_comb_data = [];

for idx = 1:n_exp

    acclim1_data = data(idx).acclim_off1;
    acclim2_data = data(idx).acclim_off2;

    % Extract the relevant data
    acclim1_data = acclim1_data.(data_type);
    acclim1_data = acclim1_data(:, 1:8000);

    acclim2_data = acclim2_data.(data_type);
    acclim2_data = acclim2_data(:, 1:900);
     
    acclim1_comb_data = vertcat(acclim1_comb_data, acclim1_data);
    acclim2_comb_data = vertcat(acclim2_comb_data, acclim2_data);
                   
end 
   
mean_acclim1 = nanmean(acclim1_comb_data);
mean_acclim2 = nanmean(acclim2_comb_data);

sem_acclim1 = nanstd(acclim1_comb_data)/sqrt(size(acclim1_comb_data,1));
sem_acclim2 = nanstd(acclim2_comb_data)/sqrt(size(acclim2_comb_data,1));

if delta == 1
    val_acclim1 = 0;
    val_acclim2 = 0;
elseif data_type == "dist_data"
    val_acclim1 = min(mean_acclim1);
    val_acclim2 = min(mean_acclim2);
else
    val_acclim1 = nanmean(mean_acclim1);
    val_acclim2 = nanmean(mean_acclim2);
end 

sem_acclim1 = nanmean(sem_acclim1);
sem_acclim2 = nanmean(sem_acclim2);

val_stim_all = [val_acclim1, val_stim, val_acclim2];
sem_stim_all = [sem_acclim1, sem_stim, sem_acclim2];

% Plot the figure;

errorbar(val_stim_all, sem_stim_all, 'Color', col, 'LineWidth', 1.5)
hold on
scatter(1:9, val_stim_all, 'o', 'MarkerFaceColor','w', 'MarkerEdgeColor', col, 'LineWidth', 1)
xlim([0 10])

if data_type == "dist_data" && delta == 0
    plot([0 10], [60 60], 'k:', 'LineWidth', 0.5)
elseif data_type == "av_data" || data_type == "curv_data" || delta ==1
    plot([0 10], [0 0], 'k:', 'LineWidth', 0.5)
end 

if data_type == "dist_data"
    if d_fv == 1
        ylb = 'Distance from centre / fv-data - delta (s)';
    elseif delta == 1
        ylb = 'Distance from centre - delta (mm)';
    else
        ylb = 'Distance from centre (mm)';
    end 
elseif data_type == "dist_trav"
    ylb = 'Distance travelled (mm)';
elseif data_type == "av_data"
    % rng = [-110 110];
    ylb = "Angular velocity (deg s-1)";
elseif data_type == "heading_data"
    ylb = "Heading (deg)";
elseif data_type == "vel_data"
    ylb = "Velocity (mm s-1)";
elseif data_type == "fv_data"
    ylb = "Forward velocity (mm s-1)";
elseif data_type == "curv_data"
    ylb = "Turning rate (deg mm-1)";
elseif data_type == "IFD_data"
    ylb = "Distance to nearest fly (mm)";
end

f = gcf;
f.Position = [125   521   556   343];

box off
ax = gca; 
ax.TickDir = 'out';
ax.TickLength = [0.02 0.02]; 
ax.LineWidth = 1; 
ax.FontSize = 12;

xticks(1:10)
xticklabels({'0', '0.11', '0.20', '0.33', '0.4', '0.56', '0.75', '0.98', '0'})
xlabel('Contrast')
sgtitle(strcat(strrep(strain, '_', '-'), " - ", ylb), 'FontSize', 16)

end 

