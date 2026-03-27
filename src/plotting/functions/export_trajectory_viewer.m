function export_trajectory_viewer(DATA, condition, rep, varargin)
% EXPORT_TRAJECTORY_VIEWER  Generate a shareable HTML trajectory viewer.
%
%   export_trajectory_viewer(DATA, condition, rep)
%   export_trajectory_viewer(DATA, condition, rep, 'OutputFile', 'viewer.html')
%
%   Exports one condition (one rep) across selected strains in DATA as a
%   self-contained HTML file that can be opened in any modern browser.
%
%   INPUTS:
%     DATA      - struct from comb_data_across_cohorts_cond
%     condition - condition number (e.g. 1), or string like 'acclim_off1'
%     rep       - 1 or 2 (which replicate). Ignored for acclimation phases.
%
%   NAME-VALUE PAIRS:
%     'OutputFile'        - output path (default: auto-named in cfg.figures)
%     'Sex'               - 'F' (default), 'M', or 'both'
%     'Strains'           - cell array of strain names to include (default:
%                           all strains in DATA). Use this to reduce file size.
%     'TortuosityWindow'  - frames (default: 31, ~1 s at 30 fps)
%     'Downsample'        - integer factor to reduce frame count (default: 1)
%     'MaxFliesPerStrain' - max flies per strain (default: Inf)
%
%   EXAMPLE:
%     DATA = comb_data_across_cohorts_cond(fullfile(cfg.results, 'protocol_27'));
%     export_trajectory_viewer(DATA, 1, 1);
%     export_trajectory_viewer(DATA, 1, 1, 'Strains', {'jfrc100_es_shibire_kir'});
%     export_trajectory_viewer(DATA, 'acclim_off1', []);
%
% See also: trajectory_viewer_template, comb_data_across_cohorts_cond

%% Parse inputs
p = inputParser;
addRequired(p, 'DATA', @isstruct);
addRequired(p, 'condition');
addRequired(p, 'rep');
addParameter(p, 'OutputFile', '', @ischar);
addParameter(p, 'Sex', 'F', @ischar);
addParameter(p, 'Strains', {}, @iscell);
addParameter(p, 'TortuosityWindow', 31, @isnumeric);
addParameter(p, 'Downsample', 1, @isnumeric);
addParameter(p, 'MaxFliesPerStrain', Inf, @isnumeric);
parse(p, DATA, condition, rep, varargin{:});

tort_window = p.Results.TortuosityWindow;
sex_list = p.Results.Sex;
output_file = p.Results.OutputFile;
ds = max(1, round(p.Results.Downsample));
max_flies = p.Results.MaxFliesPerStrain;

% Build condition field name
if ischar(condition) || isstring(condition)
    cond_field = char(condition);
    is_acclim = true;
    cond_label = cond_field;
else
    is_acclim = false;
    if rep == 1
        cond_field = strcat('R1_condition_', string(condition));
    else
        cond_field = strcat('R2_condition_', string(condition));
    end
    cond_label = char(cond_field);
end

% Default output file
if isempty(output_file)
    default_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/html_files/trajectories';
    if ~isfolder(default_dir)
        mkdir(default_dir);
    end
    if is_acclim
        fname = sprintf('trajectory_viewer_%s.html', cond_field);
    else
        fname = sprintf('trajectory_viewer_cond%d_R%d.html', condition, rep);
    end
    output_file = fullfile(default_dir, fname);
end

% Sex selection
if strcmpi(sex_list, 'both')
    sexes = {'F', 'M'};
else
    sexes = {sex_list};
end

% Strain selection
all_strains = fieldnames(DATA);
if ~isempty(p.Results.Strains)
    all_strains = intersect(all_strains, p.Results.Strains, 'stable');
    if isempty(all_strains)
        error('None of the specified strains found in DATA.');
    end
end

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

%% Collect all fly data
flies_json = {};
fly_count = 0;

