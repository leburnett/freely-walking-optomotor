%% GENERATE_STRAIN_METADATA_TABLE - Create a publication-ready strain metadata table
%
% Creates a MATLAB table combining:
%   - Manual annotations (driver line, neuron type, description, role)
%   - Auto-computed experiment statistics (n_cohorts, n_flies, temperature)
%
% USAGE:
%   Run this script after setup_path.m has been called.
%   The script loads Protocol 27 data, computes per-strain statistics,
%   and exports a CSV file.
%
% OUTPUT:
%   - strain_metadata_table.csv in {cfg.figures}/FIGS/
%   - MATLAB table variable 'metadata_table' in workspace
%
% DEPENDENCIES:
%   - comb_data_across_cohorts_cond.m
%   - generate_exp_data_struct.m
%   - get_config.m
%
% See also: generate_exp_data_struct, export_num_flies_summary

%% 1 - Manual strain annotations
% {folder_name, driver_line, neuron_type, description, role}
% NOTE: Neuron descriptions are placeholders — verify from Janelia FlyLight
% or published references before manuscript submission.

annotations = {
    'jfrc100_es_shibire_kir',      'JFRC100',     'Empty split',  'No GAL4 expression (genetic control)',    'Control';
    'ss324_t4t5_shibire_kir',      'SS00324',     'T4/T5',        'Direction-selective motion detectors',     'Positive control';
    'ss2344_T4_shibire_kir',       'SS02344',     'T4',           'ON-edge motion detector',                 'Screen';
    'ss2571_T5_shibire_kir',       'SS02571',     'T5',           'OFF-edge motion detector',                'Screen';
    'ss00297_Dm4_shibire_kir',     'SS00297',     'Dm4',          'Distal medulla interneuron',              'Screen hit';
    'ss02360_Dm4_shibire_kir',     'SS02360',     'Dm4',          'Distal medulla interneuron (line 2)',     'Replication';
    'ss02587_Dm4_shibire_kir',     'SS02587',     'Dm4',          'Distal medulla interneuron (line 3)',     'Replication';
    'ss03722_Tm5Y_shibire_kir',    'SS03722',     'Tm5Y',         'Transmedullary neuron',                   'Screen hit';
    'ss00316_Mi4_shibire_kir',     'SS00316',     'Mi4',          'Medulla intrinsic neuron',                'Screen';
    'ss00326_Pm2ab_shibire_kir',   'SS00326',     'Pm2ab',        'Proximal medulla neuron',                 'Screen';
    'ss00395_TmY3_shibire_kir',    'SS00395',     'TmY3',         'Transmedullary Y neuron',                 'Screen';
    'ss01027_H2_shibire_kir',      'SS01027',     'H2',           'Horizontal system wide-field neuron',     'Screen';
    'ss26283_H1_shibire_kir',      'SS26283',     'H1',           'Horizontal system wide-field neuron',     'Screen';
    'ss02594_TmY5a_shibire_kir',   'SS02594',     'TmY5a',        'Transmedullary Y neuron',                 'Screen';
    'ss2603_TmY20_shibire_kir',    'SS02603',     'TmY20',        'Transmedullary Y neuron',                 'Screen';
    'ss2575_LPC1_shibire_kir',     'SS02575',     'LPC1',         'Lobula plate columnar neuron',            'Screen';
    'ss1209_DCH_VCH_shibire_kir',  'SS01209',     'DCH/VCH',     'Descending neurons',                      'Screen';
    'ss34318_Am1_shibire_kir',     'SS34318',     'Am1',          'Anterior medial lobula neuron',           'Screen hit';
    'l1l4_jfrc100_shibire_kir',    'L1/L4 cross', 'L1/L4',       'Lamina monopolar neurons (blind ctrl)',   'Negative control';
};

% Build a lookup map: folder_name -> row index in annotations
annotation_map = containers.Map(annotations(:,1), num2cell(1:size(annotations,1)));

%% 2 - Load DATA and compute experiment statistics

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');

% Load and combine data across all cohorts for Protocol 27.
% This may take a few minutes depending on the number of strains.
fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
DATA = comb_data_across_cohorts_cond(protocol_dir);

% Extract per-strain experiment statistics using existing function.
exp_data = generate_exp_data_struct(DATA);

