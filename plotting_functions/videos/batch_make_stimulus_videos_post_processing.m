function batch_make_stimulus_videos_post_processing(date_to_analyse) 
%% Batch make the stimulus videos after having run "process_freely_walking_data"
% Runs through all of the experiments per day. 
% Uses the "trx" that is saved in the results file and not within the
% experiment folder, since this is the updated version of "trx" that has
% been cleaned for jumps etc. 

    close all 

    PROJECT_ROOT = '\Users\burnettl\Documents\oakey-cokey\'; %% Update for your computer. 
    data_path = fullfile(PROJECT_ROOT, 'DATA\02_processed');
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
                cd(path_to_folder)

                time_folders = dir('*_*');
                % Remove '.DS_Store' file if it exists.
                time_names = {time_folders.name};
                time_folders = time_folders(~strcmp(time_names, '.DS_Store'));
                n_time_exps = length(time_folders);
                
                for exp  = 1:n_time_exps

                    % Move into the experiment directory 
                    cd(fullfile(time_folders(exp).folder, time_folders(exp).name))

                    disp(strcat("Making the stimulus videos for ", time_folders(exp).name))
                    generate_circ_stim_ufmf(1, results_path)

                    % Move back into date folder
                    cd("../")
                end 
            end
        end 

    end
    
    disp(strcat("Finished making the stimulus videos for ", date_to_analyse))
end 
