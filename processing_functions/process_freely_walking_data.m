% process the oaky-cokey freely-walking optomotor behaviour data 

close all
clear
clc

%% If data recorded on or before 24/09/2024 - - - all experiments saved in one date folder. 

% What date to analyse:

date_to_analyse = '2024_09_24';

% Initialise fixed paths.

PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey/';
data_path = fullfile(PROJECT_ROOT, 'data');
results_path = fullfile(PROJECT_ROOT, 'results');
path_to_folder = fullfile(data_path, date_to_analyse);
save_folder = results_path; 
% Process the data and save the processed data:
process_data_features(path_to_folder, save_folder)







%% If data recorded after 24/09/2024 - - - new logging / saving system that saves in subfolders. 

date_to_analyse = '2024_09_25';
protocol_to_analyse = 'protocol_v7';
genotype_to_analyse = 'csw1118';

%% Initialise fixed paths.

PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey/';
data_path = fullfile(PROJECT_ROOT, 'data');
results_path = fullfile(PROJECT_ROOT, 'results');
path_to_folder = fullfile(data_path, date_to_analyse, protocol_to_analyse, genotype_to_analyse);
save_folder = fullfile(results_path, protocol_to_analyse, genotype_to_analyse);

%% Process the data and save the processed data:
process_data_features(path_to_folder, save_folder)

