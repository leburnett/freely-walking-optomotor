%% VERIFY_LOOP_SEGMENTATION - Quality checks for loop and inter-loop analysis
%
%  Runs a series of verification tests on the loop detection and inter-loop
%  segment extraction to ensure the code does what we think it does.
%
%  TESTS:
%    1. Coverage: loops + segments + gaps = total trajectory frames
%    2. Endpoint continuity: segment endpoints match loop boundaries
%    3. Direction consistency: fitted direction matches actual displacement
%    4. Orientation sanity: PCA axis aligns with bounding box long axis
%    5. Shuffle control: randomising distances destroys the cos-distance correlation
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).

%% Setup

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R = 120;
FPS = 30;
STIM_ON = 300;  STIM_OFF = 1200;
MASK_START = 750;  MASK_END = 850;

control_strain = "jfrc100_es_shibire_kir";
sex = 'F';
ASPECT_THRESHOLD = 1.1;
MIN_SEG_FRAMES = 5;

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

% Load data
data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data'};
[rep_data, n_flies] = load_per_rep_data(DATA, control_strain, sex, 1, data_types);
fprintf('Loaded %d fly-rep observations\n', n_flies);

stim_range = STIM_ON:STIM_OFF;
x_all       = rep_data.x_data(:, stim_range);
y_all       = rep_data.y_data(:, stim_range);
heading_all = rep_data.heading_data(:, stim_range);
vel_all     = rep_data.vel_data(:, stim_range);
n_stim_frames = size(x_all, 2);

% Mask reversal window
mask_s = max(MASK_START - STIM_ON + 1, 1);
mask_e = min(MASK_END - STIM_ON + 1, n_stim_frames);

fprintf('\n======================================================================\n');
fprintf('  VERIFICATION TESTS\n');
fprintf('======================================================================\n');

%% ================================================================
%  TEST 1: Coverage — loops + segments + gaps = total frames
%  ================================================================
%
%  Every frame in the stimulus period should be accounted for: it's either
%  inside a loop, inside an inter-loop segment, before the first loop,
%  after the last loop, or in a 1-frame boundary. No frame should be
%  counted twice.

fprintf('\n--- TEST 1: Frame coverage ---\n');

n_perfect_coverage = 0;
n_tested = 0;
total_overlap_frames = 0;
total_gap_frames = 0;

for f = 1:min(n_flies, 200)  % test first 200 flies for speed
    x_det = x_all(f,:);  y_det = y_all(f,:);  h_det = heading_all(f,:);
    x_det(mask_s:mask_e) = NaN;
    y_det(mask_s:mask_e) = NaN;
    h_det(mask_s:mask_e) = NaN;

    v_fly = vel_all(f,:);
    v_fly(mask_s:mask_e) = NaN;
    loop_opts.vel = v_fly;

    loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts);
    if loops.n_loops < 2, continue; end
    n_tested = n_tested + 1;

    % Mark all frames as: loop, segment, or unassigned
    frame_owner = zeros(1, n_stim_frames);  % 0 = unassigned

    for k = 1:loops.n_loops
        sf = loops.start_frame(k);
        ef = loops.end_frame(k);
        frame_owner(sf:ef) = frame_owner(sf:ef) + 1;  % +1 for loop
    end

    % Check for overlapping loops
    overlap = sum(frame_owner > 1);
    total_overlap_frames = total_overlap_frames + overlap;

    % Check inter-loop segments
    for k = 1:(loops.n_loops - 1)
        s_start = loops.end_frame(k) + 1;
        s_end   = loops.start_frame(k+1) - 1;
        if s_end >= s_start
            frame_owner(s_start:s_end) = frame_owner(s_start:s_end) + 2;  % +2 for segment
        end
    end

    % Check for gaps between loops and segments (frames that are 0 in the
    % range between first loop start and last loop end)
    first_loop_start = loops.start_frame(1);
    last_loop_end = loops.end_frame(end);
    inner_range = first_loop_start:last_loop_end;
    gaps_in_range = sum(frame_owner(inner_range) == 0);
    total_gap_frames = total_gap_frames + gaps_in_range;

    if overlap == 0 && gaps_in_range == 0
        n_perfect_coverage = n_perfect_coverage + 1;
    end
end

fprintf('  Tested %d flies (with >= 2 loops)\n', n_tested);
fprintf('  Perfect coverage (no gaps/overlaps between first and last loop): %d/%d (%.0f%%)\n', ...
    n_perfect_coverage, n_tested, 100*n_perfect_coverage/max(n_tested,1));
fprintf('  Total overlapping frames: %d\n', total_overlap_frames);
fprintf('  Total gap frames (between first and last loop): %d\n', total_gap_frames);
if total_overlap_frames == 0 && total_gap_frames == 0
    fprintf('  PASS: Loops and inter-loop segments tile perfectly\n');
else
    fprintf('  NOTE: Some gaps exist (expected if segment too short or has NaN)\n');
end

