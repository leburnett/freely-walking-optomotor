function make_spatial_prob_heatmap(DATA, strain, exp, condition)
% Function to make probability heatmaps of the flies location in the arena
% during specific conditions from protocol 27. 

% If "acclim" is set as something then it will make a plot for that
% condition. Otherwise, it will make a 1 x 3 plot for a condition - before,
% during and after.

% Could also update this to include a plot that plots the convex hull
% around the flies in different time bins over the course of the stimulus. 

% strain = "jfrc100_es_shibire_kir";
sex = "F";

% Fixed parameters
im_size = 250;
bin_size = 22;
num_bins = ceil(im_size / bin_size);

%% Check if "acclim" or "condition"
% If "Condition" is a number - then it's for a condition, otherwise it's
% for the string "condition" and is during an acclim period. 
figure; 

if isnumeric(condition)
    isacclim = 0;
    tiledlayout(1,3);
else
    isacclim = 1;
end 

%% Gather data from single exp "exp" or if empty then across all exps.
if isempty(exp) % Then run through all exp
    data = DATA.(strain).(sex);
else
    data = DATA.(strain).(sex)(exp);
end 

n_files = length(data);

for subpl = 1:3
    
    nexttile

    if subpl == 1
        rng = 1:300;
        sub_tit = "OFF";
    elseif subpl ==2 
        rng = 1050:1200;
        sub_tit = "GRATINGS";
        % rng = 301:750; %1650;
        % sub_tit = "BAR";
    elseif subpl == 3
        rng = 1201:1800;
        sub_tit = "OFF";
        % rng = 1650:2250;
        % sub_tit = "OFF";
    end 

    for i = 1:n_files
    
        d_exp = data(i); % Data for a single experiment. 
        n_flies = d_exp.meta.n_flies;

        if isacclim
            x_all = d_exp.(condition).x_data;
            y_all = d_exp.(condition).y_data;
        else
            x_all1 = d_exp.(strcat("R1_condition_", string(condition))).x_data;
            x_all2 = d_exp.(strcat("R2_condition_", string(condition))).x_data;
            y_all1 = d_exp.(strcat("R1_condition_", string(condition))).y_data;
            y_all2 = d_exp.(strcat("R2_condition_", string(condition))).y_data;

            negg1 = any(x_all1 < 0, 2);
            negg2 = any(x_all2 < 0, 2);
            negg3 = any(y_all1 < 0, 2);
            negg4 = any(y_all2 < 0, 2);
            negg = logical(sum([negg1, negg2, negg3, negg4],2));

            x_all1(negg, :) = [];
            x_all2(negg, :) = [];
            y_all1(negg, :) = [];
            y_all2(negg, :) = [];

            n_flies = height(x_all1);
        end 

        % Create an empty array to hold the bin counts
        pos_data  = zeros(num_bins, num_bins);

        for idx = 1:n_flies
            
            if isacclim

                x = x_all(idx, :);
                y = y_all(idx, :);
            
                for f = 1:size(x, 2)
                    % Calculate the bin index for the x and y position
                    x_bin = floor(x(f) / bin_size) + 1;
                    if x_bin > num_bins
                        x_bin = num_bins;
                    end 

                    y_bin = floor(y(f) / bin_size) + 1;
                    if y_bin > num_bins
                        y_bin = num_bins;
                    end 
    
                    if ~isnan(x_bin) && ~isnan(y_bin)
                        pos_data(x_bin, y_bin) = pos_data(x_bin, y_bin) +1; 
                    end 
                end 

            else % normal condition - run through both reps. 

                for rep = [1,2]

                    if rep == 1
                        x = x_all1(idx, :);

                        y = y_all1(idx, :);
                    elseif rep == 2 
                        x = x_all2(idx, :);
                        y = y_all2(idx, :);
                    end 
                
                    for f = rng % Only run through the frames that correspond
                        % to the period of the condition that you want to assess. 

                        % Calculate the bin index for the x and y position
                        x_bin = abs(floor(x(f) / bin_size)) + 1;
                        y_bin = abs(floor(y(f) / bin_size)) + 1;

                        if x_bin > num_bins
                            x_bin = num_bins;
                        end

                        if y_bin > num_bins
                            y_bin = num_bins;
                        end
        
                        if ~isnan(x_bin) && ~isnan(y_bin)
                            pos_data(x_bin, y_bin) = pos_data(x_bin, y_bin) +1; 
                        end 
                    end 
                end 
            end 

        end 
        
    end 
    pos_data = pos_data/sum(sum(pos_data));
    % max_lim = max(max(pos_data))*0.4;
    % max_lim = 0.003;

    % plot
    imagesc(pos_data); %clim([0 max_lim])
    hold on
    % plot(num_bins/2, num_bins/2, 'c+', 'MarkerSize', 12, 'LineWidth', 2.5);
    viscircles([num_bins/2, num_bins/2], num_bins/2, "Color", 'w', "LineWidth", 0.3); 
    plot([num_bins/2, num_bins/2], [0, num_bins], 'w', "LineWidth", 0.3);
    plot([0, num_bins], [num_bins/2, num_bins/2], 'w', "LineWidth", 0.3);

    infern = cmap_inferno();
    colormap(infern)
    % set(gcf, 'Position', [178  819  1487 205])
    set(gcf, 'Position', [178   738   950   286])
    axis off
    title(sub_tit)
    xlim([0 num_bins])
    ylim([0 num_bins])

    if subpl == 3
        hcb=colorbar;
        hcb.Title.String = "Probability";
        hcb.Ruler.SecondaryLabel.Units = 'normalized';
        hcb.Ruler.SecondaryLabel.Position = [1.07 0.95];
        % hcb.Ticks = [0, 0.001, 0.002, 0.003];
        hcb.TickDirection = 'out';
        hcb.FontSize = 12; 
        hcb.LineWidth = 1; 
    end 
end 
f = gcf;
f.Position = [45   820   718   200];
end 
