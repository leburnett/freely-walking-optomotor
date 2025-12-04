
%% Centring rate 

strain_names = fieldnames(DATA);

cond_ids = 1:12;
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

 % Colourmap:
col_12 = [166 206 227; ...
        31 120 180; ...
        178 223 138; ...
        47 141 41; ...
        251 154 153; ...
        227 26 28; ...
        253 191 111; ...
        255 127 0; ...
        202 178 214; ...
        106 61 154; ...
        255 224 41; ...
        187 75 12; ...
        ]./255;

sex = 'F';

data_type = "dist_data";

strain_id = 1;
strain = strain_names{strain_id};

data = DATA.(strain).(sex);


% 
% for strain_id = 1:numel(strain_names)
% 
%     strain = strain_names{strain_id};
% 
%     figure
%     tiledlayout(numel(cond_ids), 1, 'TileSpacing','tight', 'Padding', 'compact');
% 
%     for c = 1:numel(cond_ids)
% 
%         nexttile
%         condition_n = cond_ids(c);
%         col = col_12(c, :);
% 
%         data = DATA.(strain).(sex);
%         cond_data = combine_timeseries_across_exp(data, condition_n, data_type);
%         if delta
%             cond_data = cond_data - cond_data(:, 300); % relative
%         end 
%         mean_data = nanmean(cond_data);
%         sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
% 
%         y1 = mean_data+sem_data;
%         y2 = mean_data-sem_data;
%         nf_comb = size(mean_data, 2);
%         x = 1:1:nf_comb;
% 
%         plot(x, y1, 'w', 'LineWidth', 1)
%         hold on
%         plot(x, y2, 'w', 'LineWidth', 1)
%         patch([x fliplr(x)], [y1 fliplr(y2)], col, 'FaceAlpha', 0.1, 'EdgeColor', 'none')
%         plot(mean_data, 'Color', col, 'LineWidth', 2);
% 
%         box off
%         ax = gca;
%         ax.TickDir = 'out';
%         ax.LineWidth = 1.2;
%         ax.FontSize = 12;
%         ax.XAxis.Visible = 'off';
% 
%         % Add vertical lines for start, middle and end of stim.
%         plot([300 300], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
%         if c ~= numel(cond_ids)
%             plot([750 750], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
%             plot([1200 1200], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)  
%         end 
% 
%         ylim(rng)
%         xlim([0 1800])
%     end 
% 
%     ylb = get_ylb_from_data_type(data_type, delta);
%     sgtitle(strrep(strcat(strain, " : ", ylb), '_', '-'))
% 
%     f = gcf;
%     f.Position = [557 1 541  1046];
% 
%     if save_figs == 1
%         % Save the figure. 
%         f_str = strcat("XCond_timeseries_tiled_", strain, "_", data_type, ".png");
%         fname = fullfile(save_folder, f_str);
%         exportgraphics(f, fname); 
%         close
%     end 
% end 


condition_n = 1;
cond_data = combine_timeseries_across_exp(data, condition_n, data_type);
cond_data3 = movmean(cond_data', 5)'; 
cond_data2 = (diff(cond_data3')')*-30;

figure; 
hold on;
plot([0 1800], [0 0], 'Color', [0.7 0.7 0.7])
plot([300 300], [-5 3], 'Color', [0.7 0.7 0.7])
plot([750 750], [-5 3], 'Color', [0.7 0.7 0.7])
plot([1200 1200], [-5 3], 'Color', [0.7 0.7 0.7])
plot(mean(cond_data2), 'k', 'LineWidth', 1.2);
xlabel('Time (s)')
ylabel('Centring rate (mm/s)')

f = gcf;
f.Position = [111   491   907   423];
ax = gca;
ax.TickDir = "out";
ax.TickLength = [0.01 0.01];
ax.LineWidth = 1.2;
ax.FontSize = 15;
xticks([0, 300, 600, 900, 1200, 1500])
xticklabels({'0', '10', '20', '30', '40', '50'})



% figure; scatter(mean(cond_data(:,300:1200)), mean(cond_data2(:,300:1200)), 'ko')
% xlabel("Distance from centre (mm)")
% ylabel("Centring rate (mm/frame)")
% title("300:1200 - - movmean15 for dist-data - - cond12")
% hold on
% plot([45 80], [0 0], 'k')
% 
% set(gcf, 'Position', [163   477  1006  448])









