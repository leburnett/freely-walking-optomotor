%% Figure 1 - control flies - centring and optomotor behaviour.

%% ================================================================
%  SECTION 1: Setup
%  ================================================================

cfg = get_config();
ROOT_DIR = cfg.project_root;

if ~exist('DATA', 'var')
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

%% Reference - reminder of the condition order:

% cond_titles = {"60deg-gratings-4Hz"... %1
%             , "60deg-gratings-8Hz"... %2
%             , "narrow-ON-bars-4Hz"... %3
%             , "narrow-OFF-bars-4Hz"... %4
%             , "ON-curtains-8Hz"... %5
%             , "OFF-curtains-8Hz"... %6
%             , "reverse-phi-2Hz"... %7
%             , "reverse-phi-4Hz"... %8
%             , "60deg-flicker-4Hz"... %9
%             , "60deg-gratings-static"... %10
%             , "60deg-gratings-0-8-offset"... %11
%             , "32px-ON-single-bar"... %12
%             };

%% Colour map options

% Rainbow
% cmap = [31 120 180; ...
%         166 206 227; ...
%         178 223 138; ...
%         47 141 41; ...
%         251 154 153; ...
%         227 26 28; ...
%         253 191 111; ...
%         255 127 0; ...
%         202 178 214; ...
%         106 61 154; ...
%         255 224 41; ...
%         187 75 12; ...
%         ]./255;

% Blues
cmap = [31 120 180; ... %50 50 50; ...% 166 206 227; 106 61 154; ...
    31 120 180; ...
    178 223 138; ...
    47 141 41; ...
    251 154 153; ...
    227 26 28; ...
    253 191 111; ...
    255 127 0; ...
    166 206 227; ...%202 178 214; ...
    200 200 200; ... % 106 61 154; ...166 206 227;
    255 224 41; ...
    187 75 12; ...
    ]./255;

% Different speed colours     
 % cmap = [173 216 230; ... % 1Hz %50 50 50; ...% 166 206 227; 106 61 154; ...
 %    82 173 227; ... % 2Hz
 %    31 120 180; ... % 4 HZ
 %    61 82 159; ... % 8 Hz
 %    231 158 190; ... % Flicker
 %    243 207 226; ...
 %    231 158 190; ...
 %    223 113 167; ...
 %    215 48 139; ...%202 178 214; ...
 %    200 200 200; ... % 106 61 154; ...166 206 227;
 %    255 224 41; ...
 %    187 75 12; ...
 %    ]./255;

%% Fixed parameters. 
strain = "jfrc100_es_shibire_kir";
protocol = "protocol_27";
data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta'};

params.save_figs = 0;
params.plot_sem = 1;
params.plot_sd = 0;
params.plot_individ = 0;
params.shaded_areas = 0;

%% These plots compare control flies' behaviour to moving and static gratings
cond_ids = [10, 1]; % 60 deg gratings (condition 1) and 60 deg flicker (condition 10).

%% ================================================================
%  SECTION 2: Characterisation of ES optomotor and centring behaviour
%  ================================================================

% Time series plots.
for i = 1:numel(data_types)

    data_type = data_types{i};

    figure;
    plot_xcond_per_strain2(protocol, data_type, cond_ids, strain_names, params, DATA)
    f = gcf;
    f.Position = [181   611   641   340];

end 

%% ================================================================
%  SECTION 3: Box and whisker chart for metrics
%  ================================================================

cond_ids = [1, 10];
n_cond = numel(cond_ids);

panels = struct( ...
    'data_type', {'dist_data',  'dist_data',  'dist_data',  'fv_data',   'av_data'}, ...
    'rng',       {1170:1200,    1170:1200,    1470:1500,    300:1200,    300:1200}, ...
    'delta',     {0,            1,            2,            0,           0}, ...
    'ref_line',  {[],           [0.5 4.5],    [0.5 3.5],    [0.5 3.5],   []}, ...
    'xl',        {[0.5 n_cond+0.5],  [0.5 n_cond+0.5],  [0.5 n_cond+0.5],  [0.5 n_cond+0.5], [0.5 n_cond+0.5]} ...
);

for i = 1:numel(panels)
    p = panels(i);
    if i > 1
        figure;
    end
    if ~isempty(p.ref_line)
        plot(p.ref_line, [0 0], 'k');
        hold on;
    end
    plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, p.data_type, p.rng, p.delta, cmap);
    if ~isempty(p.xl)
        xlim(p.xl);
    end
end


%% ================================================================
%  SECTION 4: Histograms for metrics
%  ================================================================

% Make the corresponding histogram plots. 

for i = 1:numel(panels)
    p = panels(i);
    if i > 1
        figure;
    end
    plot_histogram_metrics_xcond(DATA, cond_ids, strain_names, p.data_type, p.rng, p.delta, cmap)
end


%% ================================================================
%  SECTION 5: Trajectory examples
%  ================================================================

show_phases = 1; % plots 5s pre and post stimulus and CW in blue and CCW in pink.
cond_id = 1;
fly_id = 802; 
plot_traj_xcond(DATA, strain, cond_id, fly_id, show_phases)

% Possible fly_ids ES_shibire_kir
% [543, 557, 544, 523, 370, 312, 396, 212, 816, 818, 166]
% [807, 802, 791, 314, 24, 776, 786, 804, 746, 215, 743, 701, 705, 727, 239]
% [24, 692, 646, 639, 631, 245, 637, 625, 581, 583, 87, 547]















