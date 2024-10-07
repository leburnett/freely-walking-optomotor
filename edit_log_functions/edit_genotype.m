function edit_genotype(date_folder)

% root_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/data/2024_09_27';
% log_files = dir(fullfile(root_folder, '**/LOG_2024*'));

% have to do this for all the folders within a genotype folder actually,
% will not work for just the time points bc will have to do all of them
% individually and we should just do all of them in a loop

root_folder = date_folder;
log_file = dir(fullfile(root_folder, '**/LOG_2024*'));

% open LOG
load(log_file.name); % loads LOG into workspace

to_replace_genotype_name = 'CS_w1118_new'

% update LOG with genotype name

LOG.fly_strain = to_replace_genotype_name;

% display (LOG.fly_strain);

% save LOG
save(log_file.name, 'LOG');
