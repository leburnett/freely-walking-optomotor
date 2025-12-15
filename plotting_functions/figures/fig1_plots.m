
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


strain = {"jfrc100_es_shibire_kir"};
fps = 30; 
sex = "F";
data = DATA.(strain).(sex);
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
cond_ids = [10, 9, 1];
data_type = "fv_data";
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
cond_ids = [10, 9, 1];
data_type = "dist_data";
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





%% 3 - Box and whisker plots. 

% delta == 1 - - difference from stimulus start
% delta == 2 - - difference from stimulus end

cond_ids = [1, 10, 9]; % 4 Hz, 0Hz, Flicker.

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
plot([0.5 3.5], [0 0], 'k')
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

data_type = "curv_data";
rng = 300:1200;
delta = 0;

figure;
plot([0.5 3.5], [0 0], 'k')
hold on
plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta)
xlim([0.5 3.5])
