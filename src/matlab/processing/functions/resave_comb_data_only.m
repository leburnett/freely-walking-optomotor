% % Copy whole 'protocol_27' folder in 'exp_results'
% % Name 'protocol_27_new'
% % Find all mat files
% files = 
% % Find n_files
% % LOOP
% % for n_files
%     % Load
%     load(fullfile(files(i).folder, files(i).name))
%     % save
%     save(new_save_path, 'comb_data')
% % end loop

function resave_comb_data_only(base_folder)
    % base_folder = '\\prfs\reiserlab\oaky-cokey\exp_results\protocol_27_only_comb_data';

    % Get all .mat files recursively
    mat_files = dir(fullfile(base_folder, '**', '*.mat'));

    fprintf('Found %d .mat files. Processing...\n', length(mat_files));

    for k = 2:length(mat_files)
        mat_file_path = fullfile(mat_files(k).folder, mat_files(k).name);
        fprintf('Processing file: %s\n', mat_file_path);

        % Load the .mat file
        file_data = load(mat_file_path);

        % Check if comb_data exists
        if isfield(file_data, 'comb_data')
            comb_data = file_data.comb_data;

            % Save only comb_data back to the same file
            save(mat_file_path, 'comb_data');
            fprintf('Resaved: %s\n', mat_file_path);
        else
            warning('comb_data not found in %s. Skipping...', mat_file_path);
        end
    end

    fprintf('All files processed.\n');
end