%% test_pipeline_simple.m
% Simple comparison test

PROJECT_ROOT = '/Users/burnettl/Documents/GitHub/freely-walking-optomotor';
addpath(genpath(fullfile(PROJECT_ROOT, 'processing_functions')));
addpath(fullfile(PROJECT_ROOT, '.archive', 'processing_functions', 'functions'));

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_27';
strain_to_test = 'jfrc100_es_shibire_kir';
sex_to_test = 'F';

% Run original pipeline
fprintf('\n=== Running ORIGINAL pipeline ===\n');
original_func_path = fullfile(PROJECT_ROOT, '.archive', 'processing_functions', 'functions', 'comb_data_across_cohorts_cond.m');
orig_code = fileread(original_func_path);
temp_func = fullfile(tempdir, 'comb_data_across_cohorts_cond_ORIGINAL.m');
fid = fopen(temp_func, 'w');
fprintf(fid, '%s', strrep(orig_code, 'function DATA = comb_data_across_cohorts_cond(', 'function DATA = comb_data_across_cohorts_cond_ORIGINAL('));
fclose(fid);
addpath(tempdir);

tic;
DATA_original = comb_data_across_cohorts_cond_ORIGINAL(protocol_dir);
time_original = toc;
fprintf('Original pipeline completed in %.2f seconds\n', time_original);

% Run new pipeline
fprintf('\n=== Running NEW pipeline ===\n');
tic;
DATA_new = comb_data_across_cohorts_cond(protocol_dir);
time_new = toc;
fprintf('New pipeline completed in %.2f seconds\n', time_new);

% Compare top-level fields
fprintf('\n=== STRUCTURE COMPARISON ===\n');
fields_original = fieldnames(DATA_original);
fields_new = fieldnames(DATA_new);
fprintf('Original: %d fields\n', length(fields_original));
fprintf('New: %d fields\n', length(fields_new));

new_top_fields = setdiff(fields_new, fields_original);
fprintf('\nNEW top-level fields: ');
for i = 1:length(new_top_fields)
    fprintf('%s ', new_top_fields{i});
end
fprintf('\n');

% Get strain data
exp_original = DATA_original.(strain_to_test).(sex_to_test);
exp_new = DATA_new.(strain_to_test).(sex_to_test);
fprintf('Number of experiments - Original: %d, New: %d\n', length(exp_original), length(exp_new));

% Compare behavioral data
behavioral_fields = {'vel_data', 'fv_data', 'av_data', 'curv_data', 'dist_data', ...
                     'dist_trav', 'heading_data', 'heading_wrap', 'x_data', 'y_data', ...
                     'view_dist', 'IFD_data', 'IFA_data'};

conditions_to_check = {'R1_condition_1', 'R2_condition_1'};
acclim_periods = {'acclim_off1', 'acclim_patt', 'acclim_off2'};

total_checks = 0;
total_matches = 0;
total_mismatches = 0;
mismatch_details = {};

n_exp = min(length(exp_original), length(exp_new));

for exp_idx = 1:n_exp
    for a = 1:length(acclim_periods)
        period = acclim_periods{a};
        if isfield(exp_original(exp_idx), period) && isfield(exp_new(exp_idx), period)
            for f = 1:length(behavioral_fields)
                field = behavioral_fields{f};
                if isfield(exp_original(exp_idx).(period), field) && isfield(exp_new(exp_idx).(period), field)
                    data_orig = exp_original(exp_idx).(period).(field);
                    data_new = exp_new(exp_idx).(period).(field);
                    total_checks = total_checks + 1;
                    if isequal(size(data_orig), size(data_new))
                        max_diff = max(abs(data_orig(:) - data_new(:)));
                        if max_diff < 1e-10
                            total_matches = total_matches + 1;
                        else
                            total_mismatches = total_mismatches + 1;
                            mismatch_details{end+1} = sprintf('Exp %d, %s.%s: max_diff=%.2e', exp_idx, period, field, max_diff);
                        end
                    else
                        total_mismatches = total_mismatches + 1;
                        mismatch_details{end+1} = sprintf('Exp %d, %s.%s: size mismatch', exp_idx, period, field);
                    end
                end
            end
        end
    end

    for c = 1:length(conditions_to_check)
        cond = conditions_to_check{c};
        if isfield(exp_original(exp_idx), cond) && isfield(exp_new(exp_idx), cond)
            for f = 1:length(behavioral_fields)
                field = behavioral_fields{f};
                if isfield(exp_original(exp_idx).(cond), field) && isfield(exp_new(exp_idx).(cond), field)
                    data_orig = exp_original(exp_idx).(cond).(field);
                    data_new = exp_new(exp_idx).(cond).(field);
                    total_checks = total_checks + 1;
                    if isequal(size(data_orig), size(data_new))
                        max_diff = max(abs(data_orig(:) - data_new(:)));
                        if max_diff < 1e-10
                            total_matches = total_matches + 1;
                        else
                            total_mismatches = total_mismatches + 1;
                            mismatch_details{end+1} = sprintf('Exp %d, %s.%s: max_diff=%.2e', exp_idx, cond, field, max_diff);
                        end
                    else
                        total_mismatches = total_mismatches + 1;
                        mismatch_details{end+1} = sprintf('Exp %d, %s.%s: size mismatch', exp_idx, cond, field);
                    end
                end
            end
        end
    end
end

fprintf('\n=== SUMMARY ===\n');
fprintf('Total behavioral data comparisons: %d\n', total_checks);
fprintf('Matches: %d (%.1f%%)\n', total_matches, 100*total_matches/total_checks);
fprintf('Mismatches: %d (%.1f%%)\n', total_mismatches, 100*total_mismatches/total_checks);

if total_mismatches > 0
    fprintf('\n--- Mismatch Details (first 10) ---\n');
    for i = 1:min(10, length(mismatch_details))
        fprintf('  %s\n', mismatch_details{i});
    end
end

fprintf('\n=== NEW FEATURES ===\n');
fprintf('New DATA struct has _metadata: %d\n', isfield(DATA_new, '_metadata'));
fprintf('New DATA struct has _pattern_lut: %d\n', isfield(DATA_new, '_pattern_lut'));
fprintf('Condition has phase_markers: %d\n', isfield(exp_new(1).R1_condition_1, 'phase_markers'));
fprintf('Condition has pattern_meta: %d\n', isfield(exp_new(1).R1_condition_1, 'pattern_meta'));

delete(temp_func);
rmpath(tempdir);
fprintf('\n=== TEST COMPLETE ===\n');
