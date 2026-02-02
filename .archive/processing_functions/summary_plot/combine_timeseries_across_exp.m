function cond_data = combine_timeseries_across_exp(data, condition_n, data_type)
% Combines the timeseries data across the two reps and across all
% experiments for a given strain. 
% Currently, the two rep time series are vertically concatenated, but not
% averaged. 

n_exp = length(data);

cond_data = [];

rep1_str = strcat('R1_condition_', string(condition_n));   
rep2_str = strcat('R2_condition_', string(condition_n));  

    if isfield(data, rep1_str)
    
        % nf_comb = size(cond_data, 2);
    
        for idx = 1:n_exp

            rep1_data = data(idx).(rep1_str);
        
            if ~isempty(rep1_data) % check that the row is not empty.
    
                % rep1_data_fv = rep1_data.fv_data;
                % rep2_data_fv = data(idx).(rep2_str).fv_data;
                % rep1_data_dcent = rep1_data.dist_data;
                % rep2_data_dcent = data(idx).(rep2_str).dist_data;
    
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
    
                % rep1_data_fv = rep1_data_fv(:, 1:nf);
                % rep2_data_fv = rep2_data_fv(:, 1:nf);
                % 
                nf_comb = size(cond_data, 2);
    
                if idx == 1 || nf_comb == 0
    
                    % The function below checks if during either of the
                    % reps, the fly moves on average < 2mm s-1, or never
                    % gets further than 20mm from the edge of the arena. If
                    % these conditions are met, then the rep gets converted
                    % to NaNs, the two reps are then combined and averaged
                    % and that average across both reps for the single fly
                    % is combined together to get 'cond_data'. 
    
                    % [rep_data, rep_data_fv] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent);
                   
                    % Combine the data from both reps for a single fly so
                    % that rows following each other are the two reps for
                    % one fly. 
    
                    n_flies = height(rep1_data);
                    rep_data = zeros(n_flies*2, nf); % Preallocate array
    
                    % Interleave rows
                    rep_data(1:2:end, :) = rep1_data;
                    rep_data(2:2:end, :) = rep2_data;
    
                    cond_data = vertcat(cond_data, rep_data);

                else

                    if nf>=nf_comb % trim incoming data
                        rep1_data = rep1_data(:, 1:nf_comb);
                        rep2_data = rep2_data(:, 1:nf_comb);
    
                    elseif nf_comb>nf % Add NaNs to end
    
                        diff_f = nf_comb-nf+1;
                        n_flies = size(rep1_data, 1);
                        rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                    end 
    
                    n_flies = height(rep1_data);
                    rep_data = zeros(n_flies*2, nf_comb); % Preallocate array
    
                    % Interleave rows so that the 2 reps from each animal
                    % are next to each other.
                    rep_data(1:2:end, :) = rep1_data;
                    rep_data(2:2:end, :) = rep2_data;
    
                    % [rep_data, rep_data_fv] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent);
                    cond_data = vertcat(cond_data, rep_data);
                end
            end 
        end
    
    end 

end 