function plot_data_features(results_path)
% Plot the velocity, angular velocity, heading and distance from the centre of
% the arena for each experiment (file) within the 'results_path' folder. 

% Inputs
% ______

% 'results_path' : Path
%       Path to results files e.g.
%       '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_v5/csw1118/F'

% results_path = ['/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_v5/csw1118/F'];
cd(results_path)

exps = dir('*data.mat');
n_exps = height(exps);

for i = 1:n_exps
    load(fullfile(exps(i).folder, exps(i).name));

    title_str = exps(i).name;
    title_str = title_str(1:end-9);
    title_str = strrep(title_str, '_', '-');

    % Combined figure with individual traces per fly
    f_all = plot_all_features(Log, feat, trx, title_str);
    % savefig(f_all)
end 

% Plot all features - mean + SEM across all cohorts for a particular
% condition. 
plot_all_features_mean_sem()

end 