for s_idx = 1:numel(all_strains)
    strain = all_strains{s_idx};
    strain_fly_count = 0;

    for sex_idx = 1:numel(sexes)
        sex = sexes{sex_idx};

        if ~isfield(DATA.(strain), sex)
            continue;
        end

        cohorts = DATA.(strain).(sex);
        n_exp = numel(cohorts);

        % Find minimum frame count for this strain
        min_frames = Inf;
        for idx = 1:n_exp
            if isfield(cohorts(idx), cond_field) && ~isempty(cohorts(idx).(cond_field))
                nf = size(cohorts(idx).(cond_field).x_data, 2);
                min_frames = min(min_frames, nf);
            end
        end
        if isinf(min_frames), continue; end

        % Apply downsampling to frame count
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

            if ~is_acclim && isfield(cond_data, 'optomotor_pattern')
                cond_label_str = sprintf('Pat%d Spd%d %ds', ...
                    cond_data.optomotor_pattern, ...
                    cond_data.optomotor_speed, ...
                    cond_data.trial_len);
            else
                cond_label_str = cond_label;
            end

            % Phase boundaries (adjusted for downsampling)
            %
            % framesb4 = 300: data starts 300 frames before CW onset.
            % trial_len = per-direction stimulus duration (seconds).
            % start_flicker_f = offset to post-stimulus interval onset.
            %
            %   CW onset  = framesb4 = 300
            %   CCW onset = 300 + trial_len * FPS
            %   Stim end  = start_flicker_f (interval onset)
            if ~is_acclim && isfield(cond_data, 'start_flicker_f')
                cw_start  = round(300 / ds);
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

                % Tortuosity (on full-res data, then subsample)
                tort = compute_tortuosity(x, y, tort_window, FPS);

                % Subsample and round to minimum useful precision
                % Positions: 1 dp (0.1 mm). Angles: integer (1 deg).
                % Velocities: fv 1 dp, av integer. Distances: 1 dp.
                % Tortuosity: 1 dp. This reduces JSON char count ~30%.
                x   = round(x(frame_idx), 1);
                y   = round(y(frame_idx), 1);
                hw  = round(hw(frame_idx));       % degrees → integer
                fv  = round(fv(frame_idx), 1);
                av  = round(av(frame_idx));        % deg/s → integer
                d   = round(d(frame_idx), 1);
                vd  = round(vd(frame_idx), 1);
                ang_diff = round(ang_diff(frame_idx));  % degrees → integer
                tort = round(tort(frame_idx), 1);

                % Build fly entry
                fly_count = fly_count + 1;
                strain_fly_count = strain_fly_count + 1;
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

                flies_json{fly_count} = fly_entry; %#ok<AGROW>
            end
        end
    end
    fprintf('  %s: %d flies\n', strain, strain_fly_count);
end

fprintf('Collected %d fly observations across %d strains.\n', fly_count, numel(all_strains));

if fly_count == 0
    error('No valid fly data found for condition %s.', cond_label);
end

%% Build JSON
json_struct = struct();
json_struct.meta = struct();
json_struct.meta.fps = FPS / ds;
json_struct.meta.arena = struct('cx', round(ARENA_CX, 1), 'cy', round(ARENA_CY, 1), 'r', ARENA_R);
json_struct.meta.condition = cond_label;
json_struct.flies = [flies_json{:}];

json_str = jsonencode(json_struct);

% Fix NaN → null for all MATLAB versions
json_str = strrep(json_str, 'NaN', 'null');

% Strip trailing ".0" from integer-valued numbers to save ~15-20% chars.
% e.g. "120.0," → "120,"  and "120.0]" → "120]"
json_str = regexprep(json_str, '\.0([,\]\}])', '$1');

%% Assemble HTML
html_template = trajectory_viewer_template();
html_out = strrep(html_template, '/*__DATA__*/', json_str);

%% Write file
fid = fopen(output_file, 'w', 'n', 'UTF-8');
if fid == -1
    error('Cannot open output file: %s', output_file);
end
fwrite(fid, html_out, 'char');
fclose(fid);

% Report
file_info = dir(output_file);
size_mb = file_info.bytes / 1e6;
fprintf('Written: %s (%.1f MB, %d flies)\n', output_file, size_mb, fly_count);
if size_mb > 20
    warning(['File is %.1f MB — may load slowly in the browser.\n' ...
             'Tips to reduce size:\n' ...
             '  - ''Strains'', {''strain1'', ''strain2''} — export fewer strains\n' ...
             '  - ''MaxFliesPerStrain'', 50 — cap flies per strain\n' ...
             '  - ''Downsample'', 2 — halve the frame count'], size_mb);
end

end

%% Helper: extract string from metadata field (handles char, string, datetime)
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
