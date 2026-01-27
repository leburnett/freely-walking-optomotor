function plot_boxchart_metrics_xstrains(DATA, strain_ids, cond_idx, data_type, rng, delta)
%% Box and whisker plots  - plot metric values for different conditions next to each other. 
% rng - frames over which to calculate metric.
    
strain_colours = [[220,  40,  30]; ...  % muted red
[220,  85,  30];...
[220, 130,  35];...
[220, 175,  40];...
[220, 210,  50];...  % soft yellow
[190, 170, 60];...  % yellow-green
[164, 182, 120];...  % light green
[134, 187, 139];...  % green-cyan
[104, 185, 158];...  % cyan
[ 82, 176, 176];...  % teal
[ 72, 160, 192];...  % blue-cyan
[ 74, 138, 202];...  % blue
[ 86, 114, 204];...  % blue-indigo
[108,  92, 198];...  % indigo
[132,  74, 186];...  % violet
[154,  60, 168]; ...   % deep violet
[40, 40, 40]; ...
[180, 180, 180]]./255;

box_colours = strain_colours(strain_ids, :);

strain_names = load('/Users/burnettl/Documents/Projects/oaky_cokey/results/strain_names2.mat');
strain_names = strain_names.strain_names;
n_strains = height(strain_names);
strain_names{n_strains+1} = 'jfrc100_es_shibire_kir';
strain_names{n_strains+2} = 'csw1118';

sex = 'F';
data_to_plot = [];
grp_data_to_plot= [];

ns = numel(strain_ids);
    
for strain_id = 1:ns

    strain = strain_names{strain_ids(strain_id)};
    disp(strain)
    
    condition_n = cond_idx;

    data = DATA.(strain).(sex);

    % Matrix of timeseries data. 
    % The two reps of each fly are next to each other.
    % cond_data = combine_timeseries_across_exp(data, condition_n, data_type);
    % Now removes flies that don't move on average > 2mm s-1 over the
    % stimlus or are too close to the edge of the arena for the entire
    % stimulus.
    cond_data = combine_timeseries_across_exp_check(data, condition_n, data_type);

    if delta == 1
        cond_data = cond_data - cond_data(:, 300); % relative            
    end

    if delta == 2
        cond_data = cond_data - cond_data(:, 1200); % relative            
    end

    if data_type == "av_data" ||  data_type == "curv_data" 
        cond_data(:, 750:1200) = cond_data(:, 750:1200)*-1;
    end 

    % Extract only the frames of interest
    cond_data = cond_data(:, rng);

    % Mean within this range per rep per fly - one data point per rep.
    % After "combine_timeseries_across_exp_check" this is now per FLY
    mean_data = nanmean(cond_data, 2);
    
    % Then average per fly - one data point per fly. 
    % mean_data = squeeze(nanmean(reshape(mean_data_per_rep, 2, [], size(mean_data_per_rep,2)), 1));

    n_flies = numel(mean_data);
    grp_data = ones([1, n_flies])*strain_id;

    data_to_plot = [data_to_plot, mean_data'];
    grp_data_to_plot = [grp_data_to_plot, grp_data];
  
end 

g = grp_data_to_plot;

% figure
hold on

% jitter for scatter
rng_shift = 0.45 * rand(1, numel(g));
x_shift = (g + rng_shift) - 0.25;

scatter(x_shift, data_to_plot, 20, 'o', 'filled', ...
    'MarkerFaceColor','w', ...
    'MarkerEdgeColor',[0.7 0.7 0.7]);

for k = 1:numel(strain_ids)
    idx = (g == k) & ~isnan(data_to_plot);
    boxchart( k*ones(sum(idx),1), data_to_plot(idx), ...
        'MarkerStyle', 'none', ...
        'BoxWidth', 0.5, ...
        'BoxFaceColor', box_colours(k,:), ...
        'BoxFaceAlpha', 0.5);
end

% Set x ticks
xticks(1:ns)
xticklabels({})
xlim([0.5 ns+0.5])

% Set y label.
ylb = get_ylb_from_data_type(data_type, delta);
ylabel(ylb)

% Set y-limits
if data_type == "fv_data" 
    yrng = [0 27];
elseif data_type == "dist_data_delta"
    yrng = [-45 10];
elseif data_type == "dist_data"
    if delta == 1
        yrng = [-110 100];
    elseif delta == 2
        yrng = [-110 120];
    else
        yrng = [0 125];
    end 
elseif data_type == "view_dist"
    yrng = [60 140];
elseif data_type == "dist_dt"
    yrng = [-7 5];
elseif data_type == "av_data"
    yrng = [-40 225];
elseif data_type == "curv_data" 
    yrng = [-40 210];
end 
ylim(yrng)

% Format plot.
box off
ax = gca; 
ax.TickDir = 'out';
ax.TickLength = [0.02 0.02]; 
ax.LineWidth = 1.2; 
ax.FontSize = 14;

f = gcf;
f.Position = [783   493   284   356];

% Plot errorbar on top
% errorbar(c, mean_data_all, sem_data, 'Marker', 'o', 'LineStyle', 'none')

end 