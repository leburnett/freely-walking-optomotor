% Plotting function - generate 6 x 2 subplot with the mean + / SEM as one
% line per experimental group

function f = plot_mean_sem_diff_intervals(DATA, data_type, plot_sem)

    % Generate new figure
    figure;
    t = tiledlayout(3,2);
    t.TileSpacing = 'compact';

    experimental_groups = {
    'csw1118', 'none', 'F', [0.3 0.3 0.3]; % 1
    'csw1118', 'none', 'M', [0.7 0.7 0.7]; % 2
    };

%% For each experimental group (strain-sex):
for gp = [1, 2]

    % % Eventually have this as the input to the function 
    strain = experimental_groups{gp, 1};
    landing = experimental_groups{gp, 2};
    sex = experimental_groups{gp, 3};
    col = experimental_groups{gp, 4};

    data = DATA.(strain).(landing).(sex); 

    params ={'flicker','static','ON','OFF'};
    
    n_exp = length(data);
    exp_range = 1:n_exp;

    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    % 1 Plot acclim off

     cond_data = [];
     nf_comb = size(cond_data, 2);
    
    for idx = exp_range
        rep_data = data(idx).acclim_off1;
        rep_data = rep_data.(data_type);

        % Number of frames in each rep
        nf1 = size(rep_data, 2);

        if nf1>nf2
            nf = nf2;
        elseif nf2>nf1
            nf = nf1;
        else 
            nf = nf1;
        end 

        % Trim data to same length
        rep_data = rep_data(:, 1:nf);
        nf_comb = size(cond_data, 2);

        if idx == 1 || nf_comb == 0
            cond_data = vertcat(cond_data, rep_data);
        else
            if nf>nf_comb % trim incoming data
                rep_data = rep_data(:, 1:nf_comb);
            elseif nf_comb>nf % Add NaNs to end
                diff_f = nf_comb-nf+1;
                n_flies = size(rep_data, 1);
                rep_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
            end 
            cond_data = vertcat(cond_data, rep_data);
        end
    end 
   
        % Mean +/- SEM
        mean_data = nanmean(cond_data);
        n_flies_in_cond = size(cond_data, 1);
        % disp(strcat("Number of flies: ", num2str(n_flies_in_cond)))

        if data_type == "dist_trav" || data_type == "vel_data" 
            mean_data = movmean(mean_data, 5);
        end 

        sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
        y1 = mean_data+sem_data;
        y2 = mean_data-sem_data;
        nf_comb = size(cond_data, 2);
        x = 1:1:nf_comb;
    
        % Plot subplot for condition
        subplot(3,2,1)

        if data_type == "dist_data"
            rng = [0 85];
            ylb = 'Distance from centre (mm)';
            lw = 1.5;
        elseif data_type == "dist_trav"
            rng = [0 1];
            ylb = 'Distance travelled (mm)';
            lw = 1; 
        elseif data_type == "av_data"
            rng = [-15 15];
            ylb = "Angular velocity (deg s-1)";
            lw = 1;
        elseif data_type == "heading_data"
            rng = [0 3000];
            ylb = "Heading (deg)";
            lw = 1;
        elseif data_type == "vel_data"
            rng = [0 30];
            ylb = "Velocity (mm s-1)";
            lw = 1;
        end

        if plot_sem
            plot(x, y1, 'w', 'LineWidth', 1)
            hold on
            plot(x, y2, 'w', 'LineWidth', 1)
            patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none')
        end
        plot(mean_data, 'Color', col, 'LineWidth', lw);
        hold on
    
        % When flicker stimulus started:
        if gp == 2
            if data_type == "dist_data"
                plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
            elseif data_type == "av_data"
                plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
            end 
        end 
        xlim([0 nf_comb])
        ylim(rng)
        box off
        ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; ax.TickLength = [0.015 0.015]; ax.LineWidth = 1; ax.FontSize = 12;

        title('Acclim OFF', 'FontSize', 11)

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
        % 2 - Acclim pattern on

         cond_data = [];
         nf_comb = size(cond_data, 2);
        
        for idx = exp_range
            rep_data = data(idx).acclim_patt;
            rep_data = rep_data.(data_type);
    
            % Number of frames in each rep
            nf1 = size(rep_data, 2);
    
            if nf1>nf2
                nf = nf2;
            elseif nf2>nf1
                nf = nf1;
            else 
                nf = nf1;
            end 
    
            % Trim data to same length
            rep_data = rep_data(:, 1:nf);
            nf_comb = size(cond_data, 2);
    
            if idx == 1 || nf_comb == 0
                cond_data = vertcat(cond_data, rep_data);
            else
                if nf>nf_comb % trim incoming data
                    rep_data = rep_data(:, 1:nf_comb);
                elseif nf_comb>nf % Add NaNs to end
                    diff_f = nf_comb-nf+1;
                    n_flies = size(rep_data, 1);
                    rep_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                end 
                cond_data = vertcat(cond_data, rep_data);
            end
        end 
   
        % Mean +/- SEM
        mean_data = nanmean(cond_data);
        n_flies_in_cond = size(cond_data, 1);
        % disp(strcat("Number of flies: ", num2str(n_flies_in_cond)))

        if data_type == "dist_trav" || data_type == "vel_data" 
            mean_data = movmean(mean_data, 5);
        end 

        sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
        y1 = mean_data+sem_data;
        y2 = mean_data-sem_data;
        nf_comb = size(cond_data, 2);
        x = 1:1:nf_comb;
    
        % Plot subplot for condition
        subplot(3,2,2)

        if data_type == "dist_data"
            rng = [0 85];
            ylb = 'Distance from centre (mm)';
            lw = 1.5;
        elseif data_type == "dist_trav"
            rng = [0 1];
            ylb = 'Distance travelled (mm)';
            lw = 1; 
        elseif data_type == "av_data"
            rng = [-15 15];
            ylb = "Angular velocity (deg s-1)";
            lw = 1;
        elseif data_type == "heading_data"
            rng = [0 3000];
            ylb = "Heading (deg)";
            lw = 1;
        elseif data_type == "vel_data"
            rng = [0 30];
            ylb = "Velocity (mm s-1)";
            lw = 1;
        end

        if plot_sem
            plot(x, y1, 'w', 'LineWidth', 1)
            hold on
            plot(x, y2, 'w', 'LineWidth', 1)
            patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none')
        end
        plot(mean_data, 'Color', col, 'LineWidth', lw);
        hold on
    
        % When flicker stimulus started:
        if gp == 2
            if data_type == "dist_data"
                plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
            elseif data_type == "av_data"
                plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
            end 
        end 
        xlim([0 nf_comb])
        ylim(rng)
        box off
        ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; ax.TickLength = [0.015 0.015]; ax.LineWidth = 1; ax.FontSize = 12;

        title('Acclim - pattern', 'FontSize', 11)

      
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    % Run through the different conditions: 
    for idx2 = 1:1:4

        rep1_str = strcat('rep1_cond', string(idx2));   
        rep2_str = strcat('rep2_cond', string(idx2));  

        if isfield(data, rep1_str)

        p = params{idx2};

        cond_data = [];
        nf_comb = size(cond_data, 2);
    
        for idx = exp_range
            rep1_data = data(idx).(rep1_str);
    
            if ~isempty(rep1_data) % check that the row is not empty.
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
                nf_comb = size(cond_data, 2);
    
                if idx == 1 || nf_comb == 0
                    cond_data = vertcat(cond_data, rep1_data, rep2_data);
                else
                    if nf>nf_comb % trim incoming data
                        rep1_data = rep1_data(:, 1:nf_comb);
                        rep2_data = rep2_data(:, 1:nf_comb);
                    elseif nf_comb>nf % Add NaNs to end
                        diff_f = nf_comb-nf+1;
                        n_flies = size(rep1_data, 1);
                        rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                    end 
                    cond_data = vertcat(cond_data, rep1_data, rep2_data);
                end
            end 
        end 
   
        % Mean +/- SEM
        mean_data = nanmean(cond_data);
        n_flies_in_cond = size(cond_data, 1);
        % disp(strcat("Number of flies: ", num2str(n_flies_in_cond)))

        if data_type == "dist_trav" || data_type == "vel_data" 
            mean_data = movmean(mean_data, 5);
        end 

        sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
        y1 = mean_data+sem_data;
        y2 = mean_data-sem_data;
        nf_comb = size(cond_data, 2);
        x = 1:1:nf_comb;
    
        % Plot subplot for condition
        subplot(3,2,idx2+2)

        if data_type == "dist_data"
            rng = [0 85];
            ylb = 'Distance from centre (mm)';
            lw = 1.5;
        elseif data_type == "dist_trav"
            rng = [0 1];
            ylb = 'Distance travelled (mm)';
            lw = 1; 
        elseif data_type == "av_data"
            rng = [-15 15];
            ylb = "Angular velocity (deg s-1)";
            lw = 1;
        elseif data_type == "heading_data"
            rng = [0 3000];
            ylb = "Heading (deg)";
            lw = 1;
        elseif data_type == "vel_data"
            rng = [0 30];
            ylb = "Velocity (mm s-1)";
            lw = 1;
        end

        if plot_sem
            plot(x, y1, 'w', 'LineWidth', 1)
            hold on
            plot(x, y2, 'w', 'LineWidth', 1)
            patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none')
        end
        plot(mean_data, 'Color', col, 'LineWidth', lw);
        hold on
    
        % When flicker stimulus started:
        if gp == 2
            plot([600 600], rng, 'k', 'LineWidth', 0.5) % interval starts
            plot([300 300], rng, 'k', 'LineWidth', 0.5) % gratings change direction. 
            if data_type == "dist_data"
                plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
            elseif data_type == "av_data"
                plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
            end 
        end 
        xlim([0 nf_comb])
        ylim(rng)
        box off
        ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; ax.TickLength = [0.015 0.015]; ax.LineWidth = 1; ax.FontSize = 12;

        title(strcat('Interval stimulus - ', p), 'FontSize', 11)

        % where to position text annotation
        if gp == 1
            pos_data = [nf_comb-450, rng(2)*0.1]; 
        elseif gp == 2
            pos_data = [nf_comb-450, rng(2)*0.2];
        end 

        text(pos_data(1), pos_data(2), strcat("N = ", num2str(n_flies_in_cond)), 'Color', col);
        end 
    end 

end 

    f = gcf;
    f.Position = [618   538   577   505];
    sgtitle(ylb, 'FontSize', 16)

end 