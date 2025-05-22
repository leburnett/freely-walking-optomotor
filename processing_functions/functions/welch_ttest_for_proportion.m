function [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_proportion(cond_data, cond_data_control, rng, threshold, more_or_less)
    
    %  TARGET

    d = cond_data(:, rng);
    d2 = mean_every_two_rows(d);
    n_flies = height(d2);
    n_frames = size(d2, 2);
    val_per_fly = zeros(size(n_flies, 1));

    if more_or_less == "more"

        for idx = 1:n_flies
            n_frames_threshold = numel(find(d2(idx, :)> threshold));
            val_per_fly(idx) = n_frames_threshold / n_frames;
        end 

    elseif more_or_less == "less"

        for idx = 1:n_flies
            n_frames_threshold = numel(find(d2(idx, :)< threshold));
            val_per_fly(idx) = n_frames_threshold / n_frames;
        end 
    end 

    mean_per_strain = mean(val_per_fly); % single value. 

    % CONTROL

    d_control = cond_data_control(:, rng);
    d2_control = mean_every_two_rows(d_control);

    n_flies_c = height(d2_control);
    n_frames_c = size(d2_control, 2);
    val_per_fly_control = zeros(size(n_flies_c, 1));

    if more_or_less == "more"

        for idx = 1:n_flies_c
            n_frames_threshold = numel(find(d2_control(idx, :)> threshold));
            val_per_fly_control(idx) = n_frames_threshold / n_frames_c;
        end 

    elseif more_or_less == "less"

        for idx = 1:n_flies_c
            n_frames_threshold = numel(find(d2_control(idx, :)< threshold));
            val_per_fly_control(idx) = n_frames_threshold / n_frames_c;
        end 

    end 

    mean_per_strain_control = mean(val_per_fly_control); % single value. 

    % Unpaired t-test with unequal group sizes (Welch's t-test)
    [~, p] = ttest2(val_per_fly, val_per_fly_control, 'Vartype','unequal');

end 