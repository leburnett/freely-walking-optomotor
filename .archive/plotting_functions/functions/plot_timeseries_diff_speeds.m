function f = plot_timeseries_diff_speeds(DATA, strain, data_type, plot_sem)
% For p31

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

    sex = 'F';
    data = DATA.(strain).(sex);
    n_exp = length(data);

    % Find out which conditions exist:
    [min_val, max_val, n_cond] = range_of_conditions(data);
    max_y_vals = zeros(n_cond, 1);
    min_y_vals = zeros(n_cond, 1);

    % Run through the different conditions: 
    for idx2 = min_val:1:max_val 
        if idx2<6 
            subplot(1,2,1)
        else
            subplot(1,2,2)
        end 

        if strain == "jfrc100_es_shibire_kir"
            if idx2 == 1 || idx2 == 6
                col = [0, 0.5, 1];
            elseif idx2 == 2 || idx2 == 7 
                col = [0, 0.35, 0.85];
            elseif idx2 == 3 || idx2 == 8
                col = [0, 0.2, 0.7];
            elseif idx2 == 4 || idx2 == 9
                col = [0, 0.05, 0.55];
            elseif idx2 == 5 || idx2 == 10 
                col = [0, 0, 0.4];
            end 
        else
            if idx2 == 1 || idx2 == 6
                col = [1, 0.5, 0];
            elseif idx2 == 2 || idx2 == 7 
                col = [0.85, 0.35, 0];
            elseif idx2 == 3 || idx2 == 8
                col = [0.7, 0.2, 0];
            elseif idx2 == 4 || idx2 == 9
                col = [0.55, 0.05, 0];
            elseif idx2 == 5 || idx2 == 10 
                col = [0.4, 0, 0];
            end 
        end 

        rep1_str = strcat('R1_condition_', string(idx2));   
        rep2_str = strcat('R2_condition_', string(idx2));  

        if isfield(data, rep1_str)

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

        dwn_factor = 10;
        mean_data_dwn = downsample(mean_data, dwn_factor);

        sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
        sem_data_dwn = downsample(sem_data, 10);
        y1 = mean_data_dwn+sem_data_dwn;
        y2 = mean_data_dwn-sem_data_dwn;
        nf_comb = size(mean_data_dwn, 2);
        x = 1:1:nf_comb;

        % Set the ylim rng
        max_y_vals(idx2, 1) = max(y1);
        min_y_vals(idx2, 1) = min(y2);

        if data_type == "dist_data"
            if d_fv == 1
                ylb = 'Distance from centre / fv-data - delta (s)';
            elseif delta == 1
                ylb = 'Distance from centre - delta (mm)';
            else
                ylb = 'Distance from centre (mm)';
            end 
        elseif data_type == "dist_trav"
            ylb = 'Distance travelled (mm)';
        elseif data_type == "av_data"
            % rng = [-110 110];
            ylb = "Angular velocity (deg s-1)";
        elseif data_type == "heading_data"
            ylb = "Heading (deg)";
        elseif data_type == "vel_data"
            ylb = "Velocity (mm s-1)";
        elseif data_type == "fv_data"
            ylb = "Forward velocity (mm s-1)";
        elseif data_type == "curv_data"
            ylb = "Turning rate (deg mm-1)";
        elseif data_type == "IFD_data"
            ylb = "Distance to nearest fly (mm)";
        end

        lw = 1.5;

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

        if idx2 == 5 || idx2 == 10

            if idx2 == 5
                rrr = 1:5;
                title('60 deg')
            else
                rrr = 6:10;
                title('15 deg')
            end 
            if data_type == "dist_data"
                rng = [20 120];
                if delta 
                    rng = [-40 20];
                end 
            elseif data_type == "fv_data"
                rng = [0 20];
            else
                rng = [];
                maxx_y = max(max_y_vals(rrr));
                if maxx_y < 0
                    rng(2) = maxx_y*1.1;
                elseif maxx_y >=0 
                    rng(2) = maxx_y;
                end
                minn_y = min(min_y_vals(rrr));
                if minn_y < 0
                    rng(1) = minn_y*1.1;
                elseif minn_y >=0 
                    rng(1) = minn_y;
                end 
            end 
            ylim(rng)
            plot([fl/dwn_factor fl/dwn_factor], rng, 'k', 'LineWidth', 0.5)
            plot([300/dwn_factor 300/dwn_factor], rng, 'k', 'LineWidth', 0.5) % beginning of stim
            plot([750/dwn_factor 740/dwn_factor], rng, 'Color', [0.6 0.6 0.6], 'LineWidth', 0.3) % change of direction   
            if data_type == "dist_data" && delta == 0
                plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
            elseif data_type == "av_data" || delta == 1
                plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
            end 
        end 

        xlim([0 nf_comb])
        
        box off
        ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; ax.TickLength = [0.015 0.015]; ax.LineWidth = 1; ax.FontSize = 12;
        
        end 

    end 

    f = gcf;
    f.Position = [335   520   818   356]; 
    sgtitle(ylb, 'FontSize', 16)

end 