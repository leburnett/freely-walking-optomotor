% process the oaky-cokey freely-walking optomotor behaviour data 

close all
clear
clc

%% What date to analyse:

date_to_analyse = '2024_09_24';

%% Initialise fixed paths.

PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey/';
data_path = fullfile(PROJECT_ROOT, 'data');
results_path = fullfile(PROJECT_ROOT, 'results');

path_to_folder = fullfile(data_path, date_to_analyse);

save_folder = results_path; 

% Add saving to subfolders later when processing data in folder structure. 
% genotype = 'CSw1118';
% save_folder = fullfile(results_path, genotype);

%% Process the data and save the processed data:
process_data_features(path_to_folder, save_folder)
