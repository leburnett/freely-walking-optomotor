function export_trajectory_data(DATA, varargin)
% EXPORT_TRAJECTORY_DATA  Export per-strain JSON files and an HTML viewer.
%
%   export_trajectory_data(DATA)
%   export_trajectory_data(DATA, 'Strains', {'Dm4', 'TmY3'})
%
%   Exports trajectory data as lightweight per-strain JSON files, plus
%   an empty HTML viewer. Users open the viewer and drag-and-drop JSON
%   files to load data interactively.
%
%   INPUTS:
%     DATA - struct from comb_data_across_cohorts_cond (all conditions).
%
%   NAME-VALUE PAIRS:
%     'OutputDir'         - directory for JSON files and viewer HTML
%                           (default: ~/Documents/Projects/oaky_cokey/html_files/trajectories)
%     'Sex'               - 'F' (default), 'M', or 'both'
%     'Strains'           - cell array of substrings to match (case-insensitive)
%     'Conditions'        - numeric array of conditions [1 2 3 ...] (default: all)
%     'Reps'              - which reps to include: 1, 2, or [1 2] (default: 1)
%     'IncludeAcclim'     - include acclimation phases (default: false)
%     'TortuosityWindow'  - frames (default: 31, ~1 s at 30 fps)
%     'Downsample'        - integer factor to reduce frame count (default: 1)
%     'MaxFliesPerStrain' - max flies per strain (default: Inf)
%
%   EXAMPLE:
%     DATA = comb_data_across_cohorts_cond(fullfile(cfg.results, 'protocol_27'));
%     export_trajectory_data(DATA);
%     export_trajectory_data(DATA, 'Strains', {'Dm4', 'es'}, 'Conditions', [1 2 3]);
%
% See also: trajectory_viewer_template, comb_data_across_cohorts_cond

%% Parse inputs
p = inputParser;
addRequired(p, 'DATA', @isstruct);
addParameter(p, 'OutputDir', '', @ischar);
addParameter(p, 'Sex', 'F', @ischar);
addParameter(p, 'Strains', {}, @iscell);
addParameter(p, 'Conditions', [], @isnumeric);
addParameter(p, 'Reps', 1, @isnumeric);
addParameter(p, 'IncludeAcclim', false, @islogical);
addParameter(p, 'TortuosityWindow', 31, @isnumeric);
addParameter(p, 'Downsample', 1, @isnumeric);
addParameter(p, 'MaxFliesPerStrain', Inf, @isnumeric);
parse(p, DATA, varargin{:});

tort_window = p.Results.TortuosityWindow;
sex_list = p.Results.Sex;
ds = max(1, round(p.Results.Downsample));
max_flies = p.Results.MaxFliesPerStrain;
reps = p.Results.Reps;
include_acclim = p.Results.IncludeAcclim;

output_dir = p.Results.OutputDir;
if isempty(output_dir)
    output_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/html_files/trajectories';
end
if ~isfolder(output_dir)
    mkdir(output_dir);
end
data_dir = fullfile(output_dir, 'data');
if ~isfolder(data_dir)
    mkdir(data_dir);
end

% Sex selection
if strcmpi(sex_list, 'both')
    sexes = {'F', 'M'};
else
    sexes = {sex_list};
end

% Strain selection — substring matching
all_strains = fieldnames(DATA);
if ~isempty(p.Results.Strains)
    patterns = p.Results.Strains;
    match_mask = false(size(all_strains));
    for si = 1:numel(all_strains)
        for pi = 1:numel(patterns)
            if contains(all_strains{si}, patterns{pi}, 'IgnoreCase', true)
                match_mask(si) = true;
                break;
            end
        end
    end
    all_strains = all_strains(match_mask);
    if isempty(all_strains)
        error('No strains matched patterns: %s', strjoin(patterns, ', '));
    end
    fprintf('Matched %d strains: %s\n', numel(all_strains), strjoin(all_strains, ', '));
end

%% Discover available condition fields
% Inspect the first strain to discover condition fields
sample_strain = all_strains{1};
for sx = {'F','M'}
    if isfield(DATA.(sample_strain), sx{1})
        sample_cohort = DATA.(sample_strain).(sx{1});
        break;
    end
end
all_fields = fieldnames(sample_cohort);
cond_fields = {};
cond_labels = {};

% Add R1/R2 conditions
for r = reps(:)'
    prefix = sprintf('R%d_condition_', r);
    matches = all_fields(startsWith(all_fields, prefix));
    % Filter by requested conditions
    if ~isempty(p.Results.Conditions)
        keep = false(size(matches));
        for ci = 1:numel(matches)
            num = str2double(extractAfter(matches{ci}, prefix));
            keep(ci) = ismember(num, p.Results.Conditions);
        end
        matches = matches(keep);
    end
    cond_fields = [cond_fields; matches]; %#ok<AGROW>
    for ci = 1:numel(matches)
        cond_labels = [cond_labels; {matches{ci}}]; %#ok<AGROW>
    end
