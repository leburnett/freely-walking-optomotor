function process_freely_walking_data(date_to_analyse, generate_stim_videos)
% PROCESS_FREELY_WALKING_DATA Process data from freely-walking optomotor experiments
%
%   PROCESS_FREELY_WALKING_DATA(date_to_analyse) processes all experiments
%   within the specified date folder. Automatically discovers protocols,
%   strains, and sexes within the folder hierarchy.
%
%   PROCESS_FREELY_WALKING_DATA(date_to_analyse, generate_stim_videos) optionally
%   generates stimulus overlay videos for each condition.
%
% INPUTS:
%   date_to_analyse     - String of date folder to analyze (format: "YYYY_MM_DD")
%   generate_stim_videos - Boolean to generate condition videos (default: false)
%
% OUTPUTS:
%   Processed data saved to results folder as "*_data.mat" files
%   Overview figures saved to figures/overview_figs/
%
% FOLDER STRUCTURE EXPECTED:
%   DATA/01_tracked/{date}/{protocol}/{strain}/{sex}/{time}/
%
% WORKFLOW:
%   1. Iterates through all protocol folders in the date directory
%   2. For each protocol, iterates through strain folders
%   3. For each strain, iterates through sex folders (F/M)
%   4. Calls process_data_features for each experiment
%
% EXAMPLE:
%   process_freely_walking_data("2024_09_24")
%   process_freely_walking_data("2024_09_24", true)  % with video generation
%
% See also: process_data_features, combine_data_one_cohort, comb_data_across_cohorts_cond

    if nargin < 2 || isempty(generate_stim_videos)
        generate_stim_videos = false;
    end

    close all
   
    %% If data recorded after 24/09/2024 - - - new logging / saving system that saves in subfolders. 

    PROJECT_ROOT = '\Users\burnettl\Documents\oakey-cokey\'; %% Update for your computer. 
    data_path = fullfile(PROJECT_ROOT, 'DATA\01_tracked');
    % data_path = fullfile(PROJECT_ROOT, 'DATA\02_processed');
    results_path = fullfile(PROJECT_ROOT, 'results');

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
            cd(fullfile(strain_folders(strain_idx).folder, strain_folders(strain_idx).name))

            sex_folders = dir();
            % make sure only appropriate folders are considered.
            sex_folders = sex_folders(3:end, :);
            sex_names = {sex_folders.name};
            sex_folders = sex_folders(~strcmp(sex_names, '.DS_Store'));
            n_sexes = length(sex_folders);

            for sex_idx = 1:n_sexes
                sex_to_analyse = sex_folders(sex_idx).name;
                cd(fullfile(sex_folders(sex_idx).folder, sex_folders(sex_idx).name))

                path_to_folder = fullfile(data_path, date_to_analyse, protocol_to_analyse, genotype_to_analyse, sex_to_analyse);
                save_folder = fullfile(results_path, protocol_to_analyse, genotype_to_analyse, sex_to_analyse);

                % Process the data and save the processed data:
                process_data_features(PROJECT_ROOT, path_to_folder, save_folder, date_to_analyse, generate_stim_videos)

            end
        end 

        % Display the number of flies / number of vials for this protocol
        % disp(protocol_to_analyse)
        % % Save txt file with the number of vials.
        % protocol_dir = fullfile(results_path, protocol_to_analyse);
        % DATA = comb_data_across_cohorts_cond(protocol_dir);
        % exp_data = generate_exp_data_struct(DATA);
        % export_num_flies_summary(exp_data, protocol_dir);

    end
    
    disp(strcat("Finished processing ", date_to_analyse))
end 
