function plot_timeseries_dist_to_centres(DATA, entryIdx, stim_dur, delta)

figure; tiledlayout(1, 3, 'TileSpacing','compact');

offset1 = [113.397, 212.914];
offset2 = [141.61, 31.8534];
fps = 30;

for condIdx = [1, 9, 10] % 60 deg grating stimuli. 

    nexttile

    if ismember(condIdx, 1) % regular gratings
        col = "k";
    elseif ismember(condIdx, 9) % 0.75
        col = "r";
    elseif ismember(condIdx, 10) % -0.75
        col = "b";
    end

    data2plot_r1 = DATA.csw1118.F(entryIdx).(strcat("R1_condition_", string(condIdx)));
    data2plot_r2 = DATA.csw1118.F(entryIdx).(strcat("R1_condition_", string(condIdx)));

    dist_data = vertcat(data2plot_r1.dist_data, data2plot_r2.dist_data);
    x_data = vertcat(data2plot_r1.x_data, data2plot_r2.x_data);
    y_data = vertcat(data2plot_r1.y_data, data2plot_r2.y_data);

    if delta == 1
        % Distance from the centre (pre-calculated)
        d = dist_data - dist_data(:, 300);
    
        % Calculate the distance from offset1 
        dist1 = distanceFromCoord(x_data, y_data, offset1);
        dist1 = dist1 - dist1(:, 300);

        dist2 = distanceFromCoord(x_data, y_data, offset2);
        dist2 = dist2 - dist2(:, 300);

        rng = [-120 30];

        ylb = "Relative distance (mm)";
    else
        % Distance from the centre (pre-calculated)
        d = dist_data;
    
        % Calculate the distance from offset1 
        dist1 = distanceFromCoord(x_data, y_data, offset1);
        dist2 = distanceFromCoord(x_data, y_data, offset2);

        rng = [0 150];

        ylb = "Absolute distance (mm)";
    end 

    ylim(rng)
    ylabel(ylb)
   
    % Plot when the stimulus is on:
    rectangle('Position',[300 rng(1) stim_dur*fps diff(rng)], 'EdgeColor','none', 'FaceColor', col, 'FaceAlpha', 0.2);
    hold on;
    rectangle('Position',[300+stim_dur*fps rng(1) stim_dur*fps diff(rng)], 'EdgeColor','none', 'FaceColor', col, 'FaceAlpha', 0.1);

    % Plot the distance data

    if ismember(condIdx, 1) % regular gratings
        plot(nanmean(d), 'k', 'LineWidth', 1.75)
        % plot(nanmean(dist1), 'Color', [1 0.7 0.7], 'LineWidth', 1.75)
        % plot(nanmean(dist2), 'Color', [0.7 0.7 1], 'LineWidth', 1.75)
        title("Centre of arena")
        if delta ~= 1
            ylim([0 120])
        end
    elseif ismember(condIdx, 9) % 0.75
        % plot(nanmean(d), 'Color', [0.7 0.7 0.7], 'LineWidth', 1.75)
        % if delta ~= 1
        %     plot(nanmean(dist1), 'Color', [0.7 0.7 1], 'LineWidth', 1.75)
        % end 
        plot(nanmean(dist2), 'Color', [1 0 0], 'LineWidth', 1.75)
        title("CoR1") 
    elseif ismember(condIdx, 10) % -0.75
        % plot(nanmean(d), 'Color', [0.7 0.7 0.7], 'LineWidth', 1.75)
        plot(nanmean(dist1), 'Color', [0 0 1], 'LineWidth', 1.75)
        % if delta ~= 1
        %     plot(nanmean(dist2), 'Color', [1 0.7 0.7], 'LineWidth', 1.75)
        % end 
        title("CoR2")
    end

    if delta == 1
        % Plot a reference line for the centre of the arena:
        plot([0 size(d, 2)], [0 0], 'Color', [0.7 0.7 0.7]); % middle of arena
    else
        % Plot a reference line for the centre of the arena:
        plot([0 size(d, 2)], [60 60], 'Color', [0.7 0.7 0.7]); % middle of arena
    end 
    
    xlim([0 size(d, 2)])
    box off
    ax = gca;
    ax.TickDir = "out";
    ax.FontSize = 14;
    ax.LineWidth = 1.2;
    ax.XAxis.Visible = "off";

end 

f = gcf;
f.Position = [34  736  1313  271];


end 




