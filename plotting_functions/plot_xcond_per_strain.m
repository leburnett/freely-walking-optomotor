function plot_xcond_per_strain(protocol, data_type, save_figs, DATA)
    
    close all
    
    ROOT_DIR = "/Users/burnettl/Documents/Projects/oaky_cokey/";
    
    % protocol = "protocol_27";
    % data_type = "fv_data"; 
    
    if ~exist('DATA', 'var') == 1
        % Move to the directory to where the results per experiment are saved:
        protocol_dir = fullfile(ROOT_DIR, 'results', protocol);
        cd(protocol_dir);
        % Generate the struct 'DATA' that combines data across experiments and
        % separates data into conditions.
        DATA = comb_data_across_cohorts_cond(protocol_dir);
    end 

    strain_names = fieldnames(DATA);
    
    % % Where to save the figures:
    date_str = string(datetime("today", "Format", "yyyy_MM_dd"));
    save_folder = fullfile(ROOT_DIR, "figures", protocol, "Xcond_per_strain", date_str);
    if ~isfolder(save_folder)
        mkdir(save_folder)
    end 
    
    % % Initialise parameters:
    delta = 0;
    tiled_plot = 0;
    leg = 1;
    sex = 'F';
    plot_sem = 0;

    if protocol == "protocol_27"

        xmax = 2255;

        % Conditions: 
        cond_ids = 1:12;
        cond_titles = {"60deg-gratings-4Hz"...
                    , "60deg-gratings-8Hz"...
                    , "narrow-ON-bars-4Hz"...
                    , "narrow-OFF-bars-4Hz"...
                    , "ON-curtains-8Hz"...
                    , "OFF-curtains-8Hz"...
                    , "reverse-phi-2Hz"...
                    , "reverse-phi-4Hz"...
                    , "60deg-flicker-4Hz"...
                    , "60deg-gratings-static"...
                    , "60deg-gratings-0-8-offset"...
                    , "32px-ON-single-bar"...
                    };

        % Colourmap:
        col_12 = [166 206 227; ...
            31 120 180; ...
            178 223 138; ...
            47 141 41; ...
            251 154 153; ...
            227 26 28; ...
            253 191 111; ...
            255 127 0; ...
            202 178 214; ...
            106 61 154; ...
            255 224 41; ...
            187 75 12; ...
            ]./255;

    elseif protocol == "protocol_31"

        xmax = 2255;

        % Conditions: 
        cond_ids = 1:10;
        cond_titles = {"60deg-gratings-1Hz"...
                    , "60deg-gratings-2Hz"...
                    , "60deg-gratings-4Hz"...
                    , "60deg-gratings-8Hz"...
                    , "60deg-flicker-4Hz"...
                    , "15deg-gratings-4Hz"...
                    , "15deg-gratings-8Hz"...
                    , "15deg-gratings-16Hz"...
                    , "15deg-gratings-32Hz"...
                    , "15deg-flicker-4Hz"...
                    };

        % Colourmap:
        col_12 = [15 60 120; ...%blues - dark to light (slow to fast)
            31 120 180; ... 
            62 160 200; ...
            166 206 227; ... 
            106 61 154; ... % purple
            150 13 14; ...
            190 55 70; ...
            235 90 110; ...
            251 170 170; ... % reds
            255 140 20; ... % orange
            ]./255;
    end 
        
    if data_type == "fv_data" 
        tiled_plot = 1;
        rng = [0 20];
    elseif data_type == "dist_data_delta"
        delta = 1;
        data_type = "dist_data";
        rng = [-40 15];
    elseif data_type == "dist_data"
        rng = [20 100];
    elseif data_type == "view_dist"
        rng = [60 140];
    elseif data_type == "dist_dt"
        rng = [-7 5];
    elseif data_type == "av_data" || data_type == "curv_data" 
        rng = [-250 250];
    end 
    
    %% PLOT 
    
    if tiled_plot % Subplots per condition - fv_data
    
        for strain_id = 1:numel(strain_names)
        
            strain = strain_names{strain_id};
        
            figure
            tiledlayout(numel(cond_ids), 1, 'TileSpacing','tight', 'Padding', 'compact');
            
            for c = 1:numel(cond_ids)
            
                nexttile
                condition_n = cond_ids(c);
                col = col_12(c, :);
            
                data = DATA.(strain).(sex);
                cond_data = combine_timeseries_across_exp(data, condition_n, data_type);
                if delta
                    cond_data = cond_data - cond_data(:, 300); % relative
                end 
                mean_data = nanmean(cond_data);
                sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
            
                y1 = mean_data+sem_data;
                y2 = mean_data-sem_data;
                nf_comb = size(mean_data, 2);
                x = 1:1:nf_comb;
            
                plot(x, y1, 'w', 'LineWidth', 1)
                hold on
                plot(x, y2, 'w', 'LineWidth', 1)
                patch([x fliplr(x)], [y1 fliplr(y2)], col, 'FaceAlpha', 0.1, 'EdgeColor', 'none')
                plot(mean_data, 'Color', col, 'LineWidth', 2);
            
                box off
                ax = gca;
                ax.TickDir = 'out';
                ax.LineWidth = 1.2;
                ax.FontSize = 12;
                ax.XAxis.Visible = 'off';
            
                % Add vertical lines for start, middle and end of stim.
                plot([300 300], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
                if c ~= numel(cond_ids)
                    plot([750 750], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
                    plot([1200 1200], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)  
                end 
            
                ylim(rng)
                xlim([0 1800])
            end 
            
            ylb = get_ylb_from_data_type(data_type, delta);
            sgtitle(strrep(strcat(strain, " : ", ylb), '_', '-'))
            
            f = gcf;
            f.Position = [557 1 541  1046];
        
            if save_figs == 1
                % Save the figure. 
                f_str = strcat("XCond_timeseries_tiled_", strain, "_", data_type, ".png");
                fname = fullfile(save_folder, f_str);
                exportgraphics(f, fname); 
                close
            end 
        end 
    
    else % Overlaid on one plot
    
        for strain_id = 1:numel(strain_names)
        
            strain = strain_names{strain_id};
            
            figure
            for c = 1:numel(cond_ids)
            
                condition_n = cond_ids(c);
                col = col_12(c, :);
            
                data = DATA.(strain).(sex);
                cond_data = combine_timeseries_across_exp(data, condition_n, data_type); % absolute
                if delta
                    cond_data = cond_data - cond_data(:, 300); % relative
                end 
            
                mean_data = nanmean(cond_data);
                sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
            
                y1 = mean_data+sem_data;
                y2 = mean_data-sem_data;
                nf_comb = size(mean_data, 2);
                x = 1:1:nf_comb;
            
                if plot_sem == 1
                    plot(x, y1, 'w', 'LineWidth', 1)
                    hold on
                    plot(x, y2, 'w', 'LineWidth', 1)
                    patch([x fliplr(x)], [y1 fliplr(y2)], col, 'FaceAlpha', 0.1, 'EdgeColor', 'none')
                end 
                plot(mean_data, 'Color', col, 'LineWidth', 2);
                hold on
            end 
            
            if leg == 1
                lg = legend(cond_titles);
                lg.Position = [0.6690    0.1404    0.2268    0.3011]; % p31
                % lg.Position = [0.6103    0.1551    0.2761    0.4244]; %p27
            end 
            
            box off
            ax = gca;
            ax.TickDir = 'out';
            ax.LineWidth = 1.2;
            ax.FontSize = 12;
            
            f = gcf;
            % f.Position = [233   581   603   390]; % p27
            f.Position = [233   511   641   460]; % p31
            
            ylb = get_ylb_from_data_type(data_type, delta);
            ylabel(ylb)
            
            xticks([0, 300, 600, 900, 1200, 1500, 1800, 2100, 2400])
            xticklabels({'0', '10', '20', '30', '40', '50', '60', '70', '80'})
            xlabel('Time (s)')
            
            if legend == 0
                % Add vertical lines for start, middle and end of stim.
                plot([300 300], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
                plot([750 750], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5) % beginning of stim
                plot([1200 1200], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5) % change of direction   
                
                plot([0 2255], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5) % change of direction   
            end 
                
            title(strrep(strain, '_', '-'))
        
            ylim(rng)
            xlim([0 xmax])
            
            if save_figs == 1
                % Save the figure. 
                f_str = strcat("XCond_timeseries_", strain, "_", data_type, ".png");
                fname = fullfile(save_folder, f_str);
                exportgraphics(f, fname); 
                close
            end 
        
        end 
    end 
end 
