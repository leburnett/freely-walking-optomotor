function cmaps = cmap_config(show)
% CMAP_CONFIG  Colour maps used across figure scripts.
%
%   cmaps = CMAP_CONFIG()
%   cmaps = CMAP_CONFIG(true)   % also displays a visual preview
%
%   Returns a struct containing all colour maps used in the freely-walking
%   optomotor figure scripts (fig1.m through figS3.m). Each field is a
%   struct with:
%     .colors  — [n x 3] RGB matrix (values 0-1)
%     .labels  — {n x 1} cell array of labels for each colour
%     .source  — which figure script uses this colour map
%     .usage   — brief description of what the colours represent
%
%   If 'show' is true, displays a visual preview of all colour maps as
%   rows of coloured circles.
%
%   EXAMPLE:
%     cmaps = cmap_config(true);           % view all colour maps
%     my_blue = cmaps.conditions_p27.colors(2, :);  % get the blue for cond 1
%     strain_cols = cmaps.strains.colors;  % full strain palette
%
%   See also: fig1, fig2, fig3, figS1

if nargin < 1, show = false; end

%% ================================================================
%  1. Protocol 27 conditions (fig1.m)
%  ================================================================
%  12 colours for the 12 stimulus conditions in the main screen protocol.
%  Used in time series, box plots, violins, and histograms.

cmaps.conditions_p27.colors = [ ...
    30,  30,  30;    % cond 1  — 60deg gratings 4Hz
    31, 120, 180;    % cond 2  — 60deg gratings 8Hz
   178, 223, 138;    % cond 3  — narrow ON bars 4Hz
    47, 141,  41;    % cond 4  — narrow OFF bars 4Hz
   251, 154, 153;    % cond 5  — ON curtains 8Hz
   227,  26,  28;    % cond 6  — OFF curtains 8Hz
   253, 191, 111;    % cond 7  — reverse phi 2Hz
   255, 127,   0;    % cond 8  — reverse phi 4Hz
   166, 206, 227;    % cond 9  — 60deg flicker 4Hz
   200, 200, 200;    % cond 10 — 60deg gratings static
   255, 224,  41;    % cond 11 — 60deg gratings 0.8 offset
   187,  75,  12;    % cond 12 — 32px ON single bar
   ] ./ 255;

cmaps.conditions_p27.labels = { ...
    '60° gratings 4Hz', '60° gratings 8Hz', ...
    'Narrow ON bars 4Hz', 'Narrow OFF bars 4Hz', ...
    'ON curtains 8Hz', 'OFF curtains 8Hz', ...
    'Reverse phi 2Hz', 'Reverse phi 4Hz', ...
    '60° flicker 4Hz', '60° gratings static', ...
    '60° gratings 0.8 offset', '32px ON single bar'};
cmaps.conditions_p27.source = 'fig1.m';
cmaps.conditions_p27.usage = '12 stimulus conditions in protocol 27 (main screen)';

%% ================================================================
%  2. Protocol 31 speed tuning (fig2.m)
%  ================================================================
%  Blue gradient for 60-deg gratings (1-8 Hz), pink/magenta gradient for
%  15-deg gratings (4-32 Hz). Grey for flicker controls.

cmaps.conditions_p31.colors = [ ...
   173, 216, 230;    % cond 1  — 60° 1Hz (light blue)
    82, 173, 227;    % cond 2  — 60° 2Hz
    31, 120, 180;    % cond 3  — 60° 4Hz
    61,  82, 159;    % cond 4  — 60° 8Hz (dark blue)
   100, 100, 100;    % cond 5  — 60° flicker (dark grey)
   243, 207, 226;    % cond 6  — 15° 4Hz (pale pink)
   231, 158, 190;    % cond 7  — 15° 8Hz
   223, 113, 167;    % cond 8  — 15° 16Hz
   215,  48, 139;    % cond 9  — 15° 32Hz (dark magenta)
   200, 200, 200;    % cond 10 — 15° flicker (grey)
   ] ./ 255;

