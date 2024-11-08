% Plotting function - generate 6 x 2 subplot with the mean + / SEM as one
% line per experimental group

function f = plot_mean_sem_12cond_groups(DATA, data_type, gps2plot, plot_sem)

    % Generate new figure
    figure;
    t = tiledlayout(6,2);
    t.TileSpacing = 'compact';

    cond_order = [1,3,4,2,5,7,8,6,9,11,12,10];

    experimental_groups = {
    'csw1118', 'F', [0.3 0.3 0.3];%[0 0.45 0.6]; % dark blue
    'csw1118', 'M', [0.7 0.7 0.7]; %[0.4 0.8 1];% light blue
    'jfrc49_es_kir', 'F', [0.41 0.22 0.47]; % dark purple
    'jfrc100_es_shibire', 'F', [0.85 0.4 0.7];% pink
    'ss324_t4t5_kir', 'F', [0 0.4 0]; %[1 0.6 0]; % dark green / orange
    'ss324_t4t5_shibire', 'F', [0.6 0.8 0.6];%[0.9 0.85 0.2]; % light green / yellow
    'jfrc49_l1l4_kir', 'F', [0.4 0.8 1]; %[0.6 0.6 0.6] % grey
    };

%% For each experimental group (strain-sex):
for gp = gps2plot

    % % Eventually have this as the input to the function 
    strain = experimental_groups{gp, 1};
    sex = experimental_groups{gp, 2};
    col = experimental_groups{gp, 3};

    data = DATA.(strain).(sex); 

    params =[60, 4, 2;
            60, 8, 15;
            60, 4, 15;
            60, 8, 2;
            30, 4, 2;
            30, 8, 15;
            30, 4, 15;
            30, 8, 2;
            15, 4, 2;
            15, 8, 15;
            15, 4, 15;
            15, 8, 2;
            ];
    
    n_exp = length(data);

    % Run through the different conditions: 
    for idx2 = 1:1:12 
        cond = cond_order(idx2);

        p = params(cond, :);

        cond_data = [];
        nf_comb = size(cond_data, 2);

        fl_start_f = [];
    
        rep1_str = strcat('R1_condition_', string(cond));   
        rep2_str = strcat('R2_condition_', string(cond));  
    
        % JUST DO DISTANCE DATA AT THE MOMENT:
        for idx = 1:n_exp
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

                fl_start = data(idx).(rep1_str).start_flicker_f;
                fl_start_f = [fl_start_f, fl_start];
  
            end 
        end 
   
        % Mean +/- SEM
        mean_data = nanmean(cond_data);

        if data_type == "dist_trav"
            mean_data = movmean(mean_data, 5);
        end 

        sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
        y1 = mean_data+sem_data;
        y2 = mean_data-sem_data;
        nf_comb = size(cond_data, 2);
        x = 1:1:nf_comb;
    
        % Plot subplot for condition
        subplot(6,2,idx2)

        if data_type == "dist_data"
            rng = [0 85];
            ylb = 'Distance from centre (mm)';
            lw = 2;
        elseif data_type == "dist_trav"
            rng = [0 1];
            ylb = 'Distance travelled (mm)';
            lw = 1; 
        elseif data_type == "av_data"
            rng = [-15 15];
            ylb = "Angular velocity (deg s-1)";
            lw = 1;
        elseif data_type == "heading_data"
            rng = [-6000 6000];
            ylb = "Heading (deg)";
            lw = 1.5;
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
        if gp == gps2plot(end)
            fl = mean(fl_start_f);
            plot([fl fl], rng, 'k', 'LineWidth', 0.5)
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

        title(strcat(string(p(1)), 'deg-', string(p(2)), 'Hz-', string(p(3)), 's'), 'FontSize', 11)
        
    end 

end 

    f = gcf;
    f.Position = [11    78   474   969];
    sgtitle(ylb, 'FontSize', 16)
    % ylabel(t, ylb, 'FontSize', 16)

end 