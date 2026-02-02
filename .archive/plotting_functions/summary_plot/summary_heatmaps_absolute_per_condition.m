
%% Absolute heatmap of values - only one condition to make / 4 and 8Hz only. 

% Requires 'DATA' to already be made. 

% Add the matrices "dist_dt" - centring rate - for each experiment. 
% This is not currently included in the standard processing pipeline
% and so has to be added later here.
% DATA = add_dist_dt(DATA);

% Heatmap = p-values of comparison between ES and strains based on raw
% (not z-score) values of metrics. 

pvals_all_cond = [];
target_all = [];
control_all = [];

% Combine the data across the conditions
for condition_n = [1] %1:12

    [pvals_cond, target_mean_all, control_mean_all, strain_names] = make_pvalue_heatmap_across_strains(DATA, condition_n);

    pvals_all_cond = vertcat(pvals_all_cond, pvals_cond);
    target_all = vertcat(target_all, target_mean_all);
    control_all = vertcat(control_all, control_mean_all);
end 
    
    
% plot heatmap of the absolute values
% normalised by metric across all strains - white = lowest, black =
% highest. 

% 1 - normalise each column.

xmin = min(target_all);           % Minimum of each column
xmax = max(target_all);           % Maximum of each column

% Standard normalisation: (X - xmin) ./ (xmax - xmin) gives 0→min, 1→max
X_norm = (target_all - xmin) ./ (xmax - xmin);

% Invert so min→1 and max→0
target_all_norm = 1 - X_norm;

%% Plot the heatmap divided up by CONDITION

close
n_strains = height(strain_names);
n_conditions = 1;
f = tiledlayout(n_conditions, 1);
f.Padding = "tight";
multi = 1;

h_all = height(pvals_all_cond);

for cond_n = 1:n_conditions

    nexttile

    % Extract the interleaved values
    if cond_n ==1 
        rng = 1:n_strains;
    elseif cond_n == 2
        rng = n_strains+1:n_strains*2;
    end 

    % Extract just the data for this strain
    t_all = target_all_norm(rng, :);

    if cond_n <n_conditions
        plot_x = 0;
    else
        plot_x = 1;
    end 

    % Plot the data: 
    plot_val_heatmap_condition(t_all, plot_x, multi, strain_names)

    % Format the plot.
    grid on
    ax = gca;
    xt = ax.XTick;
    ax.XTick = xt + 0.5; 
    yt = ax.YTick;
    ax.YTick = yt + 0.5;
    ax.XAxis.TickLength = [0 0];
    ax.YAxis.TickLength = [0 0]; 
    title(strrep(cond_titles{9}, '_', '-'))
 end 

f = gcf;
% f.Position = [2578   695   274  371]; %  2 cond
f.Position = [2578   885   246  181]; % 1 cond




%% Normalise columns to fixed ranges - not min / max across strains.


pvals_all_cond = [];
target_all = [];
control_all = [];

% Combine the data across the conditions
for condition_n = [1] %1:12

    [pvals_cond, target_mean_all, control_mean_all, strain_names] = make_pvalue_heatmap_across_strains(DATA, condition_n);

    pvals_all_cond = vertcat(pvals_all_cond, pvals_cond);
    target_all = vertcat(target_all, target_mean_all);
    control_all = vertcat(control_all, control_mean_all);
end 
    
%% Plot the heatmap divided up by CONDITION

close
n_strains = height(strain_names);
n_conditions = 1;
f = tiledlayout(n_conditions, 1);
f.Padding = "tight";
multi = 1;

h_all = height(pvals_all_cond);

for cond_n = 1:n_conditions

    nexttile

    % Extract the interleaved values
    if cond_n ==1 
        rng = 1:n_strains;
    elseif cond_n == 2
        rng = n_strains+1:n_strains*2;
    end 

    % Extract just the data for this strain
    t_all = target_all_norm(rng, :);

    if cond_n <n_conditions
        plot_x = 0;
    else
        plot_x = 1;
    end 

    % Plot the data: 
    plot_val_heatmap_condition(t_all, plot_x, multi, strain_names)

    % Format the plot.
    grid on
    ax = gca;
    xt = ax.XTick;
    ax.XTick = xt + 0.5; 
    yt = ax.YTick;
    ax.YTick = yt + 0.5;
    ax.XAxis.TickLength = [0 0];
    ax.YAxis.TickLength = [0 0]; 
    title(strrep(cond_titles{9}, '_', '-'))
 end 

f = gcf;
% f.Position = [2578   695   274  371]; %  2 cond
f.Position = [2578   885   246  181]; % 1 cond
































    
%% Make heatmap plot split by metric. 
% Shared colourmap for the same metric type. 