cmaps.conditions_p31.labels = { ...
    '60° 1Hz', '60° 2Hz', '60° 4Hz', '60° 8Hz', '60° flicker', ...
    '15° 4Hz', '15° 8Hz', '15° 16Hz', '15° 32Hz', '15° flicker'};
cmaps.conditions_p31.source = 'fig2.m';
cmaps.conditions_p31.usage = 'Speed tuning (protocol 31): blue = 60deg, pink = 15deg';

%% ================================================================
%  3. Protocol 31 T4/T5 conditions (viewdist_segment_metrics_p31_gui)
%  ================================================================
%  Green gradient for 60-deg, orange/yellow gradient for 15-deg.

cmaps.conditions_p31_t4t5.colors = [ ...
   190, 230, 170;    % cond 1  — 60° 1Hz (light green)
   130, 200, 100;    % cond 2  — 60° 2Hz
    60, 160,  60;    % cond 3  — 60° 4Hz
    30, 110,  30;    % cond 4  — 60° 8Hz (dark green)
   100, 100, 100;    % cond 5  — 60° flicker (dark grey)
   255, 225, 150;    % cond 6  — 15° 4Hz (pale yellow)
   255, 195, 100;    % cond 7  — 15° 8Hz (light orange)
   240, 150,  50;    % cond 8  — 15° 16Hz (orange)
   220, 100,  20;    % cond 9  — 15° 32Hz (dark orange)
   180, 180, 180;    % cond 10 — 15° flicker (grey)
   ] ./ 255;

cmaps.conditions_p31_t4t5.labels = cmaps.conditions_p31.labels;
cmaps.conditions_p31_t4t5.source = 'viewdist_segment_metrics_p31_gui.m';
cmaps.conditions_p31_t4t5.usage = 'T4/T5 speed tuning: green = 60deg, orange = 15deg';

%% ================================================================
%  4. Strain palette (figS1.m, fig4.m)
%  ================================================================
%  Red-to-violet gradient for 16 experimental strains in heatmap order.
%  Row 17 = control (dark grey), row 18 = spare (light grey).
%  Strains are mapped in REVERSE order: last experimental strain gets
%  colour 1 (red), first gets colour 16 (violet).

cmaps.strains.colors = [ ...
   220,  40,  30;    % 1  — muted red
   220,  85,  30;    % 2  — red-orange
   220, 130,  35;    % 3  — orange
   220, 175,  40;    % 4  — yellow-orange
   220, 210,  50;    % 5  — soft yellow
   190, 170,  60;    % 6  — yellow-green
   164, 182, 120;    % 7  — light green
   134, 187, 139;    % 8  — green-cyan
   104, 185, 158;    % 9  — cyan
    82, 176, 176;    % 10 — teal
    72, 160, 192;    % 11 — blue-cyan
    74, 138, 202;    % 12 — blue
    86, 114, 204;    % 13 — blue-indigo
   108,  92, 198;    % 14 — indigo
   132,  74, 186;    % 15 — violet
   154,  60, 168;    % 16 — deep violet
    40,  40,  40;    % 17 — control (dark grey)
   180, 180, 180;    % 18 — spare (light grey)
   ] ./ 255;

cmaps.strains.labels = { ...
    'l1l4 (1)', 'Mi4 (2)', 'T4T5 (3)', 'T4 (4)', 'T5 (5)', ...
    'TmY20 (6)', 'Dm4 (7)', 'Pm2ab (8)', 'TmY3 (9)', 'Tm5Y (10)', ...
    'TmY5a (11)', 'H1 (12)', 'H2 (13)', 'Am1 (14)', 'DCH-VCH (15)', ...
    'LPC1 (16)', 'Control (ES)', 'Spare'};
cmaps.strains.source = 'figS1.m, fig4.m';
cmaps.strains.usage = 'Cross-strain comparison: red→violet gradient (reverse heatmap order)';

%% ================================================================
%  5. Stimulus vs baseline (fig3.m)
%  ================================================================