end

% Add acclimation phases if requested
if include_acclim
    acclim_fields = all_fields(startsWith(all_fields, 'acclim'));
    cond_fields = [cond_fields; acclim_fields];
    for ci = 1:numel(acclim_fields)
        cond_labels = [cond_labels; acclim_fields(ci)]; %#ok<AGROW>
    end
end

fprintf('Exporting %d conditions: %s\n', numel(cond_fields), strjoin(cond_fields, ', '));

%% Constants
VEL_THRESHOLD   = 0.5;   % mm/s
QUIESCENCE_FRAC = 0.75;
DIST_THRESHOLD  = 110;   % mm from center
FPS = 30;
dt = 1 / FPS;
FLIP_THRESHOLD = 90;
ARENA_CX = 520 / 4.1691;
ARENA_CY = 520 / 4.1691;
ARENA_R  = 120;
FRAMESB4 = 300;

%% Export per-strain JSON files
total_flies = 0;
file_count = 0;

for s_idx = 1:numel(all_strains)
    strain = all_strains{s_idx};
    strain_flies = {};
    strain_fly_count = 0;
    strain_conditions = {};  % track which conditions have data

    for c_idx = 1:numel(cond_fields)
        cond_field = cond_fields{c_idx};
        is_acclim = startsWith(cond_field, 'acclim');

        cond_fly_count = 0;

        for sex_idx = 1:numel(sexes)
            sex = sexes{sex_idx};
            if ~isfield(DATA.(strain), sex)
                continue;
            end

            cohorts = DATA.(strain).(sex);
            n_exp = numel(cohorts);

            % Find minimum frame count for this condition
            min_frames = Inf;
            for idx = 1:n_exp
                if isfield(cohorts(idx), cond_field) && ~isempty(cohorts(idx).(cond_field))
                    nf = size(cohorts(idx).(cond_field).x_data, 2);
                    min_frames = min(min_frames, nf);
                end
            end
            if isinf(min_frames), continue; end

            frame_idx = 1:ds:min_frames;
            nf_out = numel(frame_idx);

            for idx = 1:n_exp
                if strain_fly_count >= max_flies, break; end
                if ~isfield(cohorts(idx), cond_field) || isempty(cohorts(idx).(cond_field))
                    continue;
                end

                cond_data = cohorts(idx).(cond_field);
                meta = cohorts(idx).meta;
                n_flies = size(cond_data.x_data, 1);

                fly_date = extract_meta_string(meta, 'date');
                fly_time = extract_meta_string(meta, 'time');

                % Build condition label
                if ~is_acclim && isfield(cond_data, 'optomotor_pattern')
                    cond_label_str = sprintf('Pat%d Spd%d %ds', ...
                        cond_data.optomotor_pattern, ...
                        cond_data.optomotor_speed, ...
                        cond_data.trial_len);
                else
                    cond_label_str = cond_field;
                end

                % Phase boundaries
                if ~is_acclim && isfield(cond_data, 'start_flicker_f')
                    cw_start  = round(FRAMESB4 / ds);
                    dir_frames = round(cond_data.trial_len * FPS / ds);
                    ccw_start = cw_start + dir_frames;
                    stim_end  = round(cond_data.start_flicker_f / ds);
                    phases = [cw_start, ccw_start, stim_end];
                else
                    phases = [nf_out, nf_out, nf_out];
                end

                for f = 1:n_flies
                    if strain_fly_count >= max_flies, break; end

                    x   = cond_data.x_data(f, 1:min_frames);
                    y   = cond_data.y_data(f, 1:min_frames);
                    hw  = cond_data.heading_wrap(f, 1:min_frames);
                    fv  = cond_data.fv_data(f, 1:min_frames);
                    av  = cond_data.av_data(f, 1:min_frames);
                    d   = cond_data.dist_data(f, 1:min_frames);
                    vd  = cond_data.view_dist(f, 1:min_frames);
                    vel = cond_data.vel_data(f, 1:min_frames);

                    % QC
                    if sum(vel < VEL_THRESHOLD) / min_frames > QUIESCENCE_FRAC
                        continue;
                    end
                    if min(d) > DIST_THRESHOLD
                        continue;
                    end

                    % Angular difference (heading vs travelling)
                    vxv = zeros(1, min_frames);
                    vyv = zeros(1, min_frames);
                    vxv(1)       = (x(2) - x(1)) / dt;
                    vyv(1)       = (y(2) - y(1)) / dt;
                    vxv(2:end-1) = (x(3:end) - x(1:end-2)) / (2 * dt);
                    vyv(2:end-1) = (y(3:end) - y(1:end-2)) / (2 * dt);
                    vxv(end)     = (x(end) - x(end-1)) / dt;
                    vyv(end)     = (y(end) - y(end-1)) / dt;
                    travel_dir = atan2d(vyv, vxv);

                    % Head-tail flip detection
                    ang_diff_raw = mod(hw - travel_dir + 180, 360) - 180;
                    speed_mask = vel >= VEL_THRESHOLD & ~isnan(ang_diff_raw);
                    if sum(speed_mask) > 50
                        median_diff = mean(abs(ang_diff_raw(speed_mask)), 'omitnan');
                        if median_diff > FLIP_THRESHOLD
                            hw = mod(hw + 180, 360);
                        end
                    end
                    ang_diff = mod(hw - travel_dir + 180, 360) - 180;
                    ang_diff(vel < VEL_THRESHOLD) = NaN;

                    % Tortuosity
                    tort = compute_tortuosity(x, y, tort_window, FPS);

                    % Subsample & round for compactness
                    x   = round(x(frame_idx), 1);
                    y   = round(y(frame_idx), 1);
                    hw  = round(hw(frame_idx));
                    fv  = round(fv(frame_idx), 1);
                    av  = round(av(frame_idx));
                    d   = round(d(frame_idx), 1);
                    vd  = round(vd(frame_idx), 1);
                    ang_diff = round(ang_diff(frame_idx));
                    tort = round(tort(frame_idx), 1);

                    fly_entry = struct();
                    fly_entry.strain    = strain;
                    fly_entry.date      = fly_date;
                    fly_entry.time      = fly_time;
                    fly_entry.condition = char(cond_field);
                    fly_entry.condLabel = cond_label_str;
                    fly_entry.flyIdx    = f;
                    fly_entry.nFrames   = nf_out;
                    fly_entry.phases    = phases;
                    fly_entry.x    = x;
                    fly_entry.y    = y;
                    fly_entry.h    = hw;
                    fly_entry.fv   = fv;
                    fly_entry.av   = av;
                    fly_entry.d    = d;
                    fly_entry.vd   = vd;
                    fly_entry.ad   = ang_diff;
                    fly_entry.tort = tort;

                    strain_fly_count = strain_fly_count + 1;
                    cond_fly_count = cond_fly_count + 1;
                    strain_flies{end+1} = fly_entry; %#ok<AGROW>
                end
            end
        end

        if cond_fly_count > 0
            strain_conditions{end+1} = cond_field; %#ok<AGROW>
        end
    end

    if strain_fly_count == 0
        fprintf('  %s: 0 flies (skipped)\n', strain);
        continue;
    end

    % Build per-strain JSON
    json_struct = struct();
    json_struct.meta = struct();
    json_struct.meta.fps = FPS / ds;
    json_struct.meta.arena = struct('cx', round(ARENA_CX, 1), ...
                                    'cy', round(ARENA_CY, 1), ...
                                    'r', ARENA_R);
    json_struct.meta.conditions = strain_conditions;
    json_struct.flies = [strain_flies{:}];

    json_str = jsonencode(json_struct);
    json_str = strrep(json_str, 'NaN', 'null');
    json_str = regexprep(json_str, '\.0([,\]\}])', '$1');

    % Write JSON file
    safe_name = regexprep(strain, '[^a-zA-Z0-9_]', '_');
    json_file = fullfile(data_dir, [safe_name '.json']);
    fid = fopen(json_file, 'w', 'n', 'UTF-8');
    fwrite(fid, json_str, 'char');
    fclose(fid);

    file_info = dir(json_file);
    fprintf('  %s: %d flies, %d conditions (%.1f MB)\n', ...
        strain, strain_fly_count, numel(strain_conditions), file_info.bytes/1e6);

    total_flies = total_flies + strain_fly_count;
    file_count = file_count + 1;
end

%% Write empty viewer HTML
html_template = trajectory_viewer_template();
viewer_file = fullfile(output_dir, 'trajectory_viewer.html');
fid = fopen(viewer_file, 'w', 'n', 'UTF-8');
fwrite(fid, html_template, 'char');
fclose(fid);

fprintf('\n=== Export complete ===\n');
fprintf('  Viewer:  %s\n', viewer_file);
fprintf('  Data:    %s/ (%d files, %d total flies)\n', data_dir, file_count, total_flies);
fprintf('\nOpen the viewer in a browser and drag-and-drop JSON files to load data.\n');

end

%% Helper: extract string from metadata field
function val = extract_meta_string(meta, field)
    if ~isfield(meta, field)
        val = 'unknown';
        return;
    end
    v = meta.(field);
    if ischar(v)
        val = v;
    elseif isstring(v)
        val = char(v);
    elseif isdatetime(v)
        if strcmp(field, 'date')
            val = char(v, 'yyyy-MM-dd');
        else
            val = char(v, 'HH-mm-ss');
        end
    else
        val = 'unknown';
    end
end
