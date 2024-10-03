function make_plots_per_strain(data_folder)
% Generate pdf with a number of different plots using the combined data
% from all experiments from a particular fly strain and for a particular
% protocol. 

% Inputs
% - - - - 

% strain_data_folder : Path (e.g.
% '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_v1/JFRC49_ES')

% Information about the strain / protocol. 
subfolders = split(data_folder, '/');
sex = subfolders{end};
strain = subfolders{end-1};
protocol = subfolders{end-2};

%% Generate combined velocity data 
combined_data = combine_data_across_exp(data_folder);

% Locomotion overview 
% loco_fig = make_locomotion_overview(combined_data, strain, sex, protocol);

% General overview - full experiment
figure
overview_fig = make_overview(combined_data, strain, sex, protocol);


end 













