%% Different speeds - p31 - plots


%% 1 - make DATA

ROOT_DIR = '/Users/burnettl/Documents/Projects/oaky_cokey';
% Move to the directory to where the results per experiment are saved:
protocol_dir = fullfile(ROOT_DIR, 'results', 'protocol_31');
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

%% 1 - DATA 

% Generate the struct 'DATA' that combines data across experiments and
% separates data into conditions.
DATA = comb_data_across_cohorts_cond(protocol_dir);

cond_titles = {"60deg-gratings-1Hz"... % 60 dps
            , "60deg-gratings-2Hz"... % 120 dps
            , "60deg-gratings-4Hz"... % 240 dps
            , "60deg-gratings-8Hz"... % 480 dps
            , "60deg-flicker-4Hz"...
            , "15deg-gratings-4Hz"... % 60 dps
            , "15deg-gratings-8Hz"... % 120 dps
            , "15deg-gratings-16Hz"... % 240 dps
            , "15deg-gratings-32Hz"... % 480 dps
            , "15deg-flicker-4Hz"...
            };

%% 2 - plot time series of flies to conditions 1,2,3,4,5 - all 60 deg stimuli 

% strain = "ss324_t4t5_shibire_kir";
strain = "jfrc100_es_shibire_kir";
% strain = "csw1118";

% 60 deg plot:
cond_ids = 3; %[1,2,3,4]; % 60 deg gratings

% 15 deg plot:
% cond_ids = 8; % [6,7,8,9]; % 15 deg


fps = 30; 
sex = "F";
data = DATA.(strain).(sex);
plot_sem = 1;

% Convert names - dashes to underscore.
% for i = 1:numel(strain_folders)
%     if isfield(strain_folders(i), 'name') && ischar(strain_folders(i).name) || isstring(strain_folders(i).name)
%         strain_folders(i).name = strrep(strain_folders(i).name, '-', '_');
%     end
% end

% PLOT 
% strain_names = strain;
% data_type = "curv_data";
data_type = "dist_data_delta";
protocol = "protocol_31";
params.save_figs = 0;
params.plot_sem = 0;
params.plot_sd = 0;
params.plot_individ = 0;
params.shaded_areas = 0;

figure;
plot_xcond_per_strain2(protocol, data_type, cond_ids, strain, params, DATA)
f = gcf;
f.Position = [181   611   641   340];

% Control
col15 = [0.8, 0.8, 0.8];
col60 = [0.4, 0.4, 0.4];

% T4T5
col15 = [1, 0.8, 0]; % yellow
col60 = [1 0.5, 0]; %orange



%% 3 - Box and whisker plots. 

% delta == 1 - - difference from stimulus start
% delta == 2 - - difference from stimulus end

%% DIST1
% 270:300 (1s around start)
% 1170:1200 (1s around end)

data_type = "dist_data";
% rng = 270:300;
rng = 1170:1200;
delta = 1;

figure
plot([0.5 4.5], [0 0], 'k')
hold on
plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta)


%% AV 
% 300:1200
% 315:450 (first 5s)

data_type = "av_data";
rng = 300:1200;
delta = 0;

figure;
plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta)
xlim([0.5 4.5])

