
%% Make plots for MIC paper - time series

%% 1 - make DATA

ROOT_DIR = '/Users/burnettl/Documents/Projects/oaky_cokey';
% Move to the directory to where the results per experiment are saved:
protocol_dir = fullfile(ROOT_DIR, 'results', 'protocol_27');
cd(protocol_dir);

% Get all of the strain folders that are inside the protocol folder.
strain_folders = dir;
strain_folders = strain_folders([strain_folders.isdir]); % Keep only directories
strain_folders = strain_folders(~ismember({strain_folders.name}, {'.', '..'})); % Remove '.' and '..'

% Check for empty split folder - remove if it exists.
if ~ismember({strain_folders.name}, {'jfrc100_es_shibire_kir'})
    disp("No data for empty split flies")
else 
    strain_folders = strain_folders(~ismember({strain_folders.name}, {'jfrc100_es_shibire_kir'})); 
end 

% Number of strains without ES.
n_strains = height(strain_folders);

% Check and change DCH VCH name. 
folderMatch = any(contains({strain_folders.name}, "ss1209_DCH-VCH_shibire_kir"));
if folderMatch
    index = find(contains({strain_folders.name}, "ss1209_DCH-VCH_shibire_kir"));
    strain_folders(index).name = strrep(strain_folders(index).name, "ss1209_DCH-VCH_shibire_kir", "ss1209_DCH_VCH_shibire_kir");
end 

% Generate the struct 'DATA' that combines data across experiments and
% separates data into conditions.
DATA = comb_data_across_cohorts_cond(protocol_dir);

% Save a text file with the number of flies and vials for each strain
% that has been run so far: 
exp_data = generate_exp_data_struct(DATA);
% Print and save text file
% export_num_flies_summary(exp_data, save_folder)

generate_fly_n_bar_charts(exp_data, save_folder)

% % Store figures in folders of the day that they were created too. Can go
% % back and look at previous versions. 
% date_str = string(datetime('now','TimeZone','local','Format','yyyy_MM_dd'));
% 
% % If saving the figures - create a folder to save them in:
% save_folder = fullfile(ROOT_DIR, "figures", protocol, date_str);
% if ~isfolder(save_folder)
%     mkdir(save_folder);
% end

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

% Blues
% col_12 = [31 120 180; ... %50 50 50; ...% 166 206 227; 106 61 154; ...
%     31 120 180; ...
%     178 223 138; ...
%     47 141 41; ...
%     251 154 153; ...
%     227 26 28; ...
%     253 191 111; ...
%     255 127 0; ...
%     166 206 227; ...%202 178 214; ...
%     200 200 200; ... % 106 61 154; ...166 206 227;
%     255 224 41; ...
%     187 75 12; ...
%     ]./255;

% Blue colours used: 
% 4 Hz  -  31 120 180;
% Flicker - 166 206 227;
% Static - 200 200 200;

%% 2 - Time series plot - just ES flies 

figure_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/FIGS';

strain = "jfrc100_es_shibire_kir";
% strain = "ss324_t4t5_shibire_kir";
% strain = "ss00297_Dm4_shibire_kir";

% fps = 30; 
% sex = "F";
% data = DATA.(strain).(sex);
cond_n = 1; 
plot_sem = 1;
data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta',};

% Convert names - dashes to underscore.
for i = 1:numel(strain_folders)
    if isfield(strain_folders(i), 'name') && ischar(strain_folders(i).name) || isstring(strain_folders(i).name)
        strain_folders(i).name = strrep(strain_folders(i).name, '-', '_');
    end
end

% PLOT 
strain_names = strain;
% cond_ids = [10, 1];
% cond_ids = [3, 4, 1];
cond_ids = [1,7];
% data_type = "dist_data_delta";
data_type = "av_data";
protocol = "protocol_27";
params.save_figs = 0;
params.plot_sem = 1;
params.plot_sd = 0;
params.plot_individ = 0;
params.shaded_areas = 0;

