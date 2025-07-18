% Plotting function - generate 6 x 2 subplot with the mean + / SEM as one
% line per experimental group

function f = plot_mean_sem_12cond_groups(DATA, data_type, gps2plot, plot_sem)

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

    n_cond = height(params);

    % Generate new figure
    figure;
    t = tiledlayout(n_cond/2,6);
    t.TileSpacing = 'compact';

    cond_order = [1,3,4,2,5,7,8,6,9,11,12,10];

   experimental_groups = {
        'csw1118', 'none', 'F', [0.3 0.3 0.3]; % 1
        'csw1118', 'none', 'M', [0.7 0.7 0.7]; % 2
        'jfrc49_es_kir', 'attP2', 'F',  [0.51 0.32 0.57]; % 3
        'jfrc49_es_kir', 'attP2', 'M',  [0.51 0.32 0.57]; % 4  - - none?
        'jfrc49_es_kir', 'attP6', 'F',  [0.31 0.12 0.37]; % 5
        'jfrc49_es_kir', 'attP6', 'M',  [0.31 0.12 0.37]; % 6 - - - none at the moment.
        'jfrc100_es_shibire', 'attP5', 'F', [0.85 0.4 0.7]; % 7
        'jfrc100_es_shibire', 'attP5', 'M', [0.85 0.4 0.7]; % 8
        'ss324_t4t5_kir', 'attP2', 'F', [0 0.4 0]; % 9
        'ss324_t4t5_kir', 'attP2', 'M', [0 0.4 0]; % 10
        'ss324_t4t5_shibire', 'attP5', 'F', [0.6 0.8 0.6]; % 11
        'ss324_t4t5_shibire', 'attP5', 'M', [0.6 0.8 0.6]; % 12
        'ss324_t4t5_shibire_kir', 'none', 'F', [0, 0, 0]; % 13
        'ss324_t4t5_shibire_kir', 'none', 'M', [0, 0, 0]; % 14
        'jfrc49_l1l4_kir', 'attP2', 'F', [0.2 0.4 0.7]; %15
        'jfrc49_l1l4_kir', 'attP2', 'M', [0.2 0.4 0.7]; %16
        'jfrc49_l1l4_kir', 'attP6', 'F', [0.4 0.6 1]; % 17 
        'jfrc49_l1l4_kir', 'attP6', 'M', [0.4 0.6 1]; % 18 
        'jfrc49_l1l4_kir', 'VK00005', 'F', [0.1 0.2 0.5]; %19
        'jfrc49_l1l4_kir', 'VK00005', 'M', [0.1 0.2 0.5]; %20
        'l1l4_jfrc100_shibire', 'attP5', 'F', [0.4 0.8 1]; %21
        'l1l4_jfrc100_shibire', 'attP5', 'M', [0.4 0.8 1]; % 22
        't4t5_RNAi_control', 'none', 'F', [0.7 0.7 0.7]; %23
        't4t5_mmd_RNAi', 'none', 'F', [0.8, 0 , 0]; % 24
        't4t5_ttl_RNAi', 'none', 'F', [0.9, 0.5, 0]; % 25
        };

