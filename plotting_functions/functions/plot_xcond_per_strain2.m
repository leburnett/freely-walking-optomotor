function plot_xcond_per_strain2(protocol, data_type, cond_ids, strain_names, params, DATA)
    
    ROOT_DIR = "/Users/burnettl/Documents/Projects/oaky_cokey/";
    
    if ~exist('DATA', 'var') == 1
        % Move to the directory to where the results per experiment are saved:
        protocol_dir = fullfile(ROOT_DIR, 'results', protocol);
        cd(protocol_dir);
        % Generate the struct 'DATA' that combines data across experiments and
        % separates data into conditions.
        DATA = comb_data_across_cohorts_cond(protocol_dir);
    end 
    
    % % Where to save the figures:
    % date_str = string(datetime("today", "Format", "yyyy_MM_dd"));
    % save_folder = fullfile(ROOT_DIR, "figures", protocol, "Xcond_per_strain", date_str);
    % if ~isfolder(save_folder)
    %     mkdir(save_folder)
    % end 
    
    % % Initialise parameters:
    delta = 0;
    sex = 'F';

    xmax = 1800;

    % Purples
    % Colourmap:
    % col_12 = [106 61 154; ... %50 50 50; ...% 166 206 227; 106 61 154; ...
    %     31 120 180; ...
    %     178 223 138; ...
    %     47 141 41; ...
    %     251 154 153; ...
    %     227 26 28; ...
    %     253 191 111; ...
    %     255 127 0; ...
    %     202 178 214; ...
    %     150 150 150; ... % 106 61 154; ...166 206 227;
    %     255 224 41; ...
    %     187 75 12; ...
    %     ]./255;

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

        
if params.plot_sem == 1
    if data_type == "fv_data" 
        rng = [0 15];
    elseif data_type == "dist_data_delta"
        delta = 1;
        data_type = "dist_data";
        rng = [-45 10];
    elseif data_type == "dist_data"
        rng = [30 90];
    elseif data_type == "view_dist"
        rng = [60 140];
    elseif data_type == "dist_dt"
        rng = [-7 5];
    elseif data_type == "av_data"
        rng = [-200 200];
    elseif data_type == "curv_data" 
        rng = [-150 150];
    end 
elseif params.plot_sd == 1
    if data_type == "fv_data" 
        rng = [0 22];
    elseif data_type == "dist_data_delta"
        delta = 1;
        data_type = "dist_data";
        rng = [-70 30];
    elseif data_type == "dist_data"
        rng = [0 120];
    elseif data_type == "view_dist"
        rng = [60 140];
    elseif data_type == "dist_dt"
        rng = [-7 5];
    elseif data_type == "av_data" || data_type == "curv_data" 
        rng = [-350 350];
    end 
end 
    
%% PLOT 

