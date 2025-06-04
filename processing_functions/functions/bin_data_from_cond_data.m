function binned_vals = bin_data_from_cond_data(cond_data, frame_rng, data_type, bin_size)

  % Extract data only from the desired frames
    d = cond_data(:, frame_rng);
    [nRows, nTimePoints] = size(d);
    
    % Bin size
    % bin_size = 15; % 0.5s
    % bin_size = 60; % 2s
    
    % Number of full bins
    nBins = floor(nTimePoints / bin_size);
    
    % Truncate to remove extra timepoints
    d_truncated = d(:, 1:bin_size * nBins);  % size: [nRows, bin_size * nBins]

    % Reshape each row into [nRows, bin_size, nBins]
    d_reshaped = reshape(d_truncated', bin_size, nBins, nRows);  % size: [15, nBins, nRows]
    d_reshaped = permute(d_reshaped, [3 1 2]);   % size: [nRows, 15, nBins] 
    
    if data_type ~= "dist_data_delta"
                       
        % Compute mean across the bin dimension (dim 2)
        binned_vals = mean(d_reshaped, 2);  % size: [nRows, 1, nBins]

    elseif data_type == "dist_data" % first value of bin
        binned_vals = d_reshaped(:, 1, :);   % size: [nRows, 1, nBins]
    
    else
        % Instead of the mean find the difference between the first and
        % last frame of the time window (bin). 

        % Extract first and last timepoint in each bin
        first_vals = d_reshaped(:, 1, :);   % size: [nRows, 1, nBins]
        last_vals  = d_reshaped(:, end, :); % size: [nRows, 1, nBins]
        
        % Compute difference (last - first)
        binned_vals = squeeze(last_vals - first_vals)*-1;  % size: [nRows, nBins]

    end

end 