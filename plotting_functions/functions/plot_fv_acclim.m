% % Assess general locomotion and turning behaviour of the flies during the
% OFF acclim and ON acclim periods. 

%% 1 - PLOT TIMESERIES

figure 

for gp = gps2plot

    % % Eventually have this as the input to the function 
    strain = gp_data{gp, 1};
    landing = gp_data{gp, 2};
    sex = gp_data{gp, 3};
    col = gp_data{gp, 4};

    data = DATA.(strain).(landing).(sex); 
    n_exp = length(data);

    d1 = [];
    d2 = [];
    d3 = [];

    for idx = 1:n_exp

        accOFF1_data = data(idx).acclim_off1.(data_type);
        if size(accOFF1_data, 2)<600
            n_flies =  size(accOFF1_data, 1);
            data1 = nan(n_flies, 600);
            data1(:, 1:size(accOFF1_data, 2)) = accOFF1_data;
        else 
            data1 = accOFF1_data(:, 1:600);
        end 

        accPATT_data = data(idx).acclim_patt.(data_type);
        if size(accPATT_data, 2)<600
            n_flies =  size(accPATT_data, 1);
            data2 = nan(n_flies, 600);
            data2(:, 1:size(accPATT_data, 2)) = accPATT_data;
        else 
            data2 = accPATT_data(:, 1:600);
        end 

        accOFF2_data = data(idx).acclim_off2.(data_type);
        if size(accOFF2_data, 2)<600
            n_flies =  size(accOFF2_data, 1);
            data3 = nan(n_flies, 600);
            data3(:, 1:size(accOFF2_data, 2)) = accOFF2_data;
        else 
            data3 = accOFF2_data(:, 1:600);
        end 

        d1 = vertcat(d1, data1);
        d2 = vertcat(d2, data2);
        d3 = vertcat(d3, data3);

    end 


    if data_type == "dist_data"
        rng = [0 80];
        ylb = 'Distance from centre (mm)';
        lw = 1.5;
    elseif data_type == "dist_trav"
        rng = [0 1];
        ylb = 'Distance travelled (mm)';
        lw = 1; 
    elseif data_type == "av_data"
        rng = [-30 30];
        ylb = "Angular velocity (deg s-1)";
        lw = 1;
    elseif data_type == "heading_data"
        rng = [0 3000];
        ylb = "Heading (deg)";
        lw = 1;
    elseif data_type == "vel_data"
        rng = [0 20];
        ylb = "Velocity (mm s-1)";
        lw = 1;
    elseif data_type == "fv_data"
        rng = [0 22];
        ylb = "Forward velocity (mm s-1)";
        lw = 1;
    elseif data_type == "curv_data"
        rng = [-30 30];
        ylb = "Turning rate (deg mm-1)";
        lw = 1;
    end

   %% ACCLIM OFF 

   subplot(1,3,1)

    % Mean +/- SEM
    mean_data = nanmean(d1);
    n_flies_in_cond = size(d1, 1);

    % smooth data if velocity / distance travelled. 
    if data_type == "dist_trav" || data_type == "vel_data" || data_type == "fv_data" 
        mean_data = movmean(mean_data, 5);
    end 

    sem_data = nanstd(d1)/sqrt(size(d1,1));
    y1 = mean_data+sem_data;
    y2 = mean_data-sem_data;

    x = 1:1:600;

    if plot_sem
        plot(x, y1, 'w', 'LineWidth', 1)
        hold on
        plot(x, y2, 'w', 'LineWidth', 1)
        patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none')
    end
    plot(mean_data, 'Color', col, 'LineWidth', lw);

    xticks([0 300 600])
    xticklabels({'0', '10', '20'})
    xlabel('Time (s)')
    ylim(rng)
    box off
    ax = gca;
    ax.TickDir = 'out';
    title('OFF start')
    ylabel(ylb)

    %% ACCLIM PATT

    subplot(1,3,2)

    % Mean +/- SEM
    mean_data = nanmean(d2);
    n_flies_in_cond = size(d2, 1);

    % smooth data if velocity / distance travelled. 
    if data_type == "dist_trav" || data_type == "vel_data" 
        mean_data = movmean(mean_data, 5);
    end 

    sem_data = nanstd(d2)/sqrt(size(d2,1));
    y1 = mean_data+sem_data;
    y2 = mean_data-sem_data;

    if plot_sem
        plot(x, y1, 'w', 'LineWidth', 1)
        hold on
        plot(x, y2, 'w', 'LineWidth', 1)
        patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none')
    end
    plot(mean_data, 'Color', col, 'LineWidth', lw);
    xticks([0 300 600])
    xticklabels({'0', '10', '20'})
    xlabel('Time (s)')
    ylim(rng)
    box off
    ax = gca;
    ax.TickDir = 'out';
    title('Static pattern')

    %% ACCLIM OFF 2

    subplot(1,3,3)

    % Mean +/- SEM
    mean_data = nanmean(d3);
    n_flies_in_cond = size(d3, 1);

    % smooth data if velocity / distance travelled. 
    if data_type == "dist_trav" || data_type == "vel_data" 
        mean_data = movmean(mean_data, 5);
    end 

    sem_data = nanstd(d3)/sqrt(size(d3,1));
    y1 = mean_data+sem_data;
    y2 = mean_data-sem_data;

    if plot_sem
        plot(x, y1, 'w', 'LineWidth', 1)
        hold on
        plot(x, y2, 'w', 'LineWidth', 1)
        patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none')
    end
    plot(mean_data, 'Color', col, 'LineWidth', lw);
    xticks([0 300 600])
    xticklabels({'0', '10', '20'})
    xlabel('Time (s)')
    ylim(rng)
    box off
    ax = gca;
    ax.TickDir = 'out';
    title('OFF end')

