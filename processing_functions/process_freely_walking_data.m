function process_freely_walking_data(date_to_analyse)
% process the oaky-cokey freely-walking optomotor behaviour data 

    close all
    clear
    clc
   

    %% If data recorded after 24/09/2024 - - - new logging / saving system that saves in subfolders. 
    
    PROJECT_ROOT = '\Users\burnettl\Documents\oakey-cokey\'; %% Update for your computer. 
    data_path = fullfile(PROJECT_ROOT, 'DATA\01_tracked');
    results_path = fullfile(PROJECT_ROOT, 'results');

    date_folder = fullfile(data_path, date_to_analyse);
    
    cd(date_folder)
    
    protocol_folders = dir('*rotocol_*');
    n_protocols = height(protocol_folders);
    
    for proto_idx = n_protocols
    
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
                process_data_features(path_to_folder, save_folder, date_to_analyse)

            end
        end 
    end 
end 