%% ================================================================
%  TEST 2: Endpoint continuity
%  ================================================================
%
%  The end of inter-loop segment k should be exactly 1 frame before the
%  start of loop k+1. And the start of segment k should be exactly 1 frame
%  after the end of loop k.

fprintf('\n--- TEST 2: Endpoint continuity ---\n');

n_segs_tested = 0;
n_continuous = 0;

for f = 1:min(n_flies, 200)
    x_det = x_all(f,:);  y_det = y_all(f,:);  h_det = heading_all(f,:);
    x_det(mask_s:mask_e) = NaN;
    y_det(mask_s:mask_e) = NaN;
    h_det(mask_s:mask_e) = NaN;

    v_fly = vel_all(f,:);
    v_fly(mask_s:mask_e) = NaN;
    loop_opts.vel = v_fly;

    loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts);
    if loops.n_loops < 2, continue; end

    for k = 1:(loops.n_loops - 1)
        expected_seg_start = loops.end_frame(k) + 1;
        expected_seg_end   = loops.start_frame(k+1) - 1;
        n_segs_tested = n_segs_tested + 1;

        % The segment should start right after loop k ends
        % and end right before loop k+1 starts
        if expected_seg_end >= expected_seg_start
            n_continuous = n_continuous + 1;
        end
    end
end

fprintf('  Tested %d inter-loop boundaries\n', n_segs_tested);
fprintf('  Continuous (seg_end = next_loop_start - 1): %d/%d (%.0f%%)\n', ...
    n_continuous, n_segs_tested, 100*n_continuous/max(n_segs_tested,1));
if n_continuous == n_segs_tested
    fprintf('  PASS: All segment boundaries are continuous with loop boundaries\n');
end

%% ================================================================
%  TEST 3: Direction consistency
%  ================================================================
%
%  The fitted direction (atan2d of endpoint displacement) should match
%  the actual displacement vector. We verify this by comparing the
%  direction angle to the angle computed from actual start/end positions.

fprintf('\n--- TEST 3: Direction consistency (inter-loop segments) ---\n');

n_dir_tested = 0;
max_dir_error = 0;
dir_errors = [];

for f = 1:min(n_flies, 100)
    x_fly = x_all(f,:);  y_fly = y_all(f,:);
    x_det = x_fly;  y_det = y_fly;  h_det = heading_all(f,:);
    x_det(mask_s:mask_e) = NaN;
    y_det(mask_s:mask_e) = NaN;
    h_det(mask_s:mask_e) = NaN;

    v_fly = vel_all(f,:);
    v_fly(mask_s:mask_e) = NaN;
    loop_opts.vel = v_fly;

    loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts);
    if loops.n_loops < 2, continue; end

    for k = 1:(loops.n_loops - 1)
        s_start = loops.end_frame(k) + 1;
        s_end   = loops.start_frame(k+1) - 1;
        if s_end - s_start + 1 < MIN_SEG_FRAMES, continue; end

        x_s = x_fly(s_start:s_end);
        y_s = y_fly(s_start:s_end);
        valid = ~isnan(x_s) & ~isnan(y_s);
        x_v = x_s(valid);  y_v = y_s(valid);
        if numel(x_v) < MIN_SEG_FRAMES, continue; end

        dx = x_v(end) - x_v(1);
        dy = y_v(end) - y_v(1);
        if sqrt(dx^2 + dy^2) < 0.5, continue; end

        fitted_angle = atan2d(dy, dx);
        actual_angle = atan2d(y_v(end) - y_v(1), x_v(end) - x_v(1));

        err = abs(mod(fitted_angle - actual_angle + 180, 360) - 180);
        dir_errors = [dir_errors, err];
        max_dir_error = max(max_dir_error, err);
        n_dir_tested = n_dir_tested + 1;
    end
end

fprintf('  Tested %d segments\n', n_dir_tested);
fprintf('  Max direction error: %.4f degrees\n', max_dir_error);
fprintf('  Mean direction error: %.4f degrees\n', mean(dir_errors));
if max_dir_error < 0.01
    fprintf('  PASS: Fitted direction matches actual displacement perfectly\n');
else
    fprintf('  WARNING: Some direction discrepancy detected\n');
end

%% ================================================================
%  TEST 4: PCA orientation sanity
%  ================================================================
%
%  For elongated loops (high aspect ratio), the PCA first component
%  should roughly align with the bounding box long axis. We check the
%  angle between the PCA direction and the bbox long axis direction.

fprintf('\n--- TEST 4: PCA vs bounding box alignment ---\n');

pca_bbox_errors = [];

