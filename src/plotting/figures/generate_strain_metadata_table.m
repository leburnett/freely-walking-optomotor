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

% --- Main screen strains (Protocol 27) ---
% {folder_name, driver_line, neuron_type, description, role, dataset}
annotations = {
    'jfrc100_es_shibire_kir',      'JFRC100',     'Empty split',  'No GAL4 expression (genetic control)',    'Control',          'screen';
    'ss324_t4t5_shibire_kir',      'SS00324',     'T4/T5',        'Direction-selective motion detectors',     'Positive control', 'screen';
    'ss2344_T4_shibire_kir',       'SS02344',     'T4',           'ON-edge motion detector',                 'Screen',           'screen';
    'ss2571_T5_shibire_kir',       'SS02571',     'T5',           'OFF-edge motion detector',                'Screen',           'screen';
    'ss00297_Dm4_shibire_kir',     'SS00297',     'Dm4',          'Distal medulla interneuron',              'Screen hit',       'screen';
    'ss02360_Dm4_shibire_kir',     'SS02360',     'Dm4',          'Distal medulla interneuron (line 2)',     'Replication',      'screen';
    'ss02587_Dm4_shibire_kir',     'SS02587',     'Dm4',          'Distal medulla interneuron (line 3)',     'Replication',      'screen';
    'ss03722_Tm5Y_shibire_kir',    'SS03722',     'Tm5Y',         'Transmedullary neuron',                   'Screen hit',       'screen';
    'ss00316_Mi4_shibire_kir',     'SS00316',     'Mi4',          'Medulla intrinsic neuron',                'Screen',           'screen';
    'ss00326_Pm2ab_shibire_kir',   'SS00326',     'Pm2ab',        'Proximal medulla neuron',                 'Screen',           'screen';
    'ss00395_TmY3_shibire_kir',    'SS00395',     'TmY3',         'Transmedullary Y neuron',                 'Screen',           'screen';
    'ss01027_H2_shibire_kir',      'SS01027',     'H2',           'Horizontal system wide-field neuron',     'Screen',           'screen';
    'ss26283_H1_shibire_kir',      'SS26283',     'H1',           'Horizontal system wide-field neuron',     'Screen',           'screen';
    'ss02594_TmY5a_shibire_kir',   'SS02594',     'TmY5a',        'Transmedullary Y neuron',                 'Screen',           'screen';
    'ss2603_TmY20_shibire_kir',    'SS02603',     'TmY20',        'Transmedullary Y neuron',                 'Screen',           'screen';
    'ss2575_LPC1_shibire_kir',     'SS02575',     'LPC1',         'Lobula plate columnar neuron',            'Screen',           'screen';
    'ss1209_DCH_VCH_shibire_kir',  'SS01209',     'DCH/VCH',     'Descending neurons',                      'Screen',           'screen';
    'ss34318_Am1_shibire_kir',     'SS34318',     'Am1',          'Anterior medial lobula neuron',           'Screen hit',       'screen';
    'l1l4_jfrc100_shibire_kir',    'L1/L4 cross', 'L1/L4',       'Lamina monopolar neurons (blind ctrl)',   'Negative control', 'screen';
    % --- NorpA photoreceptor rescue strains (Protocol 27_Norp) ---
    'NorpA_plus_plus',             'NorpA',       'NorpA +/+',    'NorpA homozygous (blind control)',        'NorpA control',    'norpA';
    'NorpA_UAS_Norp_plus',         'NorpA',       'NorpA UAS/+',  'NorpA with UAS-NorpA, no driver',        'NorpA control',    'norpA';
    'NorpA_UAS_Norp_Rh1_Gal4',    'NorpA',       'NorpA Rh1',    'NorpA rescued in R1-R6 (Rh1-Gal4)',      'NorpA rescue',     'norpA';
    'NorpA_UAS_Norp_Rh2_Gal4',    'NorpA',       'NorpA Rh2',    'NorpA rescued in ocelli (Rh2-Gal4)',     'NorpA rescue',     'norpA';
    'NorpA_UAS_Norp_Rh5_Rh6_Gal4','NorpA',       'NorpA Rh5/6',  'NorpA rescued in R7/R8 (Rh5+Rh6-Gal4)', 'NorpA rescue',     'norpA';
    'NorpAw_UAS_Norp_Rh1_Gal4',   'NorpAw',      'NorpAw Rh1',   'NorpAw rescued in R1-R6 (Rh1-Gal4)',    'NorpA rescue',     'norpA';
    'NorpAw_UAS_Norp_Rh2_Gal4',   'NorpAw',      'NorpAw Rh2',   'NorpAw rescued in ocelli (Rh2-Gal4)',   'NorpA rescue',     'norpA';
    'NorpAw_UAS_Norp_Rh5_Rh6_Gal4','NorpAw',     'NorpAw Rh5/6', 'NorpAw rescued in R7/R8 (Rh5+Rh6-Gal4)','NorpA rescue',    'norpA';
};

% Build a lookup map: folder_name -> row index in annotations
annotation_map = containers.Map(annotations(:,1), num2cell(1:size(annotations,1)));

%% 2 - Load DATA and compute experiment statistics

cfg = get_config();

% --- Load main screen data (Protocol 27) ---
protocol_dir = fullfile(cfg.results, 'protocol_27');
assert(isfolder(protocol_dir), ...
    'Protocol 27 directory not found: %s\nCheck cfg.project_root in get_config.m', protocol_dir);
fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
DATA = comb_data_across_cohorts_cond(protocol_dir);
assert(~isempty(fieldnames(DATA)), ...
    'DATA is empty — no .mat files found in %s', protocol_dir);

% --- Load NorpA data (Protocol 27_Norp) ---
norpA_dir = fullfile(cfg.results, 'protocol_27_Norp');
if isfolder(norpA_dir)
    fprintf('Loading NorpA data from: %s\n', norpA_dir);
    DATA_NORPA = comb_data_across_cohorts_cond(norpA_dir);
else
    warning('NorpA directory not found: %s — skipping NorpA strains.', norpA_dir);
    DATA_NORPA = struct();
end

% Extract per-strain experiment statistics using existing function.
exp_data = generate_exp_data_struct(DATA);
if ~isempty(fieldnames(DATA_NORPA))
    exp_data_norpA = generate_exp_data_struct(DATA_NORPA);
else
    exp_data_norpA = struct();
end

% Merge into one exp_data struct, normalizing NorpA folder names
% (hyphens -> underscores to match annotation keys)
norpA_names = fieldnames(exp_data_norpA);
for k = 1:numel(norpA_names)
    clean_name = strrep(norpA_names{k}, '-', '_');
    exp_data.(clean_name) = exp_data_norpA.(norpA_names{k});
end

%% 3 - Build the metadata table

strain_names = fieldnames(exp_data);
n_strains = numel(strain_names);

% Preallocate cell arrays for table columns
folder_names     = cell(n_strains, 1);
driver_lines     = cell(n_strains, 1);
neuron_types     = cell(n_strains, 1);
descriptions     = cell(n_strains, 1);
roles            = cell(n_strains, 1);
datasets         = cell(n_strains, 1);
n_cohorts        = zeros(n_strains, 1);
n_flies          = zeros(n_strains, 1);
mean_flies_per_c = zeros(n_strains, 1);
mean_temp_start  = zeros(n_strains, 1);
mean_fly_age     = zeros(n_strains, 1);

for i = 1:n_strains
    strain = strain_names{i};
    folder_names{i} = strain;

    % Look up manual annotations (folder names already normalized to underscores).
    lookup_name = strain;
    if isKey(annotation_map, lookup_name)
        idx = annotation_map(lookup_name);
        driver_lines{i}  = annotations{idx, 2};
        neuron_types{i}  = annotations{idx, 3};
        descriptions{i}  = annotations{idx, 4};
        roles{i}         = annotations{idx, 5};
        datasets{i}      = annotations{idx, 6};
    else
        warning('No annotation found for strain: %s', strain);
        driver_lines{i}  = 'UNKNOWN';
        neuron_types{i}  = 'UNKNOWN';
        descriptions{i}  = 'No annotation available';
        roles{i}         = 'UNKNOWN';
        datasets{i}      = 'unknown';
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
    datasets, ...
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
        'Dataset', ...
        'N_Cohorts', ...
        'N_Flies', ...
        'MeanFliesPerCohort', ...
        'MeanTemp_C', ...
        'MeanAge_hrs' ...
    });

%% 4 - Display and export

% Sort: dataset first (screen before norpA), then by role order
role_order = {'Control', 'Positive control', 'Negative control', ...
              'Screen hit', 'Screen', 'Replication', ...
              'NorpA control', 'NorpA rescue'};
[~, role_idx] = ismember(metadata_table.Role, role_order);
dataset_idx = double(strcmp(metadata_table.Dataset, 'norpA'));  % 0=screen, 1=norpA
[~, sort_order] = sortrows([dataset_idx, role_idx, (1:n_strains)']);
metadata_table = metadata_table(sort_order, :);

% Split for display
is_screen = strcmp(metadata_table.Dataset, 'screen');
screen_table = metadata_table(is_screen, :);
norpA_table  = metadata_table(~is_screen, :);

% Display in command window
disp('=== Screen Strains (Protocol 27) ===');
disp(screen_table);
fprintf('Screen strains: %d  |  Flies: %d  |  Cohorts: %d\n', ...
    height(screen_table), sum(screen_table.N_Flies), sum(screen_table.N_Cohorts));

if height(norpA_table) > 0
    fprintf('\n');
    disp('=== NorpA Strains (Protocol 27_Norp) ===');
    disp(norpA_table);
    fprintf('NorpA strains: %d  |  Flies: %d  |  Cohorts: %d\n', ...
        height(norpA_table), sum(norpA_table.N_Flies), sum(norpA_table.N_Cohorts));
end

fprintf('\nTotal strains: %d\n', n_strains);
fprintf('Total flies:   %d\n', sum(metadata_table.N_Flies));
fprintf('Total cohorts: %d\n', sum(metadata_table.N_Cohorts));

% Export to CSV
save_folder = fullfile(cfg.figures, 'FIGS');
if ~isfolder(save_folder)
    mkdir(save_folder);
end

output_file = fullfile(save_folder, 'strain_metadata_table.csv');
writetable(metadata_table, output_file);
fprintf('\nTable saved to: %s\n', output_file);

% Also save as .mat for reuse in other figure scripts
save(fullfile(save_folder, 'strain_metadata_table.mat'), ...
    'metadata_table', 'screen_table', 'norpA_table', 'annotations');
fprintf('MAT file saved to: %s\n', fullfile(save_folder, 'strain_metadata_table.mat'));
