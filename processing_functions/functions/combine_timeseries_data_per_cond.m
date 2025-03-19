function cond_data = combine_timeseries_data_per_cond( ...
    DATA, strain, sex, data_type, cond_idx)

% Combine the timeseries data for a specific condition, data type, strain 
% and sex  across experiments that is currently stored within the struct 
% 'DATA'.

% DATA is generated using 'comb_data_across_cohorts_cond' from the results
% files stored within 'oaky-cokey/results/protocol_X' folder.

% Returns:
% ________
% cond_data : array (size = [n_flies, n_frames_condition+interval])

    data = DATA.(strain).(sex); 
    n_exp = length(data); % Number of experiments run for this strain / sex.

    idx2 = cond_idx;
    
    rep1_str = strcat('R1_condition_', string(idx2));   
    rep2_str = strcat('R2_condition_', string(idx2));  
    
    % contains one row per fly and rep - combines data across all flies and all reps.
    cond_data = []; 
    nf_comb = size(cond_data, 2);
    
    for idx = 1:n_exp
        % disp(idx)
    
        rep1_data = data(idx).(rep1_str);
    
        if ~isempty(rep1_data) % check that the row is not empty.
    
            % Extract the relevant data
            rep1_data = rep1_data.(data_type);
            rep2_data = data(idx).(rep2_str).(data_type);
    
            % Number of frames in each rep
            nf1 = size(rep1_data, 2);
            nf2 = size(rep2_data, 2);
    
            if nf1>nf2
                nf = nf2;
            elseif nf2>nf1
                nf = nf1;
            else 
                nf = nf1;
            end 
    
            % Trim data to same length
            rep1_data = rep1_data(:, 1:nf);
            rep2_data = rep2_data(:, 1:nf);
    
            % Initialise empty array:
            rep_data = zeros(size(rep1_data));
    
            nf_comb = size(cond_data, 2);
    
            if idx == 1 || nf_comb == 0 % 
    
                for rr = 1:size(rep1_data, 1)
                    rep_data(rr, :) = mean(vertcat(rep1_data(rr, :), rep2_data(rr, :)));
                end 
    
            else
                if nf>nf_comb % trim incoming data
                    rep1_data = rep1_data(:, 1:nf_comb);
                    rep2_data = rep2_data(:, 1:nf_comb);
                elseif nf_comb>nf % Add NaNs to end
                    diff_f = nf_comb-nf+1;
                    n_flies = size(rep1_data, 1);
                    rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                    rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                end 
                rep_data = zeros(size(rep1_data));
                % For 'cond_data' have one row per fly - mean of 2
                % reps - not one row per rep. 
                for rr = 1:size(rep1_data, 1)
                    rep_data(rr, :) = mean(vertcat(rep1_data(rr, :), rep2_data(rr, :)));
                end 
            end
            % disp(height(rep_data))
            cond_data = vertcat(cond_data, rep_data);
    
        end 
    
    end 

end 

















