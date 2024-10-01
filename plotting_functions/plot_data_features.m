function plot_data_features(results_path)
% Plot the velocity, angular velocity, heading and distance from the centre of
% the arena for each experiment (file) within the 'results_path' folder. 

results_path = ['/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_v7/csw1118/females'];
cd(results_path)

exps = dir('*data.mat');
n_exps = height(exps);

for i = 1:n_exps
    load(fullfile(exps(i).folder, exps(i).name));

    title_str = exps(i).name;
    title_str = title_str(1:end-9);
    title_str = strrep(title_str, '_', '-');

    % Plot the heading anlge per fly - large plot containing n_flies subplots. 
    fig_heading_per_fly = plot_heading_angle_per_fly(Log, trx, title_str);
    savefig(fig_heading_per_fly);
    
    % feat = vel (1)
    f_vel_per_fly = plot_vel_per_fly(Log, feat, title_str);
    savefig(f_vel_per_fly);

    % feat = ang_vel (2) - NO - derive from trx theta
    f_angvel_per_fly = plot_ang_vel_per_fly(Log, trx, title_str);
    savefig(f_angvel_per_fly);

    % feat = dist_to_wall (9)
    f_dist_to_wall = plot_dist_2_centre_per_fly(Log, feat, title_str);
    savefig(f_dist_to_wall)


    % Create overall combined figure with the mean per all flies in the
    % cohort.
    f_all = plot_all_features(Log, feat, trx, title_str);
    savefig(f_all)
end 


% Then move to the results folder and create figures with all of the data
% from multiple experiments. 


end 