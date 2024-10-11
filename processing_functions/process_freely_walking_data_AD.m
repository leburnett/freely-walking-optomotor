function process_freely_walking_data_AD(date_to_analyse)
% process the oaky-cokey freely-walking optomotor behaviour data 

    % close all
    % clear
    % clc
    % 
    %% If data recorded after 24/09/2024 - - - new logging / saving system that saves in subfolders. 
    PROJECT_ROOT = 'C:\Users\deva\Documents\projects\oakey_cokey\'; %% Update for your computer. 
    data_path = fullfile(PROJECT_ROOT, 'data');
    results_path = fullfile(PROJECT_ROOT, 'results');
    
    % date_to_analyse = '2024_09_27';
    
    date_folder = fullfile(data_path, date_to_analyse);
    
    cd(date_folder)
    
    protocol_folders = dir('*rotocol_*');
    n_protocols = height(protocol_folders);
    
    for proto_idx = 1:n_protocols
    
        protocol_to_analyse = protocol_folders(proto_idx).name;
        cd(fullfile(protocol_folders(proto_idx).folder, protocol_folders(proto_idx).name))
    
        strain_folders = dir();
        % make sure only appropriate folders are considered.
        strain_folders = strain_folders(3:end, :);
        strain_names = {strain_folders.name};
        strain_folders = strain_folders(~strcmp(strain_names, '.DS_Store'));
        n_strains = length(strain_folders);
    
        for strain_idx = 1:n_strains
            genotype_to_analyse =  strain_folders(strain_idx).name;
            
            path_to_folder = fullfile(data_path, date_to_analyse, protocol_to_analyse, genotype_to_analyse);
            save_folder = fullfile(results_path, protocol_to_analyse, genotype_to_analyse);
            
            % Process the data and save the processed data:
            process_data_features(path_to_folder, save_folder, date_to_analyse)
        end 
    
    end 

end 
%% If data recorded on or before 24/09/2024 - - - all experiments saved in one date folder. 

% What date to analyse:

% date_to_analyse = '2024_07_16';
% 
% % Initialise fixed paths.
% 
% PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey/';
% data_path = fullfile(PROJECT_ROOT, 'data');
% results_path = fullfile(PROJECT_ROOT, 'results');
% path_to_folder = fullfile(data_path, date_to_analyse);
% save_folder = results_path; 
% % Process the data and save the processed data:
% process_data_features_pre_240925(path_to_folder, save_folder)
