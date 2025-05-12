function selections = get_input_parameters()
    
    % Create a figure window for the input dialog
    fig = uifigure('Name', 'Fly Experiment Setup', 'Position', [500 500 300 350]);

    % Dropdown for Number of Flies
    uilabel(fig, 'Position', [20 300 80 22], 'Text', 'nFlies:');
    nfliesDropdown = uidropdown(fig, ...
        'Position', [120 300 150 22], ...
        'Items', {'9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20'}, ...
        'Value', '15');

    % Dropdown for Experimenter
    uilabel(fig, 'Position', [20 250 80 22], 'Text', 'Experimenter:');
    experimenterDropdown = uidropdown(fig, ...
        'Position', [120 250 150 22], ...
        'Items', {'AparnaDev', 'LauraBurnett', 'other'}, ...
        'Value', 'AparnaDev');

    % Dropdown for Strain
    uilabel(fig, 'Position', [20 200 80 22], 'Text', 'Fly Strain:');
    strainDropdown = uidropdown(fig, ...
        'Position', [120 200 150 22], ...
        'Items', {'csw1118', 'ss324_t4t5_shibire_kir', 'jfrc100_es_shibire_kir', 'jfrc100_es_shibire_kirB','l1l4_jfrc100_shibire_kir', 'ss26283_H1_shibire_kir', 'ss01027_H2_shibire_kir', 'ss1209_DCH-VCH_shibire_kir', 'ss34318_Am1_shibire_kir', 'ss03722_Tm5Y_shibire_kir', 'ss00395_TmY3_shibire_kir', '2575_LPC1_shibire_kir', '2575_LPC1_shibire_kirB', 'ss02594_TmY5a_shibire_kir', 'ss02594_TmY5a_shibire_kirB', 'ss00297_Dm4_shibire_kir', 'ss00326_Pm2ab_shibire_kir', 't4t5_RNAi_control', 't4t5_mmd_RNAi', 't4t5_ttl_RNAi', 'test'}, ...
        'Value', 'jfrc100_es_shibire_kir');

    % Dropdown for Age
    uilabel(fig, 'Position', [20 150 80 22], 'Text', 'Age of Fly:');
    ageDropdown = uidropdown(fig, ...
        'Position', [120 150 150 22], ...
        'Items', {'1', '2', '3', '4', '5', '6', '7', '8', '>8', '1-2', '2-3', '3-4', '4-5','NaN'}, ...
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
    selections = struct('nFlies', '', 'Experimenter', '', 'Strain', '', 'Age', '', 'Sex', '', 'LightCycle', '');

    % Confirm Button with callback function to retrieve values and close the figure
    confirmButton = uibutton(fig, 'push', ...
        'Position', [100 10 100 30], ...
        'Text', 'Confirm', ...
        'ButtonPushedFcn', @(btn, event) confirmSelections(nfliesDropdown, experimenterDropdown, strainDropdown, ageDropdown, sexDropdown, lightCycleDropdown, fig));

    % Wait for the figure to close before proceeding
    uiwait(fig);

    % Callback function to store selections and close the figure
    function confirmSelections(nfliesDropdown, experimenterDropdown, strainDropdown, ageDropdown, sexDropdown, lightCycleDropdown, fig)
        selections.nFlies = nfliesDropdown.Value;
        selections.Experimenter = experimenterDropdown.Value;
        selections.Strain = strainDropdown.Value;
        selections.Age = ageDropdown.Value;
        selections.Sex = sexDropdown.Value;
        selections.LightCycle = lightCycleDropdown.Value;
        close(fig);
    end

end 


