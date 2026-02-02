function plot_histogram_from_cond_data(cond_data, frame_rng, data_type, col)

    % Extract data only from the desired frames
    d = cond_data(:, frame_rng);
    [nRows, nTimePoints] = size(d);
    
    % Bin size
    bin_size = 15;
    
    % Number of full bins
    nBins = floor(nTimePoints / bin_size);
    
    % Truncate to remove extra timepoints
    d_truncated = d(:, 1:bin_size * nBins);  % size: [nRows, bin_size * nBins]

    % Reshape each row into [nRows, bin_size, nBins]
    d_reshaped = reshape(d_truncated', bin_size, nBins, nRows);  % size: [15, nBins, nRows]
    d_reshaped = permute(d_reshaped, [3 1 2]);   % size: [nRows, 15, nBins] 
    
    if data_type ~= "dist_data"
                       
        % Compute mean across the bin dimension (dim 2)
        binned_vals = mean(d_reshaped, 2);  % size: [nRows, 1, nBins]

        % Reshape into 1D vector for histogram
        binned_vals_all = reshape(binned_vals, [], 1);  % size: [nRows * nBins, 1]
    
    else
        % Instead of the mean find the difference between the first and
        % last frame of the time window (bin). 

        % Extract first and last timepoint in each bin
        first_vals = d_reshaped(:, 1, :);   % size: [nRows, 1, nBins]
        last_vals  = d_reshaped(:, end, :); % size: [nRows, 1, nBins]
        
        % Compute difference (last - first)
        binned_vals = squeeze(last_vals - first_vals)*-1;  % size: [nRows, nBins]

        % Optional: Flatten all diffs into 1D vector for histogram
        binned_vals_all = bin_diffs(:);  % size: [nRows * nBins, 1]
    end
    
    % Find the highest value:
    max_val = max(binned_vals_all);
    min_val = min(binned_vals_all);
    if min_val>0
        min_val = 0;
    end 
    
    if data_type == "fv_data"
        step_size = 2;
    elseif data_type == "av_data" 
        step_size = 20;
    elseif data_type == "curv_data"
        step_size = 10;
    elseif data_type == "dist_data"
        step_size = 0.5;
    else
        step_size = 10;
    end 

    % Plot histogram
    histogram(binned_vals_all,'Normalization', 'probability', 'BinEdges', min_val:step_size:max_val, 'FaceColor', col, 'FaceAlpha', 0.5);
    % xlabel('Mean per 0.5s bin');
    xlabel('')
    ylabel('Probability');
    set(gca, 'YScale', 'log')

    box off
    ax = gca;
    ax.TickDir = 'out';
    ax.LineWidth = 1.2;
    ax.FontSize = 10;

    if data_type == "fv_data"
        xlim([-2 100])
    elseif data_type == "av_data"
        xlim([-5 400])
    elseif data_type == "curv_data"
        xlim([-5 600])
    end 

end 