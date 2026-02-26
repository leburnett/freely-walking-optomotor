function var_array = sliding_variance(data, window_size, step_size)
    % Validate inputs
    if window_size > length(data)
        error('Window size must be less than or equal to the length of the data array.');
    end
    
    % Initialize output array
    num_windows = floor((length(data) - window_size) / step_size) + 1;
    var_array = zeros(1, num_windows);
    
    % Compute variance for each window
    index = 1;
    for i = 1:step_size:(length(data) - window_size + 1)
        window_data = data(i:i + window_size - 1);
        var_array(index) = var(window_data);
        index = index + 1;
    end
end