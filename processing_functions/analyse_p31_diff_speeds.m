% Plot datapoints - different speeds - p31

data_type = "av_data";
strain = "jfrc100_es_shibire_kir";
sex = 'F';
data = DATA.(strain).(sex); 
gain = 1;

col = [0.8, 0.8, 0.8];

n_exp = length(data);

val_stim = zeros(1, 10);
sem_stim = zeros(1, 10);

% Run through the different conditions: 
for cond_n = 1:10

    rep1_str = strcat('R1_condition_', string(cond_n));   
    rep2_str = strcat('R2_condition_', string(cond_n));  

    if isfield(data, rep1_str)

        cond_data = [];
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
            end 
        end 

        % Mean +/- SEM
        mean_data = nanmean(cond_data);

        % GAIN: Angular velocity in dps / speed of stimulus in dps.
        if gain == 1
            if ismember(cond_n, [1,6])
                stim_fps = 60;
            elseif ismember(cond_n, [2, 7])
                stim_fps = 120;
            elseif ismember(cond_n, [3, 8])
                stim_fps = 240;
            elseif ismember(cond_n, [4, 9])
                stim_fps = 480;
            else
                stim_fps = 60;
            end 
            mean_data = mean_data/stim_fps;
        end 
      
        if gain == 1
            sem_data = nanstd(cond_data./stim_fps)/sqrt(size(cond_data,1));
        else
            sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
        end 


         if data_type == "av_data" || data_type == "curv_data" % flip the second half of the stimulus to be +ve. 
             mm = [mean_data(1:761), mean_data(761:end)*-1];
             mean_data = mm;
        end 


        val_stim(1, cond_n) = nanmean(mean_data(300:1200)); % % % % % % % % consider changing this to prctile.. 
 
        sem_stim(1, cond_n) = nanmean(sem_data(300:1200));
    end 
end 

%% % % % % % % % % % % % % % % %
 
% Find mean / sem during acclim period. 

acclim1_comb_data = [];

for idx = 1:n_exp

    acclim1_data = data(idx).acclim_off1;

    % Extract the relevant data
    acclim1_data = acclim1_data.(data_type);
    acclim1_data = acclim1_data(:, 1:8000);
    acclim1_comb_data = vertcat(acclim1_comb_data, acclim1_data);                   
end 
   
if gain == 1 
    mean_acclim1 = nanmean(acclim1_comb_data/stim_fps);
    sem_acclim1 = nanstd(acclim1_comb_data/stim_fps)/sqrt(size(acclim1_comb_data,1));
else
    mean_acclim1 = nanmean(acclim1_comb_data);
    sem_acclim1 = nanstd(acclim1_comb_data)/sqrt(size(acclim1_comb_data,1));
end 

val_acclim1 = nanmean(mean_acclim1);
sem_acclim1 = nanmean(sem_acclim1);

%% Combine acclim and points

vals15 = [val_acclim1, val_stim(6:10)];
sem15 = [sem_acclim1, sem_stim(6:10)];

vals60 = [val_acclim1, val_stim(1:5)];
sem60 = [sem_acclim1, sem_stim(1:5)];


%% Plot the figure;
stim_fps_all = [0, 60, 120, 240, 480, 60];

%% 60 deg
figure; 
b = bar(stim_fps_all,"FaceColor", 'flat',"FaceAlpha", 0.3, "EdgeColor", "none");
b.CData(1, :) =  [0    0.4811    0.9633];
b.CData(2, :) =  [0    0.3470    0.8410];
b.CData(3, :) =  [0    0.3023    0.7669];
b.CData(4, :) =  [0    0.1129    0.6187];
b.CData(5, :) =  [0    0    0.5];
b.CData(6, :) =  [0    0    0.2];
hold on;
scatter(1:6, stim_fps_all, 100, 'k.')

errorbar(vals60, sem60, 'Color', 'k', 'LineStyle', 'none', 'LineWidth', 1.2)
scatter(1:6, vals60, 60, 'o', 'MarkerFaceColor','w', 'MarkerEdgeColor', 'k', 'LineWidth', 1)
title("60 deg")
box off
ax = gca;
ax.TickDir = "out";
ax.FontSize = 14;
ax.LineWidth = 1.2;
xticks([1:6])
xlb = string(stim_fps_all);
xlb(end) = "Fl";
xticklabels(xlb)
xlabel("Stimulus speed (^o s^-^1)")
ylabel("Turning (^o mm^-^1)")
f = gcf;
f.Position = [560   603   346   420];
ylim([-50 520])


