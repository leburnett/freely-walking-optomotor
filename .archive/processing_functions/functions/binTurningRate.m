function [binned_time, binned_turning_rate] = binTurningRate(time, curv_data, bin_size)
    % BINTURNINGRATE Bins turning rate data into specified time bins
    % 
    % Inputs:
    %   time - Vector of time points (seconds)
    %   curv_data - Vector of turning rate values per frame
    %   bin_size - Bin size in seconds (e.g., 0.5 for 0.5s bins)
    %
    % Outputs:
    %   binned_time - Time at bin centers
    %   binned_turning_rate - Averaged turning rate per bin

    % Determine bin edges
    min_time = min(time);
    max_time = max(time);
    edges = min_time:bin_size:max_time;

    % Compute binned means
    [~, ~, bin_idx] = histcounts(time, edges);
    binned_turning_rate = accumarray(bin_idx(bin_idx>0), curv_data(bin_idx>0), [], @mean);
    
    % Compute bin centers
    binned_time = edges(1:end-1) + bin_size/2;
end