%% For each experimental group (strain-sex):
for gp = gps2plot

    % % Eventually have this as the input to the function 
    strain = experimental_groups{gp, 1};
    landing = experimental_groups{gp, 2};
    sex = experimental_groups{gp, 3};
    col = experimental_groups{gp, 4};

    data = DATA.(strain).(landing).(sex); 

    n_exp = length(data);

    % Find out which conditions exist:
    [min_val, max_val] = range_of_conditions(data);

    % Run through the different conditions: 
    for idx2 = min_val:1:max_val 
        cond = cond_order(idx2);
        rep1_str = strcat('R1_condition_', string(cond));   
        rep2_str = strcat('R2_condition_', string(cond));  

        if isfield(data, rep1_str)

        p = params(cond, :);

        cond_data = [];
        nf_comb = size(cond_data, 2);

        fl_start_f = [];
    
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
        subplot(n_cond/2, 6, (3*idx2-2):(3*idx2-1))

        if data_type == "dist_data"
            rng = [0 85];
            ylb = 'Distance from centre (mm)';
            lw = 1.5;
        elseif data_type == "dist_trav"
            rng = [0 1];
            ylb = 'Distance travelled (mm)';
            lw = 1; 
        elseif data_type == "av_data"
            rng = [-200 200];
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
        elseif data_type == "fv_data"
            rng = [0 30];
            ylb = "Forward velocity (mm s-1)";
            lw = 1;
        elseif data_type == "curv_data"
            rng = [-200 200];
            ylb = "Turning rate (deg mm-1)";
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
        fl = int16(mean(fl_start_f));
        if gp == gps2plot(end)
            plot([300 300], rng, 'k', 'LineWidth', 0.5)
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

        % where to position text annotation
        if rng(1)==0 && data_type~="fv_data"
            if gp == gps2plot(1)
                pos_data = [nf_comb-450, rng(2)*0.1]; 
            elseif gp == gps2plot(2)
                pos_data = [nf_comb-450, rng(2)*0.2];
            elseif gp == gps2plot(3)
                pos_data = [nf_comb-450, rng(2)*0.3];
            elseif gp == gps2plot(4)
                pos_data = [nf_comb-450, rng(2)*0.4];
            elseif gp == gps2plot(5)
                pos_data = [nf_comb-450, rng(2)*0.5];
            end 
        elseif data_type == "fv_data"
            if gp == gps2plot(1)
                pos_data = [nf_comb-450, rng(2)*0.9]; 
            elseif gp == gps2plot(2)
                pos_data = [nf_comb-450, rng(2)*0.8];
            elseif gp == gps2plot(3)
                pos_data = [nf_comb-450, rng(2)*0.7];
            elseif gp == gps2plot(4)
                pos_data = [nf_comb-450, rng(2)*0.6];
            elseif gp == gps2plot(5)
                pos_data = [nf_comb-450, rng(2)*0.5];
            end 
        else
            if gp == gps2plot(1)
                pos_data = [nf_comb-450, rng(2)*0.9]; 
            elseif gp == gps2plot(2)
                pos_data = [nf_comb-450, rng(2)*0.7];
            elseif gp == gps2plot(3)
                pos_data = [nf_comb-450, rng(2)*0.5];
            elseif gp == gps2plot(4)
                pos_data = [nf_comb-450, rng(2)*0.3];
            elseif gp == gps2plot(5)
                pos_data = [nf_comb-450, rng(2)*0.1];
            end 
        end  

        text(pos_data(1), pos_data(2), strcat("N = ", num2str(n_flies_in_cond)), 'Color', col);

        %% Add Errorbar tuning curve plot
             subplot(n_cond/2, 6, 3*idx2)

            if data_type == "dist_data"
                buffer_t = 30*7;
            else
                buffer_t = 1;
            end 
    
            if data_type == "av_data" || data_type == "curv_data"
                mean_data = abs(mean_data);
                sem_data = abs(sem_data);
            end 
    
            mean_pre = mean(mean_data(1:300));
            sem_pre = mean(sem_data(1:300));
    
            % flicker stim: 
            mean_flicker = mean(mean_data(fl+buffer_t:end));
            sem_flicker = mean(sem_data(fl+buffer_t:end));
    
            if data_type == "dist_data"
                % moving stim: 
                mean_stim1 = min(mean_data(300:750));
                sem_stim1 = mean(sem_data(300:750));
                mean_stim2 = min(mean_data(750:fl));
                sem_stim2 = mean(sem_data(750:fl));
            else
                % moving stim: 
                mean_stim1 = mean(mean_data(300:750));
                sem_stim1 = mean(sem_data(300:750));
                mean_stim2 = mean(mean_data(750:fl));
                sem_stim2 = mean(sem_data(750:fl));
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
                
            if data_type == "dist_data"
                plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
            elseif data_type == "av_data" || data_type == "curv_data"
                plot([0 nf_comb], [0 0], 'k:', 'LineWidth', 0.5)
            end 
    
            xlim([0.5 4.5])
            box off
            ylim(rng)
            ax = gca; 
            ax.YAxis.Visible = 'off';
            ax.TickDir = 'out';
            ax.TickLength = [0.015 0.015]; 
            ax.LineWidth = 1; 
            ax.FontSize = 12;
    
            xticks([1,2,3,4])
            xticklabels({''})
            xticklabels({'B4', 'ST1', 'ST2','FL'})
            xtickangle(90)

        end 
    end 

end 

    f = gcf;
    f.Position = [1  78  1044 969];
    sgtitle(ylb, 'FontSize', 16)

end 