%% 15 deg 

figure; 
b = bar(stim_fps_all,"FaceColor", 'flat',"FaceAlpha", 0.3, "EdgeColor", "none");
b.CData(1, :) =  [0    0.4811    0.9633];
b.CData(2, :) =  [0    0.3470    0.8410];
b.CData(3, :) =  [0    0.3023    0.7669];
b.CData(4, :) =  [0    0.1129    0.6187];
b.CData(5, :) =  [0    0    0.5];
b.CData(6, :) =  [0    0    0.2];
hold on;
scatter(1:6, stim_fps_all, 100, 'k.')
errorbar(vals15, sem15, 'Color', 'k', 'LineStyle', 'none', 'LineWidth', 1.2)
hold on
scatter(1:6, vals15, 60, 'o', 'MarkerFaceColor','w', 'MarkerEdgeColor', 'k', 'LineWidth', 1)
title("15 deg")
box off
ax = gca;
ax.TickDir = "out";
ax.FontSize = 14;
ax.LineWidth = 1.2;
xticks([1:6])
xlb = string(stim_fps_all);
xlb(end) = "Fl";
xticklabels(xlb)
xlabel("Stimulus speed (^o s^-^1)")
ylabel("Turning (^o mm^-^1)")
f = gcf;
f.Position = [560   603   346   420];
ylim([-50 520])


%% For gain
figure; 
b = bar(vals60,"FaceColor", 'flat',"FaceAlpha", 0.3, "EdgeColor", "none");
hold on;
b.CData(1, :) =  [0    0.4811    0.9633];
b.CData(2, :) =  [0    0.3470    0.8410];
b.CData(3, :) =  [0    0.3023    0.7669];
b.CData(4, :) =  [0    0.1129    0.6187];
b.CData(5, :) =  [0    0    0.5];
b.CData(6, :) =  [0    0    0.2];
errorbar(vals60, sem60, 'Color', 'k', 'LineStyle', 'none', 'LineWidth', 1.2)
scatter(1:6, vals60, 60, 'o', 'MarkerFaceColor','w', 'MarkerEdgeColor', 'k', 'LineWidth', 1)
title("60 deg")
box off
ax = gca;
ax.TickDir = "out";
ax.FontSize = 14;
ax.LineWidth = 1.2;
xticks([1:6])
xlb = string(stim_fps_all);
xlb(end) = "Fl";
xticklabels(xlb)
xlabel("Stimulus speed (^o s^-^1)")
ylabel("Gain (turning/stimulus speed)")
f = gcf;
f.Position = [560   603   346   420];
ylim([-0.25 0.75])
xlim([0 7])


figure; 
b = bar(vals15,"FaceColor", 'flat',"FaceAlpha", 0.3, "EdgeColor", "none");
hold on;
b.CData(1, :) =  [0    0.4811    0.9633];
b.CData(2, :) =  [0    0.3470    0.8410];
b.CData(3, :) =  [0    0.3023    0.7669];
b.CData(4, :) =  [0    0.1129    0.6187];
b.CData(5, :) =  [0    0    0.5];
b.CData(6, :) =  [0    0    0.2];
errorbar(vals15, sem15, 'Color', 'k', 'LineStyle', 'none', 'LineWidth', 1.2)
scatter(1:6, vals15, 60, 'o', 'MarkerFaceColor','w', 'MarkerEdgeColor', 'k', 'LineWidth', 1)
title("15 deg")
box off
ax = gca;
ax.TickDir = "out";
ax.FontSize = 14;
ax.LineWidth = 1.2;
xticks([1:6])
xlb = string(stim_fps_all);
xlb(end) = "Fl";
xticklabels(xlb)
xlabel("Stimulus speed (^o s^-^1)")
ylabel("Gain (turning/stimulus speed)")
f = gcf;
f.Position = [560   603   346   420];
ylim([-0.25 0.75])
xlim([0 7])