end 

f = gcf;
f.Position = [5 863 1796 184]; %[5  662  1796  385];
















%% Plot DATA POINTS - SCATTER and ERRORBAR


figure 

group_id = 1;

for gp = gps2plot

    % % Eventually have this as the input to the function 
    strain = gp_data{gp, 1};
    landing = gp_data{gp, 2};
    sex = gp_data{gp, 3};
    col = gp_data{gp, 4};

    data = DATA.(strain).(landing).(sex); 
    n_exp = length(data);

    d1 = [];
    d2 = [];
    d3 = [];

    for idx = 1:n_exp

        accOFF1_data = data(idx).acclim_off1.(data_type);
        if size(accOFF1_data, 2)<600
            n_flies =  size(accOFF1_data, 1);
            data1 = nan(n_flies, 600);
            data1(:, 1:size(accOFF1_data, 2)) = accOFF1_data;
        else 
            data1 = accOFF1_data(:, 1:600);
        end 

        accPATT_data = data(idx).acclim_patt.(data_type);
        if size(accPATT_data, 2)<600
            n_flies =  size(accPATT_data, 1);
            data2 = nan(n_flies, 600);
            data2(:, 1:size(accPATT_data, 2)) = accPATT_data;
        else 
            data2 = accPATT_data(:, 1:600);
        end 

        accOFF2_data = data(idx).acclim_off2.(data_type);
        if size(accOFF2_data, 2)<600
            n_flies =  size(accOFF2_data, 1);
            data3 = nan(n_flies, 600);
            data3(:, 1:size(accOFF2_data, 2)) = accOFF2_data;
        else 
            data3 = accOFF2_data(:, 1:600);
        end 

        d1 = vertcat(d1, data1);
        d2 = vertcat(d2, data2);
        d3 = vertcat(d3, data3);

    end 

    if data_type == "dist_data"
        rng = [0 80];
        ylb = 'Distance from centre (mm)';
        lw = 1.5;
    elseif data_type == "dist_trav"
        rng = [0 1];
        ylb = 'Distance travelled (mm)';
        lw = 1; 
    elseif data_type == "av_data"
        rng = [-30 30];
        ylb = "Angular velocity (deg s-1)";
        lw = 1;
    elseif data_type == "heading_data"
        rng = [0 3000];
        ylb = "Heading (deg)";
        lw = 1;
    elseif data_type == "vel_data"
        rng = [0 20];
        ylb = "Velocity (mm s-1)";
        lw = 1;
    elseif data_type == "fv_data"
        rng = [0 22];
        ylb = "Forward velocity (mm s-1)";
        lw = 1;
    elseif data_type == "curv_data"
        rng = [-30 30];
        ylb = "Turning rate (deg mm-1)";
        lw = 1;
    end

   %% ACCLIM OFF 

   subplot(1,3,1)

    % Mean +/- SEM
    mean_data = max(d1');
    mean_gp = median(mean_data);
    n_ind = size(d1, 1);
    sem_data = nanstd(mean_data); %/sqrt(n_ind);

    % Plot each fly as an individual data point
    for id = 1:n_ind
        jit_num = group_id + (rand(1,1)/5)-0.1;
        mean_ind = max(d1(id, :));
        plot(jit_num, mean_ind, 'o', 'Color', [0.88 0.88 0.88], 'MarkerSize', 10);
        hold on
    end 

    errorbar(group_id, mean_gp, sem_data, 'Color', col, 'LineWidth', lw, 'CapSize', 10);
    plot([group_id-0.1, group_id+0.1], [mean_gp mean_gp], '-', 'Color', col, 'LineWidth', lw);

    xlim([0 3.5])
    xticks([1,2,3])
    xticklabels({''})
    box off
    ax = gca;
    ax.TickDir = 'out';
    ax.LineWidth = 1.2;
    ax.TickLength = [0.02 0.02];
    title('OFF start')
    ylabel(ylb)

    ylim([0 55])

    %% ACCLIM PATT

    subplot(1,3,2)

    % Mean +/- SEM
    mean_data = max(d2');
    mean_gp = median(mean_data);
    n_ind = size(d2, 1);
    sem_data = nanstd(mean_data); %/sqrt(n_ind);

    % Plot each fly as an individual data point
    for id = 1:n_ind
        jit_num = group_id + (rand(1,1)/5)-0.1;
        mean_ind = max(d2(id, :));
        plot(jit_num, mean_ind, 'o', 'Color', [0.88 0.88 0.88], 'MarkerSize', 10);
        hold on
    end 

    errorbar(group_id, mean_gp, sem_data, 'Color', col, 'LineWidth', lw, 'CapSize', 10);
    plot([group_id-0.1, group_id+0.1], [mean_gp mean_gp], '-', 'Color', col, 'LineWidth', lw);

    xlim([0 3.5])
    xticks([1,2,3])
    xticklabels({''})
    box off
    ax = gca;
    ax.TickDir = 'out';
    ax.LineWidth = 1.2;
    ax.TickLength = [0.02 0.02];
    title('Static pattern')

    ylim([0 55])

    %% ACCLIM OFF 2

    subplot(1,3,3)

    % Mean +/- SEM
    mean_data = max(d3');
    mean_gp = median(mean_data);
    n_ind = size(d3, 1);
    sem_data = nanstd(mean_data); %/sqrt(n_ind);

    % Plot each fly as an individual data point
    for id = 1:n_ind
        jit_num = group_id + (rand(1,1)/5)-0.1;
        mean_ind = max(d3(id, :));
        plot(jit_num, mean_ind, 'o', 'Color', [0.88 0.88 0.88], 'MarkerSize', 10);
        hold on
    end 

    errorbar(group_id, mean_gp, sem_data, 'Color', col, 'LineWidth', lw, 'CapSize', 10);
    plot([group_id-0.1, group_id+0.1], [mean_gp mean_gp], '-', 'Color', col, 'LineWidth', lw);

    xlim([0 3.5])
    xticks([1,2,3])
    xticklabels({''})
    box off
    ax = gca;
    ax.TickDir = 'out';
    title('OFF end')
    ax.LineWidth = 1.2;
    ax.TickLength = [0.02 0.02];

    ylim([0 55])

    % Increase group_id number
    group_id = group_id + 1;

end 

sgtitle("Max")
f = gcf;
f.Position = [1   706   804   341];