hold on
if params.shaded_areas == 1
    if data_type == "fv_data" 

        % Full stim
        rectangle('Position', [300, rng(1), 900, rng(2)], ...
              'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

        % % Change at start
        % rectangle('Position', [210, rng(1), 90, rng(2)], ...
        %       'FaceColor', [1 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
        % 
        % 
        % rectangle('Position', [300, rng(1), 90, rng(2)], ...
        %       'FaceColor', [0.4 0.4 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

    elseif data_type == "dist_data"

        if delta == 1

            % within 10s
            rectangle('Position', [570, rng(1), 30, diff(rng)], ...
                  'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

            % end of stim
            rectangle('Position', [1170, rng(1), 30, diff(rng)], ...
                  'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
        else

            % 1s start 
            rectangle('Position', [270, rng(1), 30, diff(rng)], ...
                  'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    
            % 1s end
            rectangle('Position', [1170, rng(1), 30, diff(rng)], ...
                  'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

            % Diff stop to int
            rectangle('Position', [1198, rng(1), 4, diff(rng)], ...
                  'FaceColor', [1 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 0.9);
            rectangle('Position', [1470, rng(1), 30, diff(rng)], ...
                  'FaceColor', [0.4 0.4 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
        end 

    elseif data_type == "av_data" || data_type == "curv_data" 

        % Full stim
        % rectangle('Position', [300, rng(1), 900, diff(rng)], ...
        %       'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

        % % First 5s - slight delay
        rectangle('Position', [315, rng(1), 150, diff(rng)], ...
              'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    end 
end 
   
for strain_id = 1:numel(strain_names)

    strain = strain_names{strain_id};
    
    for c = 1:numel(cond_ids)
    
        condition_n = cond_ids(c);
        col = col_12(condition_n, :);
    
        data = DATA.(strain).(sex);
        cond_data = combine_timeseries_across_exp(data, condition_n, data_type); % absolute
        if delta
            cond_data = cond_data - cond_data(:, 300); % relative
        end 
    
        % Average per fly. 
        mean_data = squeeze(nanmean(reshape(cond_data, 2, [], size(cond_data,2)), 1));

        % Mean across all flies
        mean_data_all = nanmean(mean_data);

        % mean_data = nanmean(cond_data);

        if params.plot_sem == 1
            sem_data = nanstd(mean_data)/sqrt(size(mean_data,1));
        elseif params.plot_sd == 1
            sem_data = nanstd(mean_data);
        end 

        y1 = mean_data_all+sem_data;
        y2 = mean_data_all-sem_data;
        nf_comb = size(mean_data_all, 2);
        x = 1:1:nf_comb;

        if params.plot_individ == 1
            n_indiv = height(mean_data);
            for id = 1:n_indiv
                plot(mean_data(id, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.7); 
                hold on
            end 
        end 
    
        if params.plot_sem == 1 || params.plot_sd == 1
            plot(x, y1, 'w', 'LineWidth', 1)
            hold on
            plot(x, y2, 'w', 'LineWidth', 1)
            patch([x fliplr(x)], [y1 fliplr(y2)], col, 'FaceAlpha', 0.25, 'EdgeColor', 'none')
        end
        plot(mean_data_all, 'Color', col, 'LineWidth', 2.5);
        hold on
    end 
    
    box off
    ax = gca;
    ax.TickDir = 'out';
    ax.LineWidth = 1.2;
    ax.FontSize = 14;
    
    f = gcf;
    % f.Position = [233   581   603   390]; % p27
    f.Position = [233   511   641   460]; % p31
    
    ylb = get_ylb_from_data_type(data_type, delta);
    ylabel(ylb)
    
    xticks([0, 300, 600, 900, 1200, 1500, 1800, 2100, 2400])
    xticklabels({'-10','0', '10', '20', '30', '40', '50', '60', '70'})
    xlabel('Time (s)')

    % Add vertical lines for start, middle and end of stim.
    plot([300 300], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
    plot([750 750], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5) % beginning of stim
    plot([1200 1200], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5) % change of direction   
    
    plot([0 xmax], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5) 
        
    % title(strrep(strain, '_', '-'))

    ylim(rng)
    xlim([0 xmax])

    %% RECTANGLES AT TOP
    % Determine current y-axis range and add a band of rectangles above the data.
    yl = ylim;                    % [ymin ymax] after setting ylim(rng)
    ymin = yl(1);
    ymax = yl(2);
    yrange = ymax - ymin;
    
    rect_h = yrange / 20;         % height is 1/20 of current y-range
    
    % Extend y-limits to make space for the rectangles
    ylim([ymin ymax + rect_h]);
    
    % y position where rectangles will start (just above the old ymax)
    rect_y = ymax;
    
    % ==== First rectangle: 0 to 300 ====
    rectangle('Position', [0, rect_y, 300, rect_h], ...
              'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');
    
    % ==== Middle region: bars from 300 to 1200 ====
    bar_width = 15;
    x_start = 300;
    x_end = 1200;
    
    x_positions = x_start:bar_width:(x_end - bar_width);
    
    for i = 1:length(x_positions)
        x0 = x_positions(i);
    
        % alternate colors: black, white, black, ...
        if mod(i,2)==1
            fc = 'w';     % odd → white
        else
            fc = 'k';     % even → black
        end
    
        rectangle('Position', [x0, rect_y, bar_width, rect_h], ...
                  'FaceColor', fc, ...
                  'EdgeColor', 'k');
    end
    
    % ==== Final rectangle: 1200 to xmax ====
    rectangle('Position', [1200, rect_y, xmax-1200, rect_h], ...
              'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');

    
    if params.save_figs == 1
        % Save the figure. 
        f_str = strcat("XCond_timeseries_", strain, "_", data_type, ".png");
        fname = fullfile(save_folder, f_str);
        exportgraphics(f, fname); 
        close
    end 

end 
end 
