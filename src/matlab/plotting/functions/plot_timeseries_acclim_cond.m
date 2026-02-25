function f = plot_timeseries_acclim_cond(DATA, gp_data, gps2plot, data_type, plot_sem, plot_ind_cohorts, acclim_cond)

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
    t = tiledlayout(1,3);
    t.TileSpacing = 'compact';
    n_groups = numel(gps2plot);
    subplot(1, 3, 1:2)

    % FIX ME - at the moment this is hardcoded to 12 but might change.
    max_y_vals = zeros(12, n_groups);
    min_y_vals = zeros(12, n_groups);

    dwn_factor = 10;

%% For each experimental group (strain-sex):
for grpId = 1:n_groups
    
    gp = gps2plot(grpId);

    % % Eventually have this as the input to the function 
    strain = gp_data{gp, 1};
    sex = gp_data{gp, 2}; 
    col = gp_data{gp, 3};

    data = DATA.(strain).(sex); 
    n_exp = length(data); % Number of experimental vials ran for that strain. 

    cond_data = [];
    if d_fv 
        cond_data_fv = [];
    end 
    nf_comb = size(cond_data, 2);

    subplot(1, 3, 1:2)

    for idx = 1:n_exp

        acclim_data = data(idx).(acclim_cond);

        if ~isempty(acclim_data) % check that the row is not empty.

            acclim_data_fv = acclim_data.fv_data;
            acclim_data_dcent = acclim_data.dist_data;

            % Extract the relevant data
            acclim_data = acclim_data.(data_type);

            % Number of frames in each rep
            nf = size(acclim_data, 2);

            % Trim data to same length
            acclim_data = acclim_data(:, 1:nf);
            acclim_data_fv = acclim_data_fv(:, 1:nf);

            nf_comb = size(cond_data, 2);

            if idx == 1 || nf_comb == 0
                [rep_data, rep_data_fv] = check_single_rep(acclim_data, acclim_data_fv, acclim_data_dcent);
                cond_data = vertcat(cond_data, rep_data);

                if d_fv
                    cond_data_fv = vertcat(cond_data_fv, rep_data_fv);
                end 
            else
                if nf>nf_comb % trim incoming data
                    acclim_data = acclim_data(:, 1:nf_comb);

                    if d_fv
                        acclim_data_fv = acclim_data_fv(:, 1:nf_comb);
                    end 

                elseif nf_comb>nf % Add NaNs to end

                    diff_f = nf_comb-nf+1;
                    n_flies = size(acclim_data, 1);
                    acclim_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                    if d_fv 
                        acclim_data_fv(:, nf:nf_comb) = NaN(n_flies, diff_f);
                    end 
                end 

                [rep_data, rep_data_fv] = check_single_rep(acclim_data, acclim_data_fv, acclim_data_dcent);
                cond_data = vertcat(cond_data, rep_data);

                    if d_fv
                        cond_data_fv = vertcat(cond_data_fv, rep_data_fv);
                    end 
            end

            if plot_ind_cohorts
                % Plot the mean of each individual cohort 
                mean_data_dwn = downsample(nanmean(cond_data), dwn_factor);
                if delta
                    mean_data_dwn = mean_data_dwn-mean_data_dwn(1);
                end 
                plot(mean_data_dwn, 'Color', [col 0.2], 'LineWidth', 1); 
                hold on;
            end 

        end 
    end 

    % Mean +/- SEM
    mean_data = nanmean(cond_data);
    if delta == 1
        mean_data = mean_data - mean_data(1);
        if d_fv
            mean_data_fv = nanmean(cond_data_fv);
            mean_data = mean_data./mean_data_fv;
        end 
    end 
    % n_flies_in_cond = size(cond_data, 1);

    % smooth data if velocity / distance travelled. 
    if data_type == "dist_trav" || data_type == "vel_data" 
        mean_data = movmean(mean_data, 5);
    end 

    mean_data_dwn = downsample(mean_data, dwn_factor);

    sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
    sem_data_dwn = downsample(sem_data, 10);
    y1 = mean_data_dwn+sem_data_dwn;
    y2 = mean_data_dwn-sem_data_dwn;
    nf_comb = size(mean_data_dwn, 2);
    x = 1:1:nf_comb;

    %% Plot subplot for condition

    subplot(1, 3, 1:2)
    % Set the ylim rng
    max_y_vals(1, grpId) = max(y1);
    min_y_vals(1, grpId) = min(y2);

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
    end

    if plot_sem
        plot(x, y1, 'w', 'LineWidth', 1)
        hold on
        plot(x, y2, 'w', 'LineWidth', 1)
        patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none')
    end
    plot(mean_data_dwn, 'Color', col, 'LineWidth', lw);
    hold on

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
            maxx_y = max(max_y_vals(1, :));
            if maxx_y < 0
                rng(2) = maxx_y*1.1;
            elseif maxx_y >=0 
                rng(2) = maxx_y*0.9;
            end
            minn_y = min(min_y_vals(1, :));
            if minn_y < 0
                rng(1) = minn_y*1.1;
            elseif minn_y >=0 
                rng(1) = minn_y*0.9;
            end 
        end 
        ylim(rng)
 
        if data_type == "dist_data" && delta == 0
            plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
        elseif data_type == "av_data" || delta == 1
            plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
        end 
    end 

    xlim([0 nf_comb])
    
    box off
    ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; ax.TickLength = [0.015 0.015]; ax.LineWidth = 1; ax.FontSize = 12;

    title(strrep(acclim_cond, '_', '-'), 'FontSize', 9)

    %% Add Errorbar tuning curve plot
    subplot(1, 3, 3)

    mean_acclim = nanmean(mean_data);
    sem_acclim = nanmean(sem_data);

    jt3 = rand(1)/4;
    % Add the scatter / error bar plot.
    errorbar(0.875+jt3, mean_acclim, sem_acclim, 'Color', col, 'LineWidth', 1.2)
    hold on
    scatter(0.875+jt3, mean_acclim, 120, col, 'Marker', '_', 'LineWidth', 2)
        
    if data_type == "dist_data" && delta == 0
        plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
    elseif delta ==1
        plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
    end 

    xlim([0.5 1.5])
    box off
    if data_type == "av_data" ||  data_type == "curv_data" 
        rng(1) = -5;
    end 

    if gp == gps2plot(end)
        ylim(rng)
    end 
    ax = gca; 
    ax.TickDir = 'out';
    ax.TickLength = [0.02 0.02]; 
    ax.LineWidth = 1; 
    ax.FontSize = 12;

    xticks([1,2,3,4])
    xticklabels({''})
    xticklabels({strrep(acclim_cond, '_', '-')})

end 

    f = gcf;
    f.Position = [57   781   679   191];
    sgtitle(ylb, 'FontSize', 16)

end 

