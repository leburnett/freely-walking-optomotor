% Generate a single figure composed of different subplots for the different
% conditions. The responses of different experimental groups are overlaid
% in different colours. 

function f = plot_allcond_acrossgroups_tuning(DATA, gp_data, params, data_type, gps2plot, plot_sem)

    if data_type == "dist_data_delta"
        data_type = "dist_data";
        delta = 1;
        d_fv = 0 ;
    elseif data_type == "dist_data_fv"
        data_type = "dist_data";
        delta = 1;
        d_fv = 1;
        plot_sem = 0;
    else 
        delta = 0;
        d_fv = 0;
    end 

    % Generate new figure
    figure;
    n_cond = length(params);
    t = tiledlayout(ceil(n_cond/2),6);
    t.TileSpacing = 'compact';
    n_groups = numel(gps2plot);

    % FIX ME - at the moment this is hardcoded to 12 but might change.
    max_y_vals = zeros(12, n_groups);
    min_y_vals = zeros(12, n_groups);

%% For each experimental group (strain-sex):
for grpId = 1:n_groups
    
    gp = gps2plot(grpId);

    % % Eventually have this as the input to the function 
    strain = gp_data{gp, 1};
    sex = gp_data{gp, 2}; 
    col = gp_data{gp, 3};

    data = DATA.(strain).(sex); 

    n_exp = length(data);

    % Find out which conditions exist:
    [min_val, max_val, n_cond] = range_of_conditions(data);

    % Run through the different conditions: 
    for idx2 = min_val:1:max_val 

        rep1_str = strcat('R1_condition_', string(idx2));   
        rep2_str = strcat('R2_condition_', string(idx2));  

        if isfield(data, rep1_str)

        p = params{idx2};

        cond_data = [];
        if d_fv 
            cond_data_fv = [];
        end 
        nf_comb = size(cond_data, 2);

        fl_start_f = [];
    
        for idx = 1:n_exp
            rep1_data = data(idx).(rep1_str);
    
            if ~isempty(rep1_data) % check that the row is not empty.

                rep1_data_fv = rep1_data.fv_data;
                rep2_data_fv = data(idx).(rep2_str).fv_data;
                rep1_data_dcent = rep1_data.dist_data;
                rep2_data_dcent = data(idx).(rep2_str).dist_data;

                % Extract the relevant data
                rep1_data = rep1_data.(data_type);
                rep2_data = data(idx).(rep2_str).(data_type);
    
                % Number of frames in each rep
                nf1 = size(rep1_data, 2);
                nf2 = size(rep2_data, 2);
    
                if nf1>nf2
                    nf = nf2;
                elseif nf2>nf1
                    nf = nf1;
                else 
                    nf = nf1;
                end 

                % Trim data to same length
                rep1_data = rep1_data(:, 1:nf);
                rep2_data = rep2_data(:, 1:nf);

                rep1_data_fv = rep1_data_fv(:, 1:nf);
                rep2_data_fv = rep2_data_fv(:, 1:nf);

                nf_comb = size(cond_data, 2);
    
                if idx == 1 || nf_comb == 0
                        [rep_data, rep_data_fv] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent);
                        cond_data = vertcat(cond_data, rep_data);

                    if d_fv
                        cond_data_fv = vertcat(cond_data_fv, rep_data_fv);
                    end 
                else
                    if nf>nf_comb % trim incoming data
                        rep1_data = rep1_data(:, 1:nf_comb);
                        rep2_data = rep2_data(:, 1:nf_comb);

                        if d_fv
                            rep1_data_fv = rep1_data_fv(:, 1:nf_comb);
                            rep2_data_fv = rep2_data_fv(:, 1:nf_comb);
                        end 

                    elseif nf_comb>nf % Add NaNs to end

                        diff_f = nf_comb-nf+1;
                        n_flies = size(rep1_data, 1);
                        rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        if d_fv 
                            rep1_data_fv(:, nf:nf_comb) = NaN(n_flies, diff_f);
                            rep2_data_fv(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        end 
                    end 

                    [rep_data, rep_data_fv] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent);
                    cond_data = vertcat(cond_data, rep_data);

                        if d_fv
                            cond_data_fv = vertcat(cond_data_fv, rep_data_fv);
                        end 
                end

                fl_start = data(idx).(rep1_str).start_flicker_f;
                fl_start_f = [fl_start_f, fl_start];
  
            end 
        end 

        % "cond_data" is used from now on:
   
        % Mean +/- SEM
        mean_data = nanmean(cond_data);
        if delta == 1
            mean_data = mean_data - mean_data(300);
            if d_fv
                mean_data_fv = nanmean(cond_data_fv);
                mean_data = mean_data./mean_data_fv;
            end 
        end 
        n_flies_in_cond = size(cond_data, 1);

        % smooth data if velocity / distance travelled. 
        if data_type == "dist_trav" || data_type == "vel_data" 
            mean_data = movmean(mean_data, 5);
        end 

        sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));

        % % % % % Bin the data
        window_size = 15;
        step_size = 5;
        n_datapoints = size(mean_data, 2);
        mean_data_dwn = bin_data(mean_data, window_size, step_size, 1, n_datapoints); 
        sem_data_dwn = bin_data(sem_data, window_size, step_size, 1, n_datapoints); 

        y1 = mean_data_dwn+sem_data_dwn;
        y2 = mean_data_dwn-sem_data_dwn;
        nf_comb = size(mean_data_dwn, 2);
        x = 1:1:nf_comb;
    
        %% Plot subplot for condition
        subplot(ceil(n_cond/2), 6, (3*idx2-2):(3*idx2-1))

        % Set the ylim rng
        max_y_vals(idx2, grpId) = max(y1);
        min_y_vals(idx2, grpId) = min(y2);

        if data_type == "dist_data"
            if d_fv == 1
                ylb = 'Distance from centre / fv-data - delta (s)';
            elseif delta == 1
                ylb = 'Distance from centre - delta (mm)';
            else
                ylb = 'Distance from centre (mm)';
            end 
            lw = 1.5;
        elseif data_type == "dist_trav"
            ylb = 'Distance travelled (mm)';
            lw = 1; 
        elseif data_type == "av_data"
            % rng = [-110 110];
            ylb = "Angular velocity (deg s-1)";
            lw = 1;
        elseif data_type == "heading_data"
            ylb = "Heading (deg)";
            lw = 1;
        elseif data_type == "vel_data"
            ylb = "Velocity (mm s-1)";
            lw = 1;
        elseif data_type == "fv_data"
            ylb = "Forward velocity (mm s-1)";
            lw = 1;
        elseif data_type == "curv_data"
            ylb = "Turning rate (deg mm-1)";
            lw = 1;
        elseif data_type == "IFD_data"
            ylb = "Distance to nearest fly (mm)";
            lw = 1;
        elseif data_type == "view_dist"
            ylb = "Viewing distance (mm)";
            lw = 1;
        end

        if plot_sem
            plot(x, y1, 'w', 'LineWidth', 1)
            hold on
            plot(x, y2, 'w', 'LineWidth', 1)
            patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none')
        end
        plot(mean_data_dwn, 'Color', col, 'LineWidth', lw);
        hold on
    
        % When flicker stimulus started:
        fl = int16(mean(fl_start_f));
        if gp == gps2plot(end)

            if data_type == "dist_data"
                rng = [20 120];
                if delta 
                    rng = [-40 20];
                end 
            elseif data_type == "fv_data"
                rng = [0 20];
            else
                rng = [];
                maxx_y = max(max_y_vals(idx2, :));
                if maxx_y < 0
                    rng(2) = maxx_y*0.9;
                elseif maxx_y >=0 
                    rng(2) = maxx_y*1.1;
                end
                minn_y = min(min_y_vals(idx2, :));
                if minn_y < 0
                    rng(1) = minn_y*1.1;
                elseif minn_y >=0 
                    rng(1) = minn_y*0.9;
                end 
            end 
            ylim(rng)

            plot([fl/step_size fl/step_size], rng, 'k', 'LineWidth', 0.5)
            plot([300/step_size 300/step_size], rng, 'k', 'LineWidth', 0.5) % beginning of stim
            plot([750/step_size 740/step_size], rng, 'Color', [0.6 0.6 0.6], 'LineWidth', 0.3) % change of direction   
            if data_type == "dist_data"
                plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
            elseif data_type == "av_data" || delta == 1
                plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
            end 
        end 

        xlim([0 nf_comb])
        
        box off
        ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; ax.TickLength = [0.015 0.015]; ax.LineWidth = 1; ax.FontSize = 12;

        title(p, 'FontSize', 9)

        % where to position text annotation
        xpos = nf_comb-(450/step_size);
        rng_pos = [min_y_vals(idx2, grpId), max_y_vals(idx2, grpId)];
        pos_data = get_pos_data_nflies(xpos, rng_pos, data_type, delta, gp, gps2plot);
        text(pos_data(1), pos_data(2), strcat("N = ", num2str(n_flies_in_cond)), 'Color', col);

        %% Add Errorbar tuning curve plot
         subplot(ceil(n_cond/2), 6, 3*idx2)

        if data_type == "dist_data"
            buffer_t = 30*7;
        else
            buffer_t = 1;
        end 

        %  if data_type == "av_data" || data_type == "curv_data"
        %     mean_data = abs(mean_data);
        %     sem_data = abs(sem_data);
        % end 

        mean_pre = nanmean(mean_data(1:300));
        sem_pre = mean(sem_data(1:300));

        % flicker stim: 
        mean_flicker = nanmean(mean_data(fl+buffer_t:end));
        sem_flicker = nanmean(sem_data(fl+buffer_t:end));

        if data_type == "dist_data"
            % moving stim: 
            mean_stim1 = min(mean_data(300:750));
            sem_stim1 = nanmean(sem_data(300:750));
            mean_stim2 = min(mean_data(750:fl));
            sem_stim2 = nanmean(sem_data(750:fl));
        else
            % moving stim: 
            mean_stim1 = nanmean(mean_data(300:750));
            sem_stim1 = nanmean(sem_data(300:750));
            mean_stim2 = nanmean(mean_data(750:fl));
            sem_stim2 = nanmean(sem_data(750:fl));
        end 

        jt3 = rand(1)/4;
        % Add the scatter / error bar plot.
        errorbar(0.875+jt3, mean_pre, sem_pre, 'Color', col, 'LineWidth', 1.2)
        hold on
        % scatter(1, mean_stim, 60, col, 'Marker', 'o', 'LineWidth', 1.2, 'MarkerFaceColor', col, 'MarkerFaceAlpha', 0.2)
        scatter(0.875+jt3, mean_pre, 120, col, 'Marker', '_', 'LineWidth', 2)

        jt1 = rand(1)/4;
        % Add the scatter / error bar plot.
        errorbar(1.875+jt1, mean_stim1, sem_stim1, 'Color', col, 'LineWidth', 1.2)
        hold on
        scatter(1.875+jt1, mean_stim1, 120, col, 'Marker', '_', 'LineWidth', 2)

        jt4 = rand(1)/4;
        % Add the scatter / error bar plot.
        errorbar(2.875+jt4, mean_stim2, sem_stim2, 'Color', col, 'LineWidth', 1.2)
        hold on
        scatter(2.875+jt4, mean_stim2, 120, col, 'Marker', '_', 'LineWidth', 2)

        jt2 = rand(1)/4;
        errorbar(3.875+jt2, mean_flicker, sem_flicker, 'Color', col, 'LineWidth', 1.2)
        hold on
        % scatter(1.875+jt2, mean_flicker, 60, col, 'Marker', 'o', 'LineWidth', 1.2, 'MarkerFaceColor', col, 'MarkerFaceAlpha', 0.2)
        scatter(3.875+jt2, mean_flicker, 120, col, 'Marker', '_', 'LineWidth', 2)

        plot([0.875+jt3, 1.875+jt1, 2.875+jt4, 3.875+jt2], [mean_pre, mean_stim1, mean_stim2, mean_flicker], '-', 'LineWidth', 1.2, 'Color', col)
            
        if data_type == "dist_data" && delta == 0
            plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
        elseif data_type == "av_data" || data_type == "curv_data" || delta ==1
            plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
        end 

        xlim([0.5 4.5])
        box off
        % if data_type == "av_data" ||  data_type == "curv_data" 
        %     rng(1) = -5;
        % end 

        if gp == gps2plot(end)
            ylim(rng)
        end

        ax = gca; 
        % ax.YAxis.Visible = 'off';
        ax.TickDir = 'out';
        ax.TickLength = [0.02 0.02]; 
        ax.LineWidth = 1; 
        ax.FontSize = 12;

        xticks([1,2,3,4])
        xticklabels({''})
        xticklabels({'Int', 'Dir1', 'Dir2','Int'})
        % xtickangle(90)

        end 

    end 

end 

    f = gcf;
    f.Position = [1   161   751   886]; % new smaller size.
    % sgtitle(strcat(strrep(strain, '_', '-'), " - ", ylb), 'FontSize', 16)
    sgtitle(ylb, 'FontSize', 16)

end 