function [rep_data, rep_data_fv] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent)
% Check the data for an individual fly across an individual rep. 
% Remove reps where the fly either doesn't move, or remains too close to
% the edge of the arena. 

    % Initialise empty array:
    rep_data = zeros(size(rep1_data));
    rep_data_fv = zeros((size(rep1_data_fv)));

    for rr = 1:size(rep1_data, 1)

        % Check what the fly's average forward velocity was during the first rep.
        mean_fv_rep1 = mean(rep1_data_fv(rr, :));
        min_dcent_rep1 = min(rep1_data_dcent(rr, :));
        if mean_fv_rep1 < 3  || min_dcent_rep1 > 110 % Less than 3mms-1 or never closer than 100mm from centre.
            % disp('Removing rep1')
            rep1_data(rr, :) = nan(size(rep1_data(rr, :)));
            rep1_data_fv(rr, :) = nan(size(rep1_data_fv(rr, :)));
        end 

        % Check what the fly's average forward velocity was during the second rep.
        mean_fv_rep2 = mean(rep2_data_fv(rr, :));
        min_dcent_rep2 = min(rep2_data_dcent(rr, :));
        if mean_fv_rep2 < 3 || min_dcent_rep2 > 110 % Less than 3mms-1 or never closer than 100mm from centre.
            % disp('Removing rep2')
            rep2_data(rr, :) = nan(size(rep2_data(rr, :)));
            rep2_data_fv(rr, :) = nan(size(rep2_data_fv(rr, :)));
        end 
            
        rep_data(rr, :) = nanmean(vertcat(rep1_data(rr, :), rep2_data(rr, :)));
        rep_data_fv(rr, :) = nanmean(vertcat(rep1_data_fv(rr, :), rep2_data_fv(rr, :)));
    end

    % Remove rows that are filled with NaNs
    rep_data = rmmissing(rep_data, 'MinNumMissing', size(rep_data, 2));
    rep_data_fv = rmmissing(rep_data_fv, 'MinNumMissing', size(rep_data, 2));

end 
