%%  Protocol 35 analysis:
% Exploratory code for the different varieties of p35 that were run
% recently:

% % [pattern_id, interval_id, speed_patt, speed_int, trial_dur, int_dur, condition_n]
all_conditions = [ 
    9, 47, 127, 1, 20, t_interval, 1; %  60 deg gratings - 4Hz - 1 px step pattern
    6, 47, 64, 1, 20, t_interval, 2; %  30 deg gratings - 4Hz - 1 px step pattern

    7, 47, 8, 1, 20, t_interval, 3;  % 30 deg Flicker - 4Hz
    7, 47, 0, 1, 20, t_interval, 4; % 30 deg static grating
    10, 47, 8, 1, 20, t_interval, 5;  % 60 deg Flicker - 4Hz
    10, 47, 0, 1, 20, t_interval, 6; % 60 deg static grating

    70, 47, 64, 1, 20, t_interval, 7; % 30 deg -- 0.75 offset - 4Hz
    71, 47, 64, 1, 20, t_interval, 8; % 30 deg -- 0.75 offset - 4Hz
    72, 47, 127, 1, 20, t_interval, 9; % 60 deg -- 0.75 offset - 4Hz
    73, 47, 127, 1, 20, t_interval, 10; % 60 deg -- 0.75 offset - 4Hz
];  

%%
fps = 30; 
sex = "F";
strain = "csw1118";
data = DATA.(strain).(sex);

%% Spatial occupancy:

entryIdx = 3;

if entryIdx == 1
    frameRange = 900:1200; %cohort 1
    stim_dur = 15;
    swapf = 750;
    endf = 1200;
else
    frameRange = 1200:1500; %cohort 2
    stim_dur = 20;
    swapf = 900;
    endf = 1500;
end 

plot_fly_occupancy_heatmaps(data, entryIdx, frameRange)
f = gcf;
f.Position = [66   694  1357  305];

%% Timeseries plot:

    figure; tiledlayout(1, 3, 'TileSpacing','compact');
    
    data_type = "av_data";
    
    for condIdx = [1, 9, 10] % [2,7,8] % 
    
        nexttile
    
        if ismember(condIdx, [1,2]) % regular gratings
            col = "k";
        elseif ismember(condIdx, [7,9]) % 0.75
            col = "r";
        elseif ismember(condIdx, [8, 10]) % -0.75
            col = "b";
        end
        
        if data_type == "dist_data"
            ylabel('Distance from the centre (mm)')
            rng = [0 120];
            ylim([20 100])
        elseif data_type == "av_data"
            ylabel('Angular velocity (deg s-1)')
            rng = [-200 200];
        end 

        data2plot = DATA.csw1118.F(entryIdx).(strcat("R1_condition_", string(condIdx)));
        d = data2plot.(data_type);
       
        rectangle('Position',[300 rng(1) stim_dur*fps diff(rng)], 'EdgeColor','none', 'FaceColor', col, 'FaceAlpha', 0.2);
        hold on;
        rectangle('Position',[300+stim_dur*fps rng(1) stim_dur*fps diff(rng)], 'EdgeColor','none', 'FaceColor', col, 'FaceAlpha', 0.1);
        plot(mean(d), 'k', 'LineWidth', 1.75)
        plot([0 size(d, 2)], [60 60], 'Color', [0.7 0.7 0.7]); % middle of arena
        
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