%% 3 - Build the metadata table

strain_names = fieldnames(exp_data);
n_strains = numel(strain_names);

% Preallocate cell arrays for table columns
folder_names     = cell(n_strains, 1);
driver_lines     = cell(n_strains, 1);
neuron_types     = cell(n_strains, 1);
descriptions     = cell(n_strains, 1);
roles            = cell(n_strains, 1);
n_cohorts        = zeros(n_strains, 1);
n_flies          = zeros(n_strains, 1);
mean_flies_per_c = zeros(n_strains, 1);
mean_temp_start  = zeros(n_strains, 1);
mean_fly_age     = zeros(n_strains, 1);

for i = 1:n_strains
    strain = strain_names{i};
    folder_names{i} = strain;

    % Look up manual annotations.
    % Handle the DCH-VCH hyphen/underscore mismatch:
    % DATA struct uses underscores, folder may have hyphen.
    lookup_name = strain;
    if ~isKey(annotation_map, lookup_name)
        % Try converting underscore back to hyphen for DCH_VCH case
        lookup_name = strrep(strain, 'DCH_VCH', 'DCH_VCH');
        if ~isKey(annotation_map, lookup_name)
            warning('No annotation found for strain: %s', strain);
            driver_lines{i}  = 'UNKNOWN';
            neuron_types{i}  = 'UNKNOWN';
            descriptions{i}  = 'No annotation available';
            roles{i}         = 'UNKNOWN';
        end
    end

    if isKey(annotation_map, lookup_name)
        idx = annotation_map(lookup_name);
        driver_lines{i}  = annotations{idx, 2};
        neuron_types{i}  = annotations{idx, 3};
        descriptions{i}  = annotations{idx, 4};
        roles{i}         = annotations{idx, 5};
    end

    % Auto-computed statistics from generate_exp_data_struct
    n_cohorts(i)        = exp_data.(strain).n_vials;
    n_flies(i)          = exp_data.(strain).n_flies_total;
    mean_flies_per_c(i) = round(n_flies(i) / n_cohorts(i), 1);
    mean_temp_start(i)  = round(mean(exp_data.(strain).temp_start, 'omitnan'), 1);
    mean_fly_age(i)     = round(mean(exp_data.(strain).fly_age, 'omitnan'), 1);
end

% Assemble into a MATLAB table
metadata_table = table( ...
    folder_names, ...
    driver_lines, ...
    neuron_types, ...
    descriptions, ...
    roles, ...
    n_cohorts, ...
    n_flies, ...
    mean_flies_per_c, ...
    mean_temp_start, ...
    mean_fly_age, ...
    'VariableNames', { ...
        'Strain', ...
        'DriverLine', ...
        'NeuronType', ...
        'Description', ...
        'Role', ...
        'N_Cohorts', ...
        'N_Flies', ...
        'MeanFliesPerCohort', ...
        'MeanTemp_C', ...
        'MeanAge_hrs' ...
    });

%% 4 - Display and export

% Sort: control first, then alphabetically by neuron type
role_order = {'Control', 'Positive control', 'Negative control', ...
              'Screen hit', 'Screen', 'Replication'};
[~, role_idx] = ismember(metadata_table.Role, role_order);
[~, sort_order] = sortrows([role_idx, (1:n_strains)']);
metadata_table = metadata_table(sort_order, :);

% Display in command window
disp('=== Strain Metadata Table (Protocol 27) ===');
disp(metadata_table);
fprintf('\nTotal strains: %d\n', n_strains);
fprintf('Total flies:   %d\n', sum(n_flies));
fprintf('Total cohorts: %d\n', sum(n_cohorts));

% Export to CSV
save_folder = fullfile(cfg.figures, 'FIGS');
if ~isfolder(save_folder)
    mkdir(save_folder);
end

output_file = fullfile(save_folder, 'strain_metadata_table.csv');
writetable(metadata_table, output_file);
fprintf('\nTable saved to: %s\n', output_file);

% Also save as .mat for reuse in other figure scripts
save(fullfile(save_folder, 'strain_metadata_table.mat'), 'metadata_table', 'annotations');
fprintf('MAT file saved to: %s\n', fullfile(save_folder, 'strain_metadata_table.mat'));
