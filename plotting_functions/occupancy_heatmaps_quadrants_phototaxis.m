
% Use DATA: "2025_10_30_DATA_phototaxis_with_angles.mat"

entryIdx = 14;

close 

figure; 
tiledlayout(1,7,"TileSpacing","compact")
for i = 1:7
    nexttile
    if i < 7 
        if i == 1
            frameRange = 1:300; % before stimulus
        elseif i == 2
            frameRange = 300:600; % 20s of stimulus
        elseif i == 3
            frameRange = 300:900; % 20s of stimulus
        elseif i == 4
            frameRange = 300:1200; % 30s of stimulus
        elseif i == 5
            frameRange = 300:1650; % full 45s of stimulus
        elseif i == 6
            frameRange = 1650:2000; % after stimulus
        end 
        plot_fly_occupancy_quadrants_phototaxis(DATA, entryIdx, frameRange)
        if i == 1
            ax = gca;
           cb = colorbar(ax); cb.Label.String = 'Occupancy (fraction)'; cb.FontSize = 12; cb.Ticks = [0, 0.1, 0.2, 0.3, 0.4]; cb.Location = 'southoutside';
        end 
    else
        plot_fly_occupancy_quadrants_diff_phototaxis(DATA, entryIdx)
        ax = gca;
        cb = colorbar(ax);
        cb.Label.String = 'Δ occupancy (fraction, later − early)';
        cb.Location = 'southoutside';
        cb.FontSize = 12;
    end 

end 

f = gcf;
f.Position = [1  720  1796  327];
sgtitle(sprintf('Cohort - %d', entryIdx), 'FontSize', 20)




%% Average across all cohorts

entryIdxVec = 1:30;

entryIdxVec([5,18,17,20,22,24,25]) = [];
plot_fly_occupancy_quadrants_diff_avg_phototaxis( ...
        DATA, entryIdxVec, 'Epoch1',[1 300], 'Epoch2',[300 1200], ...
        'Condition','condition_12');




