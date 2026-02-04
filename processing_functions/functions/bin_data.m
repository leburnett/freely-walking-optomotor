function binned_array = bin_data(input_array, window_size, step_size, start_frame, end_frame)
% BIN_DATA Compute sliding window averages across time for all flies
%
%   binned_array = BIN_DATA(input_array, window_size, step_size, start_frame, end_frame)
%   computes the mean value within sliding windows for behavioral timeseries data.
%
% INPUTS:
%   input_array - [n_flies x n_frames] matrix of behavioral data
%   window_size - Number of frames to average within each bin
%   step_size   - Number of frames to advance between bins
%   start_frame - First frame to include in binning
%   end_frame   - Last frame to include in binning
%
% OUTPUT:
%   binned_array - [n_flies x n_bins] matrix of binned averages
%
% EXAMPLE:
%   % Bin distance data in 5-second (150 frame) windows, stepping 150 frames
%   binned_dist = bin_data(dist_data, 150, 150, 300, 1200);
%
%   % Overlapping windows: 5s window, 2.5s step
%   binned_dist = bin_data(dist_data, 150, 75, 300, 1200);
%
% NOTES:
%   - Uses nanmean to handle missing values
%   - n_bins = floor((end_frame - start_frame - window_size) / step_size) + 1
%   - Useful for computing time-binned summary statistics
%
% See also: nanmean, combine_timeseries_across_exp

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
