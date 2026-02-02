function output = mean_every_two_rows(input)
    % Check that the number of rows is even
    if mod(size(input, 1), 2) ~= 0
        error('Number of rows in input must be even.');
    end

    % Reshape and compute the mean
    reshaped = reshape(input', size(input, 2), 2, []); % [cols x 2 x num_pairs]
    output = squeeze(nanmean(reshaped, 2))'; % Take mean along 2nd dim and transpose
end