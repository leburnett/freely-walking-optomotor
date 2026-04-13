function plot_xcond_per_strain_p31(protocol, data_type, cond_ids, strain_names, params, DATA)
%PLOT_XCOND_PER_STRAIN_P31  Time series plot for Protocol 31 (speed tuning).
%
%   Identical to plot_xcond_per_strain2 except it uses a blue/green speed
%   colourmap designed for Protocol 31 grating conditions at different
%   temporal frequencies.
%
%   Colour mapping (by condition index):
%     1-4  60deg gratings: light blue (1Hz) → dark blue (8Hz)
%     5    60deg flicker:  light pink
%     6-9  15deg gratings: light pink (4Hz) → dark magenta (32Hz)
%     10   15deg flicker:  grey
%
%   INPUTS:
%     protocol     - e.g. 'protocol_31'
%     data_type    - string (e.g. "fv_data", "dist_data_delta")
%     cond_ids     - array of condition indices to plot
%     strain_names - cell array or string of strain name(s)
%     params       - struct: save_figs, plot_sem, plot_sd, plot_individ, shaded_areas
%     DATA         - (optional) struct from comb_data_across_cohorts_cond
%
%   See also: plot_xcond_per_strain2

    cfg = get_config();
    ROOT_DIR = cfg.project_root;

    if ~exist('DATA', 'var') == 1
        protocol_dir = fullfile(ROOT_DIR, 'results', protocol);
        DATA = comb_data_across_cohorts_cond(protocol_dir);
    end

    [data_type, delta] = resolve_delta_data_type(data_type);
    sex = 'F';
    xmax = 1800;

    % Speed colourmap for Protocol 31
    col_12 = [173 216 230; ...  % Cond 1: 60deg 1Hz — light blue
               82 173 227; ...  % Cond 2: 60deg 2Hz
               31 120 180; ...  % Cond 3: 60deg 4Hz — medium blue
               61  82 159; ...  % Cond 4: 60deg 8Hz — dark blue
              231 158 190; ...  % Cond 5: 60deg flicker — light pink
              243 207 226; ...  % Cond 6: 15deg 4Hz — pale pink
              231 158 190; ...  % Cond 7: 15deg 8Hz
              223 113 167; ...  % Cond 8: 15deg 16Hz
              215  48 139; ...  % Cond 9: 15deg 32Hz — dark magenta
              200 200 200; ...  % Cond 10: 15deg flicker — grey
              255 224  41; ...  % spare
              187  75  12; ...  % spare
              ] ./ 255;

    % Compute data-driven y-limits from all conditions being plotted
    y_global_min =  Inf;
    y_global_max = -Inf;

    for strain_id = 1:numel(strain_names)
        strain = strain_names{strain_id};
        for c = 1:numel(cond_ids)
            condition_n = cond_ids(c);
            data_s = DATA.(strain).(sex);
            cd_tmp = combine_timeseries_across_exp(data_s, condition_n, data_type);
            if delta
                cd_tmp = (cd_tmp - cd_tmp(:, 300)) * -1;
            end
            md_tmp = squeeze(nanmean(reshape(cd_tmp, 2, [], size(cd_tmp, 2)), 1)); %#ok<NANMEAN>
            mean_tmp = nanmean(md_tmp); %#ok<NANMEAN>

            if params.plot_sem == 1
                spread = nanstd(md_tmp) / sqrt(size(md_tmp, 1)); %#ok<NANSTD>
            elseif params.plot_sd == 1
                spread = nanstd(md_tmp); %#ok<NANSTD>
            else
                spread = zeros(size(mean_tmp));
            end

            y_global_min = min(y_global_min, min(mean_tmp - spread, [], 'omitnan'));
            y_global_max = max(y_global_max, max(mean_tmp + spread, [], 'omitnan'));
        end
    end

    % Add 10% padding
    y_pad = (y_global_max - y_global_min) * 0.10;
    rng = [y_global_min - y_pad, y_global_max + y_pad];

    %% PLOT

    hold on
    if params.shaded_areas == 1
        if data_type == "fv_data"
            rectangle('Position', [300, rng(1), 900, diff(rng)], ...
                'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
        elseif data_type == "dist_data"
            if delta == 1
                rectangle('Position', [570, rng(1), 30, diff(rng)], ...
                    'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
                rectangle('Position', [1170, rng(1), 30, diff(rng)], ...
                    'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
            else
                rectangle('Position', [270, rng(1), 30, diff(rng)], ...
                    'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
                rectangle('Position', [1170, rng(1), 30, diff(rng)], ...
                    'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
            end
        elseif data_type == "av_data" || data_type == "curv_data"
            rectangle('Position', [315, rng(1), 135, diff(rng)], ...
                'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
        end
    end

    for strain_id = 1:numel(strain_names)
        strain = strain_names{strain_id};

        for c = 1:numel(cond_ids)
            condition_n = cond_ids(c);
            col = col_12(condition_n, :);

            data = DATA.(strain).(sex);
            cond_data = combine_timeseries_across_exp(data, condition_n, data_type);
            if delta
                cond_data = (cond_data - cond_data(:, 300)) * -1;
            end

            mean_data = cond_data;
            mean_data_all = nanmean(mean_data); %#ok<NANMEAN>

            if params.plot_sem == 1
                sem_data = nanstd(mean_data) / sqrt(size(mean_data, 1)); %#ok<NANSTD>
            elseif params.plot_sd == 1
                sem_data = nanstd(mean_data); %#ok<NANSTD>
            end

            if params.plot_sem == 1 || params.plot_sd == 1
                nf_comb = size(mean_data_all, 2);
                x = 1:nf_comb;
                y1 = mean_data_all + sem_data;
                y2 = mean_data_all - sem_data;
                plot(x, y1, 'w', 'LineWidth', 1);
                plot(x, y2, 'w', 'LineWidth', 1);
                patch([x fliplr(x)], [y1 fliplr(y2)], col, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
            end

            if params.plot_individ == 1
                n_indiv = height(mean_data);
                for id = 1:n_indiv
                    plot(mean_data(id, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.7);
                end
            end

            plot(mean_data_all, 'Color', col, 'LineWidth', 2.5);
        end

        box off
        ax = gca;
        ax.TickDir = 'out';
        ax.LineWidth = 1.2;
        ax.FontSize = 14;

        ylb = get_ylb_from_data_type(data_type, delta);
        ylabel(ylb)

        xticks([0, 300, 600, 900, 1200, 1500, 1800])
        xticklabels({'-10', '0', '10', '20', '30', '40', '50'})
        xlabel('Time (s)')

        plot([300 300], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
        plot([750 750], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
        plot([1200 1200], rng, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
        plot([0 xmax], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)

        ylim(rng)
        xlim([0 xmax])

        %% Rectangles at top (stimulus annotation)
        yl = ylim;
        ymin = yl(1);  ymax = yl(2);
        yrange = ymax - ymin;
        rect_h = yrange / 20;
        ylim([ymin ymax + rect_h]);
        rect_y = ymax;

        rectangle('Position', [0, rect_y, 300, rect_h], ...
            'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');
        bar_width = 15;
        x_positions = 300:bar_width:(1200 - bar_width);
        for i = 1:length(x_positions)
            if mod(i, 2) == 1, fc = 'w'; else, fc = 'k'; end
            rectangle('Position', [x_positions(i), rect_y, bar_width, rect_h], ...
                'FaceColor', fc, 'EdgeColor', 'k');
        end
        rectangle('Position', [1200, rect_y, xmax - 1200, rect_h], ...
            'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');
    end

    f = gcf;
    f.Position = [233 511 641 460];
end
