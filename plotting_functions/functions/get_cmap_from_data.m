function cmap_array = get_cmap_from_data(data)

    % Normalize col_bin to range [0,1] for colormap scaling
    col_bin = data(:); % Ensure column vector
    col_bin = fillmissing(col_bin, 'nearest');
    col_bin_norm = (col_bin - min(col_bin)) / (max(col_bin) - min(col_bin));
    % col_bin_norm = (col_bin - 0) / (125 - 0);
    
    % Define the colormap (e.g., 'parula', 'jet', 'viridis', etc.)
    cmap = parula(256); % Change colormap if needed
    
    % Map col_bin_norm to actual RGB values
    color_indices = round(col_bin_norm * (size(cmap, 1) - 1)) + 1;
    color_indices = fillmissing(color_indices, 'nearest'); % in case of NaNs
    cmap_array = cmap(color_indices, :);

end 