figure;
plot_xcond_per_strain2(protocol, data_type, cond_ids, strain_names, params, DATA)
f = gcf;
f.Position = [181   611   641   340];

if params.plot_sem == 1
    sd_str = "SEM";
elseif params.plot_sd == 1
    sd_str = "SD";
end 

savefig(fullfile(figure_folder, strcat('TimeSeries_p27_Cond10-9-1_ES_', sd_str,'_', data_type,'.fig')));


%% Plot JUST 4Hz responses with shaded areas showing the time over which metrics were calculated. 
figure_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/FIGS/ES_timeseries_with_shaded_metric_areas';

strain_names = strain;
cond_ids = 1; %[10, 9, 1];
data_type = "curv_data";
protocol = "protocol_27";
params.save_figs = 0;
params.plot_sem = 0;
params.plot_sd = 0;
params.plot_individ = 0;
params.shaded_areas = 1;

figure;
plot_xcond_per_strain2(protocol, data_type, cond_ids, strain_names, params, DATA)
f = gcf;
f.Position = [181   611   641   340];

if params.plot_sem == 1
    sd_str = "SEM";
elseif params.plot_sd == 1
    sd_str = "SD";
end 

savefig(fullfile(figure_folder, strcat('TimeSeries_p27_Cond10-9-1_ES_', sd_str,'_', data_type,'.fig')));





%% 3 - Box and whisker plots. 

% delta == 1 - - difference from stimulus start
% delta == 2 - - difference from stimulus end

% cond_ids = [1, 10, 9]; % 4 Hz, 0Hz, Flicker.
cond_ids = [1,7];

%% DIST1
% 270:300 (1s around start)
% 1170:1200 (1s around end)

data_type = "dist_data";
% rng = 270:300;
rng = 1170:1200;
delta = 0;

plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta)

%% DIST2 
% 570:600 (1s min - dist moved from start to 10s in)
% 1170:1200 

data_type = "dist_data";
% rng = 570:600;
rng = 1170:1200;
delta = 1;

figure;
plot([0.5 4.5], [0 0], 'k')
hold on
plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta)

%%  DIST3
% 1470:1500 (difference from end of stim to 10s after stim ends)

data_type = "dist_data";
rng = 1470:1500;
delta = 2;

figure;
plot([0.5 3.5], [0 0], 'k')
hold on
plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta)
xlim([0.5 3.5])

%% FV
% 300:1200
% 210:300 - 300:390 (3s +/-)

data_type = "fv_data";
rng = 300:1200;
delta = 0;

figure;
plot([0.5 3.5], [0 0], 'k')
hold on
plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta)
xlim([0.5 3.5])


%% AV 
% 300:1200
% 315:450 (first 5s)

data_type = "av_data";
rng = 300:1200;
delta = 0;

figure;
% plot([0.5 4.5], [0 0], 'k')
% hold on
plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta)
% xlim([0.5 4.5])


%% Spatial occupancy maps

strain = "jfrc100_es_shibire_kir";
fps = 30; 
sex = "F";
data = DATA.(strain).(sex);


for entryIdx = 16:25
    protocol = "protocol_27";
    plot_fly_occupancy_heatmaps(data, protocol, entryIdx, [], []);
    f = gcf;
    f.Position = [103   726   766   238];
end 

% - ALL COHORTS
hFig = plot_fly_occupancy_heatmaps_all(data);
hFig.Position = [27  622  1774  425];


%% Trajectories. 

cond_ids = [10, 9, 1];

% [807, 802, 791, 314, 24, 776, 786, 804, 746, 215, 743, 701, 705, 727, 239]
% [24, 692, 646, 639, 631, 245, 637, 625, 581, 583, 87, 547]
for f = [543, 557, 544, 523, 370, 312, 396, 212, 816, 818, 166]
    plot_traj_xcond(DATA, strain, cond_ids, f)
end 

