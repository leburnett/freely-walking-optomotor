
% Shifted Centre of Rotation analysis - condition 11 - protocol 27.

% Create DATA through the code in "process_screen_data".
DATA2 = DATA.jfrc100_es_shibire_kir.F;
% Extract the data for the flicker (cond 9), normal gratings (cond 1) and shifted gratings (cond 11).
% Saved in "2025_11_03_DATA_CoR_conds_1-11-9_es_shibire_kir.mat"

%% Add columns to DATA about the distance to the centre of the new centre of rotation. 

% The x and y data is in PIXELS in DATA. "dist_data" is the distance to the
% centre of the arena.

% Location of the narrowest part of the shifted CoR gratings in the video
% frame. 
PPM = 4.1691;
W = [606, 37]; % W = narrowest wall point in pixels
C = [528, 516]; % C = arena centre in pixels

t = 0.8;               % the translation you used in the generator (arena radii)
[S, info] = stimulus_center_from_translation(C, W, t, 'Plot', true);
% S is the position of the centre of the shifted stimulus in PIXELS. 

ref_mm = S / PPM; % Find the centre of rotation in mm.

conds = {'R1_condition_11','R2_condition_11', 'R1_condition_1','R2_condition_1', 'R1_condition_9','R2_condition_9'};

for i = 1:numel(DATA)
    for c = 1:numel(conds)
        if isfield(DATA(i), conds{c}) && isstruct(DATA(i).(conds{c}))
            S = DATA(i).(conds{c});
            if isfield(S,'x_data') && isfield(S,'y_data')

                x = S.x_data;   % 15 x 2256 (mm)
                y = S.y_data;   % 15 x 2256 (mm)

                % Euclidean distance in mm to the narrowest part of the
                % gratings.
                d_mm = hypot(x - ref_mm(1), y - ref_mm(2));

                % Store distance of fly from this narrowest part
                DATA(i).(conds{c}).d2CoR = d_mm; 

                % Vector from fly to reference (image coords: +y is down)
                dx = ref_mm(1) - x;
                dy = ref_mm(2) - y;

            end
        end
    end
end


%% Distance to centre versus distance to narrowest part of gratings. 

% 1 - make plot for the "dist_data" for condition 1 (gratings), 11(offset) and 9(flicker). 

for entryIdx = 1 %:30
    
    % metric = "dist_data";
    metric = "d2CoR";
    
    if metric == "dist_data"
        yl = 120;
    elseif metric == "d2CoR"
        yl = 210;
    end 
    
    figure
    subplot(1,4,1)
    condIdx = 1; % Regular gratings
    col = [0 0 0];
    plot_timeseries_metric_both_reps(DATA, metric, condIdx, entryIdx, col, 1)
    ylim([0 yl])
    
    subplot(1,4,2)
    condIdx = 11; % Offset gratings
    col = [0.6 0 0];
    plot_timeseries_metric_both_reps(DATA, metric, condIdx, entryIdx, col, 1)
    ylim([0 yl])
    
    subplot(1,4,3)
    condIdx = 9; % Flicker
    col = [0 0 0.6];
    plot_timeseries_metric_both_reps(DATA, metric, condIdx, entryIdx, col, 1)
    ylim([0 yl])
    
    subplot(1,4,4)
    condIdx = 1; % Regular gratings
    col = [0 0 0];
    plot_timeseries_metric_both_reps(DATA, metric, condIdx, entryIdx, col, 0)
    condIdx = 11; % Offset gratings
    col = [0.6 0 0];
    plot_timeseries_metric_both_reps(DATA, metric, condIdx, entryIdx, col, 0)
    condIdx = 9; % Flicker
    col = [0 0 0.6];
    plot_timeseries_metric_both_reps(DATA, metric, condIdx, entryIdx, col, 0)
    title('Combined')
    ylim([0 yl])
    
    f = gcf; 
    f.Position = [1  730  1800 317];
    sgtitle(sprintf('Cohort %d', entryIdx))

end 


% 2 - make plot for the "d2CoR" for condition 1 (gratings), 11(offset) and 9(flicker). 

% 3 - make plot for the "dist_data" for condition 1 (gratings) and D2CoR for 11(offset) 


%% 2D Spatial Occupancy plots - per cohort.

for entryIdx = [20, 13, 14]
    hFig = plot_fly_occupancy_heatmaps(DATA, entryIdx, [], []);
    hFig.Position = [27  622  1774  425];
    sgtitle(sprintf('Cohort %d', entryIdx))
end 

%% Plot with data from ALL FLIES

hFig = plot_fly_occupancy_heatmaps_all(DATA);
hFig.Position = [27  622  1774  425];




%% Use fv_data (not vel_data) to filter the flies that are included in the analysis.

