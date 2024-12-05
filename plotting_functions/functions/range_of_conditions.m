function [min_val, max_val] = range_of_conditions(data)

 % Get all field names of the struct
fieldNames = fieldnames(data);

% Filter field names that start with 'R1_'
r1Fields = fieldNames(startsWith(fieldNames, 'R1_'));

% Initialize an array to store extracted numbers
numbers = [];

% Loop through each field name
for i = 1:length(r1Fields)
    % Use regular expressions to extract numbers at the end of the field name
    match = regexp(r1Fields{i}, '_(\d+)$', 'tokens');
    
    % If a number is found, convert it to double and store it
    if ~isempty(match)
        numbers(end + 1) = str2double(match{1}{1});
    end
end

% Calculate the range of numbers
min_val = min(numbers);
max_val = max(numbers);

% Display the results
fprintf('Range of conditions: %d to %d\n', min_val, max_val);