cond_idx = 7; %10 
% fly_ids = [557, 543, 637]; %557
fly_ids = [807, 802, 791];

plot_traj_xflies(DATA, strain, cond_idx, fly_ids)
legend off

%% Plot time series data - across strains for one conditions
% Rainbow plots 

    % {'ss2575_LPC1_shibire_kir'   } 1
    % {'csw1118'                   } 2
    % {'jfrc100_es_shibire_kir'    } 3
    % {'l1l4_jfrc100_shibire_kir'  } 4
    % {'ss00297_Dm4_shibire_kir'   } 5
    % {'ss00316_Mi4_shibire_kir'   } 6
    % {'ss00326_Pm2ab_shibire_kir' } 7 
    % {'ss00395_TmY3_shibire_kir'  } 8
    % {'ss01027_H2_shibire_kir'    } 9
    % {'ss02594_TmY5a_shibire_kir' } 10
    % {'ss03722_Tm5Y_shibire_kir'  } 11
    % {'ss1209_DCH_VCH_shibire_kir'} 12
    % {'ss2344_T4_shibire_kir'     } 13
    % {'ss2571_T5_shibire_kir'     } 14
    % {'ss2603_TmY20_shibire_kir'  } 15
    % {'ss26283_H1_shibire_kir'    } 16
    % {'ss324_t4t5_shibire_kir'    } 17 
    % {'ss34318_Am1_shibire_kir'   } 18


close
% strains_to_plot= 1:17; % Which strains to plot the data for:
% strains_to_plot = [1:5, 17];
% strains_to_plot = [6,8,9,10,11,7,17]; %[6:11, 17];
% strains_to_plot = [12:16, 17];
% strains_to_plot = [18, 17];
strains_to_plot = [3, 7, 17]; % T4t5, Dm4, ES


cond_ids = 3; % Which condition number to plot the data for.
% data_type = "dist_data_delta";
data_type = "av_data";
protocol = "protocol_27";
params.save_figs = 0;
params.plot_sem = 1;
params.plot_sd = 0;
params.plot_individ = 0;
params.shaded_areas = 0;

figure;
plot_xstrain_per_cond(protocol, data_type, cond_ids, strains_to_plot, params, DATA)
f = gcf;
f.Position = [181   611   641   340];


%% Make rainbow dot plot to show which colour corresponds to which strain.

figure; 
scatter(1:18, ones(1, 18), 200, strain_colours, 'filled')
axis off


%% Boxplots - X-strain - per cond. 

strain_ids = [3,7,17]; %1:17;
cond_idx = 3;

% Distance metrics
data_type = "dist_data";
rng = 1170:1200;
delta = 1;

figure;
plot([0.5 17.5], [0 0], 'k')
hold on
plot_boxchart_metrics_xstrains(DATA, strain_ids, cond_idx, data_type, rng, delta)
f = gcf;
% f.Position = [138   605   607   241];
% 3 strains
f.Position = [138   605   197   241];


% Angular velocity
data_type = "av_data";
rng = 300:1200;
delta = 0;

figure;
plot([0.5 17.5], [0 0], 'k')
hold on
plot_boxchart_metrics_xstrains(DATA, strain_ids, cond_idx, data_type, rng, delta)
f = gcf;
f.Position = [138   605   607   241];


% Turning rate 
data_type = "curv_data";
rng = 300:1200;
delta = 0;

figure;
plot([0.5 17.5], [0 0], 'k')
hold on
plot_boxchart_metrics_xstrains(DATA, strain_ids, cond_idx, data_type, rng, delta)
f = gcf;
f.Position = [138   605   607   241];

 % ylim([-40 320])

% Forward velocity
data_type = "fv_data";
rng = 300:1200;
delta = 0;

figure;
plot([0.5 17.5], [0 0], 'k')
hold on
plot_boxchart_metrics_xstrains(DATA, strain_ids, cond_idx, data_type, rng, delta)
f = gcf;
f.Position = [138   605   607   241];
