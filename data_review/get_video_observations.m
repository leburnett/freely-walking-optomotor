function selections = get_video_observations()
    
    % Create a figure window for the input dialog
    fig = uifigure('Name', 'Video Observations', 'Position', [500 500 330 350]);

    % Dropdown for centring
    uilabel(fig, 'Position', [20 300 100 22], 'Text', 'Centring (0-10):');
    centreDropdown = uidropdown(fig, ...
        'Position', [140 300 150 22], ...
        'Items', {'0','1', '2', '3', '4', '5', '6', '7','8', '9', '10', 'NaN'}, ...
        'Value', '0');

    % Dropdown for turning style
    uilabel(fig, 'Position', [20 250 100 22], 'Text', 'Turning style:');
    turningDropdown = uidropdown(fig, ...
        'Position', [140 250 150 22], ...
        'Items', {'None', 'LargeLoops', 'TightLoops', 'Pirouette', 'Pivot', }, ...
        'Value', 'None');

    % Dropdown for rebound activity
    uilabel(fig, 'Position', [20 200 100 22], 'Text', 'Rebound?');
    reboundDropdown = uidropdown(fig, ...
        'Position', [140 200 150 22], ...
        'Items', {'None', 'Strong', 'Medium', 'Weak'}, ...
        'Value', 'None');

    % Dropdown for spatial spread of flies
    uilabel(fig, 'Position', [20 150 100 22], 'Text', 'Fly Distribution:');
    distDropdown = uidropdown(fig, ...
        'Position', [140 150 150 22], ...
        'Items', {'Diffuse', 'Clustered', 'Mixed', 'NA'}, ...
        'Value', 'NA');

    % Dropdown for locomotion
    uilabel(fig, 'Position', [20 100 100 22], 'Text', 'Locomotion:');
    locoDropdown = uidropdown(fig, ...
        'Position', [140 100 150 22], ...
        'Items', {'None', 'Slow', 'Mid', 'Fast'}, ...
        'Value', 'None');

    % Dropdown for response diversity
    uilabel(fig, 'Position', [20 50 110 22], 'Text', 'Resp diversity (%):');
    diversityDropdown = uidropdown(fig, ...
        'Position', [140 50 150 22], ...
        'Items', {'0','10', '20', '30', '40', '50', '60', '70','80', '90', '100', 'NaN'}, ...
        'Value', 'NaN');

    % Variable to hold selections
    selections = struct('centring', '', 'turning', '', 'rebound', '', 'distribution', '', 'locomotion', '', 'diversity', '');

    % Confirm Button with callback function to retrieve values and close the figure
    confirmButton = uibutton(fig, 'push', ...
        'Position', [100 10 100 30], ...
        'Text', 'Confirm', ...
        'ButtonPushedFcn', @(btn, event) confirmSelections(centreDropdown, turningDropdown, reboundDropdown, distDropdown, locoDropdown, diversityDropdown, fig));

    % Wait for the figure to close before proceeding
    uiwait(fig);

    % Callback function to store selections and close the figure
    function confirmSelections(centreDropdown, turningDropdown, reboundDropdown, distDropdown, locoDropdown, diversityDropdown, fig)
        selections.centring = centreDropdown.Value;
        selections.turning = turningDropdown.Value;
        selections.rebound = reboundDropdown.Value;
        selections.distribution = distDropdown.Value;
        selections.locomotion = locoDropdown.Value;
        selections.diversity = diversityDropdown.Value;
        close(fig);
    end

end 




