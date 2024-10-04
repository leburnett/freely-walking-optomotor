function edit_genotype(time_folder)

% root_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/data/2024_09_27';
% log_files = dir(fullfile(root_folder, '**/LOG_2024*'));

root_folder = time_folder;
log_file = dir(full_file(root_folder, '**/LOG_2024*'));

% open date folder

% for i = 1:n_files
%     % open LOG
%     load(fullfile(log_files(i).folder, log_files(i).name), 'LOG')
%     % update LOG
% 
%     % save LOG
% end