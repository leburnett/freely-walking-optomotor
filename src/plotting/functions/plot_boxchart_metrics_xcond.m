function plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta, cmap)
% PLOT_BOXCHART_METRICS_XCOND Generate box plots comparing conditions
%
%   PLOT_BOXCHART_METRICS_XCOND(DATA, cond_ids, strain_names, data_type, rng, delta)
%   creates box plots comparing behavioral metrics across multiple stimulus conditions.

% Resolve delta data types (e.g., 'fv_data_delta' → 'fv_data' + delta=1)
[data_type, resolved_delta] = resolve_delta_data_type(data_type);
if resolved_delta > 0, delta = resolved_delta; end
%
% INPUTS:
%   DATA         - DATA struct from comb_data_across_cohorts_cond
%   cond_ids     - Vector of condition indices to plot (e.g., [1,2,3,4])
%   strain_names - Cell array of strain names to include
%   data_type    - String specifying metric: 'av_data', 'fv_data', 'dist_data', etc.
%   rng          - Frame range to average over (e.g., 300:1200 for stimulus period)
%   delta        - 0=raw values, 1=relative to frame 300, 2=relative to frame 1200
%
% OUTPUTS:
%   Creates box plot figure with:
%   - Individual data points (jittered white circles)
%   - Box charts with colored fills matching condition
%   - Rainbow colormap for up to 12 conditions
%
% PREPROCESSING:
%   - Uses combine_timeseries_across_exp_check (filters non-walking flies)
%   - For av_data/curv_data: flips second half of stimulus (frames 750:1200)
%   - Conditions 7,8 (reverse phi): multiplies by -1 for sign convention
%
% Y-AXIS LIMITS (auto-set by data_type):
%   - fv_data: [0, 27]
%   - dist_data: [0, 125] or [-110, 100] if delta=1
%   - av_data: [-20, 225]
%   - curv_data: [-40, 210]
%
% See also: boxchart, scatter, combine_timeseries_across_exp_check, get_ylb_from_data_type
   
box_colours = cmap(cond_ids, :);

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
            cond_data = (cond_data - cond_data(:, 300))*-1; % relative            
        end

        if delta == 2
            cond_data = (cond_data - cond_data(:, 1200))*-1; % relative            
        end

        if data_type == "av_data" ||  data_type == "curv_data" 
            cond_data(:, 750:1200) = cond_data(:, 750:1200)*-1;
        end 
    
        % Extract only the frames of interest
        cond_data = cond_data(:, rng);

        % Mean within this range per rep per fly - one data point per rep.
        % After "combine_timeseries_across_exp_check" this is now per FLY
        mean_data = nanmean(cond_data, 2);

        if condition_n == 7 || condition_n == 8
            mean_data = mean_data*-1;
        end 
        
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


for k = 1:numel(cond_ids)
    idx = (g == k) & ~isnan(data_to_plot);
    boxchart( k*ones(sum(idx),1), data_to_plot(idx), ...
        'MarkerStyle', 'none', ...
        'BoxWidth', 0.5, ...
        'BoxFaceColor', box_colours(k,:), ...
        'BoxFaceAlpha', 0.5);
end

% Set x ticks — label with condition numbers
xticks(1:numel(cond_ids))
xticklabels(arrayfun(@(c) sprintf('Cond %d', c), cond_ids, 'UniformOutput', false))
xlim([0.5 numel(cond_ids)+0.5])

% Set y label.
ylb = get_ylb_from_data_type(data_type, delta);
ylabel(ylb)

% Set y-limits
if data_type == "fv_data"
    if delta, yrng = [-15 15]; else, yrng = [0 27]; end
elseif data_type == "dist_data"
    if delta == 1
        yrng = [-100 120];
    elseif delta == 2
        yrng = [-100 120];
    else
        yrng = [0 125];
    end
elseif data_type == "view_dist"
    yrng = [60 140];
elseif data_type == "dist_dt"
    yrng = [-7 5];
elseif data_type == "av_data"
    if delta, yrng = [-200 200]; else, yrng = [-20 225]; end
elseif data_type == "curv_data"
    if delta, yrng = [-200 200]; else, yrng = [-40 210]; end
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
f.Position = [138   432   230   413];

% Plot errorbar on top
% errorbar(c, mean_data_all, sem_data, 'Marker', 'o', 'LineStyle', 'none')

end 