% A - forward velocity. 
fv = target_all(:, 1:4);

rng_cmap = [5 15];

xmin = rng_cmap(1); 
xmax = rng_cmap(2); 

% Standard normalisation: (X - xmin) ./ (xmax - xmin) gives 0→min, 1→max
fv_norm = (fv - xmin) ./ (xmax - xmin);

% Invert so min→1 and max→0
fv_norm = 1 - fv_norm;

% Plot the figure
figure
n_conditions = 1;
f = tiledlayout(n_conditions, 1);
f.Padding = "tight";

% Initialize RGB image
[m, n] = size(fv_norm);
heatmap_rgb = ones(m, n, 3); % Start with white background

% Loop through each element
for i = 1:m
    for j = 1:n
        p_val = fv_norm(i,j);
        heatmap_rgb(i,j,:) = [p_val, p_val, p_val]; % Red fades with p
    end
end

% Display the heatmap
image(heatmap_rgb);

cond_titles = strain_names;
cond_titles = strrep(cond_titles, '_', '-');
cond_titles = strrep(cond_titles, '-shibire-kir', '');

n_conditions = numel(cond_titles);
yticks(1:n_conditions)
yticklabels(cond_titles)

xticks(1:4)
xticklabels({...
    'fv-10s-b4', ...
    'fv-stim', ...
    'fv-3s-start', ...
    'fv-3s-stop', ...
    })

ax = gca;
ax.FontSize = 5;
ax.LineWidth = 0.5;
grid on
xt = ax.XTick;
ax.XTick = xt + 0.5; 
yt = ax.YTick;
ax.YTick = yt + 0.5;
ax.XAxis.TickLength = [0 0];
ax.YAxis.TickLength = [0 0]; 