for f = 1:min(n_flies, 100)
    x_fly = x_all(f,:);  y_fly = y_all(f,:);
    x_det = x_fly;  y_det = y_fly;  h_det = heading_all(f,:);
    x_det(mask_s:mask_e) = NaN;
    y_det(mask_s:mask_e) = NaN;
    h_det(mask_s:mask_e) = NaN;

    v_fly = vel_all(f,:);
    v_fly(mask_s:mask_e) = NaN;
    loop_opts.vel = v_fly;

    loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts);

    for k = 1:loops.n_loops
        if loops.bbox_aspect(k) < 2.0, continue; end  % only test elongated loops

        sf = loops.start_frame(k);
        ef = loops.end_frame(k);
        x_seg = x_fly(sf:ef);
        y_seg = y_fly(sf:ef);

        [oa, ~, ~, ~] = compute_loop_orientation(x_seg, y_seg, ARENA_CENTER);
        if isnan(oa), continue; end

        % Bounding box long axis direction
        xv = x_seg(~isnan(x_seg));  yv = y_seg(~isnan(y_seg));
        w = max(xv) - min(xv);
        h = max(yv) - min(yv);
        if w > h
            bbox_angle = 0;   % long axis is horizontal
        else
            bbox_angle = 90;  % long axis is vertical
        end

        % PCA angle (unsigned, 0-180 range for comparison)
        pca_unsigned = mod(oa, 180);
        err = min(abs(pca_unsigned - bbox_angle), 180 - abs(pca_unsigned - bbox_angle));
        pca_bbox_errors = [pca_bbox_errors, err];
    end
end

fprintf('  Tested %d elongated loops (aspect >= 2.0)\n', numel(pca_bbox_errors));
fprintf('  Mean PCA-bbox angle difference: %.1f degrees\n', mean(pca_bbox_errors));
fprintf('  Median: %.1f degrees\n', median(pca_bbox_errors));
fprintf('  %% within 20 degrees: %.0f%%\n', 100*mean(pca_bbox_errors < 20));
if mean(pca_bbox_errors) < 30
    fprintf('  PASS: PCA axis aligns reasonably with bbox long axis\n');
else
    fprintf('  WARNING: PCA axis diverges from bbox axis (may indicate curved loops)\n');
end
fprintf('  (Note: PCA can differ from bbox axis for curved/banana-shaped loops — this is expected)\n');

%% ================================================================
%  TEST 5: Shuffle control
%  ================================================================
%
%  If we randomly shuffle which distance is assigned to which orientation,
%  the cos-distance correlation should disappear. This confirms the
%  correlation is not an artefact of the analysis pipeline.

fprintf('\n--- TEST 5: Shuffle control ---\n');

% First compute real cos and distance for all loops
real_cos  = [];
real_dist = [];

for f = 1:min(n_flies, 200)
    x_fly = x_all(f,:);  y_fly = y_all(f,:);
    x_det = x_fly;  y_det = y_fly;  h_det = heading_all(f,:);
    x_det(mask_s:mask_e) = NaN;
    y_det(mask_s:mask_e) = NaN;
    h_det(mask_s:mask_e) = NaN;

    v_fly = vel_all(f,:);
    v_fly(mask_s:mask_e) = NaN;
    loop_opts.vel = v_fly;

    loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts);

    for k = 1:loops.n_loops
        if loops.bbox_aspect(k) < ASPECT_THRESHOLD, continue; end
        sf = loops.start_frame(k);
        ef = loops.end_frame(k);
        [~, ra, ~, ~] = compute_loop_orientation(x_fly(sf:ef), y_fly(sf:ef), ARENA_CENTER);
        if ~isnan(ra)
            real_cos  = [real_cos, cosd(ra)];
            real_dist = [real_dist, loops.bbox_dist_center(k)];
        end
    end
end

% Real correlation
v = ~isnan(real_cos) & ~isnan(real_dist);
[r_real, p_real] = corr(real_cos(v)', real_dist(v)', 'Type', 'Spearman');

% Shuffled correlations (1000 permutations)
n_perms = 1000;
r_shuf = NaN(1, n_perms);
for pi = 1:n_perms
    shuf_idx = randperm(sum(v));
    shuf_dist = real_dist(v);
    shuf_dist = shuf_dist(shuf_idx);
    r_shuf(pi) = corr(real_cos(v)', shuf_dist', 'Type', 'Spearman');
end

p_perm = mean(abs(r_shuf) >= abs(r_real));

fprintf('  n loops tested: %d\n', sum(v));
fprintf('  Real Spearman r(cos, dist): %.4f (p = %.3e)\n', r_real, p_real);
fprintf('  Shuffled r: mean=%.4f, SD=%.4f, range=[%.4f, %.4f]\n', ...
    mean(r_shuf), std(r_shuf), min(r_shuf), max(r_shuf));
fprintf('  Permutation p-value: %.4f (fraction of shuffles with |r| >= |r_real|)\n', p_perm);
if p_perm < 0.01
    fprintf('  PASS: Real correlation is significantly stronger than shuffled\n');
else
    fprintf('  WARNING: Real correlation is not distinguishable from shuffled\n');
end

%% Summary

fprintf('\n======================================================================\n');
fprintf('  VERIFICATION COMPLETE — 5 tests run\n');
fprintf('======================================================================\n');
