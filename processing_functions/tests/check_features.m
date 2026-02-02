PROJECT_ROOT = '/Users/burnettl/Documents/GitHub/freely-walking-optomotor';
addpath(genpath(fullfile(PROJECT_ROOT, 'processing_functions')));

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_27';

fprintf('Running new pipeline...\n');
DATA_new = comb_data_across_cohorts_cond(protocol_dir);

fprintf('\n=== NEW FEATURES CHECK ===\n');
fprintf('Has _metadata: %d\n', isfield(DATA_new, '_metadata'));
fprintf('Has _pattern_lut: %d\n', isfield(DATA_new, '_pattern_lut'));

if isfield(DATA_new, '_metadata')
    fprintf('_metadata fields:\n');
    disp(fieldnames(DATA_new._metadata));
end

strain = 'jfrc100_es_shibire_kir';
exp = DATA_new.(strain).F(1);
cond = exp.R1_condition_1;

fprintf('Has phase_markers: %d\n', isfield(cond, 'phase_markers'));
fprintf('Has pattern_meta: %d\n', isfield(cond, 'pattern_meta'));

if isfield(cond, 'phase_markers')
    fprintf('phase_markers fields:\n');
    disp(fieldnames(cond.phase_markers));
end
