function binned_array = bin_data(input_array, window_size, step_size, start_frame, end_frame)
    
    % Get the number of flies and frames from input data
    [n_flies, ~] = size(input_array);
    
    % Compute the number of bins
    n_bins = floor((end_frame - start_frame - window_size) / step_size) + 1;

    % Preallocate the binned array
    binned_array = nan(n_flies, n_bins);

    % Loop through each bin
    for i = 1:n_bins
        start_idx = start_frame + (i-1) * step_size;  % Start of the window
        end_idx = start_idx + window_size - 1;        % End of the window

        % Compute mean within the window
        binned_array(:, i) = nanmean(input_array(:, start_idx:end_idx), 2);
    end
end
