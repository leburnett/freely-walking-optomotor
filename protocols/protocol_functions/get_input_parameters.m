function selections = get_input_parameters()
    
    % Create a figure window for the input dialog
    fig = uifigure('Name', 'Fly Experiment Setup', 'Position', [500 500 300 250]);

    % Dropdown for Strain
    uilabel(fig, 'Position', [20 200 80 22], 'Text', 'Fly Strain:');
    strainDropdown = uidropdown(fig, ...
        'Position', [120 200 150 22], ...
        'Items', {'csw1118', 'jfrc49_es_kir', 'ss324_t4t5_kir', 'jfrc49_l1l4_kir', 'jfrc100_es_shibire', 'ss324_t4t5_shibire', 't4t5_RNAi_control', 't4t5_mmd_RNAi', 't4t5_ttl_RNAi', 'test'}, ...
        'Value', 'csw1118');

    % Dropdown for Age
    uilabel(fig, 'Position', [20 150 80 22], 'Text', 'Age of Fly:');
    ageDropdown = uidropdown(fig, ...
        'Position', [120 150 150 22], ...
        'Items', {'1', '2', '3', '4', '5', '6', '7', '8', 'NaN'}, ...
        'Value', '4');

    % Dropdown for Sex
    uilabel(fig, 'Position', [20 100 80 22], 'Text', 'Sex of Fly:');
    sexDropdown = uidropdown(fig, ...
        'Position', [120 100 150 22], ...
        'Items', {'F', 'M', 'NaN'}, ...
        'Value', 'F');

    % Dropdown for Light Cycle
    uilabel(fig, 'Position', [20 50 80 22], 'Text', 'Light Cycle:');
    lightCycleDropdown = uidropdown(fig, ...
        'Position', [120 50 150 22], ...
        'Items', {'20:00_12:00', '01:00_17:00', 'NaN'}, ...
        'Value', '01:00_17:00');

    % Variable to hold selections
    selections = struct('Strain', '', 'Age', '', 'Sex', '', 'LightCycle', '');

    % Confirm Button with callback function to retrieve values and close the figure
    confirmButton = uibutton(fig, 'push', ...
        'Position', [100 10 100 30], ...
        'Text', 'Confirm', ...
        'ButtonPushedFcn', @(btn, event) confirmSelections(strainDropdown, ageDropdown, sexDropdown, lightCycleDropdown, fig));

    % Wait for the figure to close before proceeding
    uiwait(fig);

    % Retrieve selected values from the struct after uiwait releases
    % selectedStrain = selections.Strain;
    % selectedAge = selections.Age;
    % selectedSex = selections.Sex;
    % selectedLightCycle = selections.LightCycle;

    % Callback function to store selections and close the figure
    function confirmSelections(strainDropdown, ageDropdown, sexDropdown, lightCycleDropdown, fig)
        selections.Strain = strainDropdown.Value;
        selections.Age = ageDropdown.Value;
        selections.Sex = sexDropdown.Value;
        selections.LightCycle = lightCycleDropdown.Value;
        close(fig);
    end

end 


