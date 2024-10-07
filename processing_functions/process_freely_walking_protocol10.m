% function process_freely_walking_protocol10(date_to_analyse)

% process_freely_walking_protocol_10

% This script will make mean datapoints, process data_features, and
% process_freely walking data for each condition of the long protocol

close all
clear
clc

%% process_freely_walking_data_v10

%% enter correct date folder based on parameter
PROJECT_ROOT = 'C:\Users\deva\Documents\projects\oakey_cokey\';
data_path = fullfile(PROJECT_ROOT, 'data');
results_path = fullfile(PROJECT_ROOT, 'results');
date_to_analyse = '2024_10_03';

date_folder = fullfile(data_path, date_to_analyse);

cd(date_folder);

protocol_folders = dir('*rotocol_*'); % gets all the protocol folders in this date
n_protocols = height(protocol_folders);

% if block to analyze just the protocol_10 differently

% display(protocol_folders);

% for loop for all of the protocols within one date folder
for proto_idx = 1:n_protocols
    protocol_to_analyse = protocol_folders(proto_idx).name;
    cd (fullfile(protocol_folders(proto_idx).folder, protocol_folders(proto_idx).name))

    % enter strain folder
    strain_folders = dir();
    strain_folders = strain_folders(3:end, :);
    strain_names = {strain_folders.name};
    strain_folders = strain_folders(~strcmp(strain_names, '.DS_Store'));
    n_strains = length(strain_folders);

    for strain_idx = 1:n_strains
            genotype_to_analyse =  strain_folders(strain_idx).name;
            
            path_to_folder = fullfile(data_path, date_to_analyse, protocol_to_analyse, genotype_to_analyse);
            save_folder = fullfile(results_path, protocol_to_analyse, genotype_to_analyse);
            
            % Process the data and save the processed data:
            if (protocol_folders.name == 'Protocol_v10_all_tests')
                display('entered if');
                process_data_features_v10(path_to_folder, save_folder, date_to_analyse);
            else
                process_data_features(path_to_folder, save_folder, date_to_analyse)
            end

        end 
    
end

% if (protocol_folders.name == 'Protocol_v10_all_tests')
%     display('entered if');
%     % conduct analysis on each condition separately
%     protocol_to_a
% 
% end
% 
% display ('outside if');