cmaps.stim_baseline.colors = [ ...
     0.10, 0.10, 0.10;    % stimulus line
     0.20, 0.20, 0.20;    % stimulus fill
     0.75, 0.75, 0.75;    % baseline line
     0.80, 0.80, 0.80;    % baseline fill
   ];

cmaps.stim_baseline.labels = {'Stimulus line', 'Stimulus fill', 'Baseline line', 'Baseline fill'};
cmaps.stim_baseline.source = 'fig3.m';
cmaps.stim_baseline.usage = 'Stimulus (black) vs baseline/acclimation (grey)';

%% ================================================================
%  6. Loop vs segment orientation (fig3.m)
%  ================================================================

cmaps.loop_segment.colors = [ ...
     0.60, 0.60, 0.60;    % loop (grey)
     0.133, 0.545, 0.133; % inter-loop segment (forest green)
   ];

cmaps.loop_segment.labels = {'Loops', 'Inter-loop segments'};
cmaps.loop_segment.source = 'fig3.m, loop_vs_segment_orientation_overlay.m';
cmaps.loop_segment.usage = 'Loop orientation (grey) vs inter-loop segment direction (green)';

%% ================================================================
%  7. Trajectory phases (fig1.m — plot_trajectory_condition)
%  ================================================================

cmaps.trajectory_phases.colors = [ ...
     0.70, 0.70, 0.70;        % no stimulus (grey)
     0.231, 0.510, 0.965;     % CCW (blue)
     0.925, 0.282, 0.600;     % CW (pink)
     0.30, 0.60, 0.60;        % start marker (teal)
     0.90, 0.00, 0.00;        % end marker (red)
   ];

cmaps.trajectory_phases.labels = {'No stimulus', 'CCW', 'CW', 'Start', 'End'};
cmaps.trajectory_phases.source = 'plot_trajectory_condition.m';
cmaps.trajectory_phases.usage = 'Trajectory phase colouring: stimulus halves + start/end markers';

%% ================================================================
%  8. NorpA rescue lines (figS2.m)
%  ================================================================

cmaps.norpa_rescue.colors = [ ...
     0.75, 0.75, 0.75;    % ES control
     0.894, 0.102, 0.110; % L1L4
     0.133, 0.545, 0.133; % NorpA +/+
     0.565, 0.933, 0.565; % NorpA UAS-Norp/+
     0.10,  0.25,  0.54;  % NorpA Rh1
     0.55,  0.70,  0.90;  % NorpAw Rh1
     0.40,  0.15,  0.53;  % NorpA Rh2
     0.75,  0.55,  0.85;  % NorpAw Rh2
     0.72,  0.53,  0.04;  % NorpA Rh5/Rh6
     0.95,  0.85,  0.10;  % NorpAw Rh5/Rh6
   ];

cmaps.norpa_rescue.labels = { ...
    'ES control', 'L1L4', 'T4T5', ...
    'NorpA +/+', 'NorpA UAS-Norp/+', ...
    'NorpA Rh1', 'NorpAw Rh1', ...
    'NorpA Rh2', 'NorpAw Rh2', ...
    'NorpA Rh5/Rh6', 'NorpAw Rh5/Rh6'};
cmaps.norpa_rescue.source = 'figS2.m';
cmaps.norpa_rescue.usage = 'NorpA rescue: controls (grey/red/orange), rescue lines by rhodopsin';

%% ================================================================
%  9. Group vs solo (figS3.m)
%  ================================================================

cmaps.group_solo.colors = [ ...
     0.40, 0.40, 0.40;    % grouped (dark grey)
     0.46, 0.15, 0.30;    % solo (burgundy)
   ];

cmaps.group_solo.labels = {'Grouped', 'Solo'};
cmaps.group_solo.source = 'figS3.m';
cmaps.group_solo.usage = 'Group vs solo behavioural comparison';

%% ================================================================
%  10. ES vs T4T5 speed comparison (fig5.m)
%  ================================================================