N = 256; 
myMap = [linspace(1,0,N)' linspace(1,0,N)' linspace(1,0,N)'];

c = colorbar(ax, 'southoutside', 'Limits', [0 1], 'Colormap', myMap, 'AxisLocation', 'out');
c.Ticks = [0 1];
c.TickLabels = {string(rng_cmap(1)), string(rng_cmap(2))};

f = gcf;
f.Position = [620   755   107   212];

% Thinner bar
c_pos = c.Position;
c_pos(4) = c_pos(4) * 0.4;
c_pos(2) = c_pos(2) * 0.15;
c.Position = c_pos;

f.Position = [620   656   110   311];


%% AV - angular velocity

av = target_all(:, 8:10);

rng_cmap = [0 150];

xmin = rng_cmap(1); 
xmax = rng_cmap(2); 

% Standard normalisation: (X - xmin) ./ (xmax - xmin) gives 0→min, 1→max
av_norm = (av - xmin) ./ (xmax - xmin);

% Invert so min→1 and max→0
av_norm = 1 - av_norm;

% Plot the figure
figure
n_conditions = 1;
f = tiledlayout(n_conditions, 1);
f.Padding = "tight";

% Initialize RGB image
[m, n] = size(av_norm);
heatmap_rgb = ones(m, n, 3); % Start with white background

% Loop through each element
for i = 1:m
    for j = 1:n
        p_val = av_norm(i,j);
        heatmap_rgb(i,j,:) = [p_val, p_val, p_val]; % Red fades with p
    end
end

% Display the heatmap
image(heatmap_rgb);

cond_titles = strain_names;
cond_titles = strrep(cond_titles, '_', '-');
cond_titles = strrep(cond_titles, '-shibire-kir', '');

n_conditions = numel(cond_titles);
yticks(1:n_conditions)
yticklabels(cond_titles)

xticks(1:4)
xticklabels({...
    'av-stim', ...
    'av-5s-CW', ...
    'av-5s-CCW', ...
    })

ax = gca;
ax.FontSize = 5;
ax.LineWidth = 0.5;
grid on
xt = ax.XTick;
ax.XTick = xt + 0.5; 
yt = ax.YTick;
ax.YTick = yt + 0.5;
ax.XAxis.TickLength = [0 0];
ax.YAxis.TickLength = [0 0]; 

N = 256; 
myMap = [linspace(1,0,N)' linspace(1,0,N)' linspace(1,0,N)'];

c = colorbar(ax, 'southoutside', 'Limits', [0 1], 'Colormap', myMap, 'AxisLocation', 'out');
c.Ticks = [0 1];
c.TickLabels = {string(rng_cmap(1)), string(rng_cmap(2))};

f = gcf;
f.Position = [620   755   107   212];

% Thinner bar
c_pos = c.Position;
c_pos(4) = c_pos(4) * 0.4;
c_pos(2) = c_pos(2) * 0.15;
c.Position = c_pos;

f.Position = [620   656   110   311];



%% CV - turning rate 

av = target_all(:, 11:13);

rng_cmap = [0 110];

xmin = rng_cmap(1); 
xmax = rng_cmap(2); 

% Standard normalisation: (X - xmin) ./ (xmax - xmin) gives 0→min, 1→max
av_norm = (av - xmin) ./ (xmax - xmin);

% Invert so min→1 and max→0
av_norm = 1 - av_norm;

% Plot the figure
figure
n_conditions = 1;
f = tiledlayout(n_conditions, 1);
f.Padding = "tight";

% Initialize RGB image
[m, n] = size(av_norm);
heatmap_rgb = ones(m, n, 3); % Start with white background

% Loop through each element
for i = 1:m
    for j = 1:n
        p_val = av_norm(i,j);
        heatmap_rgb(i,j,:) = [p_val, p_val, p_val]; % Red fades with p
    end
end

% Display the heatmap
image(heatmap_rgb);

cond_titles = strain_names;
cond_titles = strrep(cond_titles, '_', '-');
cond_titles = strrep(cond_titles, '-shibire-kir', '');

n_conditions = numel(cond_titles);
yticks(1:n_conditions)
yticklabels(cond_titles)

xticks(1:3)
xticklabels({...
    'turning-stim', ...
    'turning-5s-CW', ...
    'turning-5s-CCW', ...
    })

ax = gca;
ax.FontSize = 5;
ax.LineWidth = 0.5;
grid on
xt = ax.XTick;
ax.XTick = xt + 0.5; 
yt = ax.YTick;
ax.YTick = yt + 0.5;
ax.XAxis.TickLength = [0 0];
ax.YAxis.TickLength = [0 0]; 

N = 256; 
myMap = [linspace(1,0,N)' linspace(1,0,N)' linspace(1,0,N)'];

c = colorbar(ax, 'southoutside', 'Limits', [0 1], 'Colormap', myMap, 'AxisLocation', 'out');
c.Ticks = [0 1];
c.TickLabels = {string(rng_cmap(1)), string(rng_cmap(2))};

f = gcf;
f.Position = [620   755   107   212];

% Thinner bar
c_pos = c.Position;
c_pos(4) = c_pos(4) * 0.4;
c_pos(2) = c_pos(2) * 0.15;
c.Position = c_pos;

f.Position = [620   656   110   311];

%% Absolute distance

av = target_all(:, 14:16);

rng_cmap = [35 80];

xmin = rng_cmap(1); 
xmax = rng_cmap(2); 

% Standard normalisation: (X - xmin) ./ (xmax - xmin) gives 0→min, 1→max
av_norm = (av - xmin) ./ (xmax - xmin);

% Invert so min→1 and max→0
av_norm = 1 - av_norm;

% Plot the figure
figure
n_conditions = 1;
f = tiledlayout(n_conditions, 1);
f.Padding = "tight";

% Initialize RGB image
[m, n] = size(av_norm);
heatmap_rgb = ones(m, n, 3); % Start with white background

% Loop through each element
for i = 1:m
    for j = 1:n
        p_val = av_norm(i,j);
        heatmap_rgb(i,j,:) = [p_val, p_val, p_val]; % Red fades with p
    end
end

% Display the heatmap
image(heatmap_rgb);

cond_titles = strain_names;
cond_titles = strrep(cond_titles, '_', '-');
cond_titles = strrep(cond_titles, '-shibire-kir', '');

n_conditions = numel(cond_titles);
yticks(1:n_conditions)
yticklabels(cond_titles)

xticks(1:3)
xticklabels({...
    'dist-abs-start'...
    'dist-abs-end', ...
    'dist-abs-int', ...
    })

ax = gca;
ax.FontSize = 5;
ax.LineWidth = 0.5;
grid on
xt = ax.XTick;
ax.XTick = xt + 0.5; 
yt = ax.YTick;
ax.YTick = yt + 0.5;
ax.XAxis.TickLength = [0 0];
ax.YAxis.TickLength = [0 0]; 

N = 256; 
myMap = [linspace(1,0,N)' linspace(1,0,N)' linspace(1,0,N)'];

c = colorbar(ax, 'southoutside', 'Limits', [0 1], 'Colormap', myMap, 'AxisLocation', 'out');
c.Ticks = [0 1];
c.TickLabels = {string(rng_cmap(1)), string(rng_cmap(2))};

f = gcf;
f.Position = [620   755   107   212];

% Thinner bar
c_pos = c.Position;
c_pos(4) = c_pos(4) * 0.4;
c_pos(2) = c_pos(2) * 0.15;
c.Position = c_pos;

f.Position = [620   656   110   311];


%% Relative distance

av = target_all(:, 17:19);

rng_cmap = [-45 10];

xmin = rng_cmap(1); 
xmax = rng_cmap(2); 

% Standard normalisation: (X - xmin) ./ (xmax - xmin) gives 0→min, 1→max
av_norm = (av - xmin) ./ (xmax - xmin);

% Invert so min→1 and max→0
av_norm = 1 - av_norm;

% Plot the figure
figure
n_conditions = 1;
f = tiledlayout(n_conditions, 1);
f.Padding = "tight";

% Initialize RGB image
[m, n] = size(av_norm);
heatmap_rgb = ones(m, n, 3); % Start with white background

% Loop through each element
for i = 1:m
    for j = 1:n
        p_val = av_norm(i,j);
        heatmap_rgb(i,j,:) = [p_val, p_val, p_val]; % Red fades with p
    end
end

% Display the heatmap
image(heatmap_rgb);

cond_titles = strain_names;
cond_titles = strrep(cond_titles, '_', '-');
cond_titles = strrep(cond_titles, '-shibire-kir', '');

n_conditions = numel(cond_titles);
yticks(1:n_conditions)
yticklabels(cond_titles)

xticks(1:3)
xticklabels({...
    'dist-rel-10'...
    'dist-rel-end', ...
    'dist-rel-int', ...
    })

ax = gca;
ax.FontSize = 5;
ax.LineWidth = 0.5;
grid on
xt = ax.XTick;
ax.XTick = xt + 0.5; 
yt = ax.YTick;
ax.YTick = yt + 0.5;
ax.XAxis.TickLength = [0 0];
ax.YAxis.TickLength = [0 0]; 

N = 256; 
myMap = [linspace(1,0,N)' linspace(1,0,N)' linspace(1,0,N)'];

c = colorbar(ax, 'southoutside', 'Limits', [0 1], 'Colormap', myMap, 'AxisLocation', 'out');
c.Ticks = [0 1];
c.TickLabels = {string(rng_cmap(1)), string(rng_cmap(2))};

f = gcf;
f.Position = [620   755   107   212];

% Thinner bar
c_pos = c.Position;
c_pos(4) = c_pos(4) * 0.4;
c_pos(2) = c_pos(2) * 0.15;
c.Position = c_pos;

f.Position = [620   656   110   311];



%% Centring rate

av = target_all(:, 20:24);

rng_cmap = [-2 2];

xmin = rng_cmap(1); 
xmax = rng_cmap(2); 

% Standard normalisation: (X - xmin) ./ (xmax - xmin) gives 0→min, 1→max
av_norm = (av - xmin) ./ (xmax - xmin);

% Invert so min→1 and max→0
av_norm = 1 - av_norm;

% Plot the figure
figure
n_conditions = 1;
f = tiledlayout(n_conditions, 1);
f.Padding = "tight";

% Initialize RGB image
[m, n] = size(av_norm);
heatmap_rgb = ones(m, n, 3); % Start with white background

% Loop through each element
for i = 1:m
    for j = 1:n
        p_val = av_norm(i,j);
        heatmap_rgb(i,j,:) = [p_val, p_val, p_val]; % Red fades with p
    end
end

% Display the heatmap
image(heatmap_rgb);

cond_titles = strain_names;
cond_titles = strrep(cond_titles, '_', '-');
cond_titles = strrep(cond_titles, '-shibire-kir', '');

n_conditions = numel(cond_titles);
yticks(1:n_conditions)
yticklabels(cond_titles)

xticks(1:5)
xticklabels({...
    'centring-stim', ...
    'centring-3s', ...
    'centring-CW', ...
    'centring-CCW', ...
    'centring-5s-int', ...
    })

ax = gca;
ax.FontSize = 5;
ax.LineWidth = 0.5;
grid on
xt = ax.XTick;
ax.XTick = xt + 0.5; 
yt = ax.YTick;
ax.YTick = yt + 0.5;
ax.XAxis.TickLength = [0 0];
ax.YAxis.TickLength = [0 0]; 

N = 256; 
myMap = [linspace(1,0,N)' linspace(1,0,N)' linspace(1,0,N)'];

c = colorbar(ax, 'southoutside', 'Limits', [0 1], 'Colormap', myMap, 'AxisLocation', 'out');
c.Ticks = [0 1];
c.TickLabels = {string(rng_cmap(1)), string(rng_cmap(2))};

f = gcf;
f.Position = [620   755   107   212];

% Thinner bar
c_pos = c.Position;
c_pos(4) = c_pos(4) * 0.4;
c_pos(2) = c_pos(2) * 0.15;
c.Position = c_pos;

f.Position = [620   656   110   311];






