function [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_straightness(x_data, x_data_control, y_data, y_data_control, rng)
 
    n_reps = size(x_data, 1);

    % TARGET 
    str_data = zeros([n_reps, 1]);

    % Calculate the straightness of the path over the given range for each rep
    for i = 1:n_reps
        [~, ~, straightness] = computeTwoPointDisplacement(x_data(i, :), y_data(i, :), rng);
        str_data(i, 1) = straightness;
    end 

    % THEN average acros the reps to get the average path straightness per fly. 
    mean_per_fly = mean_every_two_rows(str_data)';
    mean_per_strain = nanmean(mean_per_fly);


    % CONTROL

    % TARGET 
    str_data_control = zeros([n_reps, 1]);
    
    % Calculate the straightness of the path over the given range for each rep
    for i = 1:n_reps
        [~, ~, straightness] = computeTwoPointDisplacement(x_data_control(i, :), y_data_control(i, :), rng);
        str_data_control(i, 1) = straightness;
    end 

    % THEN average acros the reps to get the average path straightness per fly. 
    mean_per_fly_control = mean_every_two_rows(str_data_control)';
    mean_per_strain_control = nanmean(mean_per_fly_control); % single value.

    % Unpaired t-test with unequal group sizes (Welch's t-test)
    [~, p] = ttest2(mean_per_fly, mean_per_fly_control, 'Vartype','unequal');


end 