cmaps.es_vs_t4t5.colors = [ ...
     0.40, 0.40, 0.40;    % ES on 60deg (dark grey)
     1.00, 0.50, 0.00;    % T4T5 on 60deg (orange)
     0.75, 0.75, 0.75;    % ES on 15deg (light grey)
     1.00, 0.85, 0.10;    % T4T5 on 15deg (yellow)
   ];

cmaps.es_vs_t4t5.labels = {'ES 60°', 'T4T5 60°', 'ES 15°', 'T4T5 15°'};
cmaps.es_vs_t4t5.source = 'fig5.m';
cmaps.es_vs_t4t5.usage = 'ES (grey) vs T4T5 (orange/yellow) speed tuning comparison';

%% ================================================================
%  11. Centring figure (fig1_centring.m)
%  ================================================================

cmaps.centring.colors = [ ...
     0.216, 0.494, 0.722;    % stimulus (blue)
     0.70,  0.70,  0.70;     % pre/post & reference lines (grey)
   ];

cmaps.centring.labels = {'Stimulus (blue)', 'Reference (grey)'};
cmaps.centring.source = 'fig1_centring.m';
cmaps.centring.usage = 'Centring phenomenon: blue stimulus period, grey references';

%% ================================================================
%  12. Combined speed range (fig2_combined_speeds.m)
%  ================================================================

cmaps.combined_speeds.colors = [ ...
     0.88, 0.88, 0.88;            % static (light grey)
     0.55, 0.55, 0.55;            % flicker (darker grey)
   173, 216, 230;                  % 1Hz (light blue)
    82, 173, 227;                  % 2Hz
    31, 120, 180;                  % 4Hz
    61,  82, 159;                  % 8Hz (dark blue)
   ] ./ [1; 1; 255; 255; 255; 255];  % first 2 rows already normalised

% Fix: normalise properly
cmaps.combined_speeds.colors = [ ...
     0.88, 0.88, 0.88;    % static
     0.55, 0.55, 0.55;    % flicker
     173, 216, 230;        % 1Hz
      82, 173, 227;        % 2Hz
      31, 120, 180;        % 4Hz
      61,  82, 159;        % 8Hz
   ];
cmaps.combined_speeds.colors(3:6,:) = cmaps.combined_speeds.colors(3:6,:) ./ 255;

cmaps.combined_speeds.labels = {'Static', 'Flicker', '1Hz', '2Hz', '4Hz', '8Hz'};
cmaps.combined_speeds.source = 'fig2_combined_speeds.m';
cmaps.combined_speeds.usage = 'Combined 60deg speed range: grey baselines + blue speed gradient';

%% ================================================================
%  Visual preview
%  ================================================================

if show
    cmap_names = fieldnames(cmaps);
    n_maps = numel(cmap_names);

    max_n = max(cellfun(@(n) size(cmaps.(n).colors, 1), cmap_names));

    figure('Position', [50 50 900 (n_maps + 1) * 55 + 40], ...
        'Name', 'Colour Map Preview', 'Color', 'w');
    hold on;

    % Column index numbers along the top row
    y_top = n_maps + 1;
    for ci = 1:max_n
        text(ci+1, y_top, sprintf('%d', ci), ...
            'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.4 0.4 0.4], ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end

    y = n_maps;
    for mi = 1:n_maps
        name = cmap_names{mi};
        c = cmaps.(name).colors;
        n_c = size(c, 1);

        for ci = 1:n_c
            plot(ci+1, y, 'o', 'MarkerSize', 20, ...
                'MarkerFaceColor', c(ci,:), 'MarkerEdgeColor', [0.5 0.5 0.5], 'LineWidth', 0.75);
        end

        text(0.5, y, strrep(name, '_', ' '), ...
            'FontSize', 11, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');

        y = y - 1;
    end

    xlim([0.5 max_n + 2]);
    ylim([0 n_maps + 1.5]);
    axis off;
    title('Colour maps used in figure scripts', 'FontSize', 16);
    f = gcf; f.Position = [50   240   791   480];

end

end
