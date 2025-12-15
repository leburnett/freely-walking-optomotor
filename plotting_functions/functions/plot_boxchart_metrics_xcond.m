function plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta)
%% Box and whisker plots  - plot metric values for different conditions next to each other. 

% rng - frames over which to calculate metric.

    
% Blues
col_12 = [31 120 180; ... %50 50 50; ...% 166 206 227; 106 61 154; ...
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

box_colours = col_12(cond_ids, :);

sex = 'F';

data_to_plot = [];
grp_data_to_plot= [];
    
for strain_id = 1:numel(strain_names)

    strain = strain_names{strain_id};
    
    for c = 1:numel(cond_ids)
    
        condition_n = cond_ids(c);
        % col = col_12(condition_n, :);
    
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
        grp_data = ones([1, n_flies])*c;

        data_to_plot = [data_to_plot, mean_data'];
        grp_data_to_plot = [grp_data_to_plot, grp_data];
    end

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


for k = 1:3
    idx = (g == k) & ~isnan(data_to_plot);
    boxchart( k*ones(sum(idx),1), data_to_plot(idx), ...
        'MarkerStyle', 'none', ...
        'BoxWidth', 0.5, ...
        'BoxFaceColor', box_colours(k,:), ...
        'BoxFaceAlpha', 0.5);
end

% Set x ticks
xticks(1:3)
% xticklabels({'1','2','3'})
xticklabels({})
xlim([0.5 3.5])

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