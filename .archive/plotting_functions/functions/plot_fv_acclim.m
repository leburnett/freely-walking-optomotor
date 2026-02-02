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
        rng = [0 20];
        ylb = "Forward velocity (mm s-1)";
        lw = 1;
    elseif data_type == "curv_data"
        rng = [-50 50];
        ylb = "Turning rate (deg mm-1)";
        lw = 1;
    end

   %% ACCLIM OFF 

   subplot(3,1,1)

    % Mean +/- SEM
    mean_data = nanmean(d1);
    mean_data = mean_data - mean_data(1);
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

    % xlim([0 90]) % 3s 
    % xticks([0 30 60 90])
    % xticklabels({'0', '1', '2', '3'})

    xticks([0 300 600])
    xticklabels({'0', '10', '20'})
    xlabel('Time (s)')
    % ylim(rng)
    ylim([-2 7])
    box off
    ax = gca;
    ax.TickDir = 'out';
    title('OFF start')
    ax.XAxis.Visible = 'off';


    %% ACCLIM PATT

    subplot(3,1,2)

    % Mean +/- SEM
    mean_data = nanmean(d2);
    mean_data = mean_data - mean_data(1);
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
    % ylim(rng)
    ylim([-3 7])
    box off
    ax = gca;
    ax.TickDir = 'out';
    title('Static pattern')
    ylabel(ylb)
    ax.XAxis.Visible = 'off';

    % xlim([0 90]) % 3s 
    % xticks([0 30 60 90])
    % xticklabels({'0', '1', '2', '3'})

    %% ACCLIM OFF 2

    subplot(3,1,3)

    % Mean +/- SEM
    mean_data = nanmean(d3);
    mean_data = mean_data - mean_data(1);
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
    % ylim(rng)
    ylim([-7 5])
    box off
    ax = gca;
    ax.TickDir = 'out';
    title('OFF end')

    % narrow
    % xlim([0 90]) % 3s 
    % xticks([0 30 60 90])
    % xticklabels({'0', '1', '2', '3'})

end 

f = gcf;
f.Position = [636   548   448   496]; %[5 863 1796 184]; %[5  662  1796  385];
% f.Position = [636   548   198   496]; % narrow















%% Plot DATA POINTS - SCATTER and ERRORBAR

value_to_plot = "mean";

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
        rng = [-5 160];
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
        % rng = [0 31];
        rng = [0 250];
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
    if value_to_plot == "var"
        mean_data = nanvar(d1')';
    elseif value_to_plot == "mean"
        mean_data = nanmean(abs(d1), 2);
    end 
    mean_gp = mean(mean_data);
    n_ind = size(d1, 1);
    sem_data = nanstd(mean_data); %/sqrt(n_ind);

    % Plot each fly as an individual data point
    for id = 1:n_ind
        jit_num = group_id + (rand(1,1)/5)-0.1;
        if value_to_plot == "var"
            mean_ind = nanvar(d1(id, :));
        elseif value_to_plot == "mean"
            mean_ind = nanmean(abs(d1(id, :)));
        end 
        plot(jit_num, mean_ind, 'o', 'Color', [0.88 0.88 0.88], 'MarkerSize', 8);
        hold on
    end 

    xvals = ones(1, n_ind)*group_id;
    % boxplot(mean_data, 'positions', group_id, "Colors", 'k', "BoxFaceColor", col)
    b = boxchart(xvals', mean_data, 'BoxFaceColor', col, 'MarkerColor', 'k'); 

    % errorbar(group_id, mean_gp, sem_data, 'Color', col, 'LineWidth', lw, 'CapSize', 10);
    % plot([group_id-0.1, group_id+0.1], [mean_gp mean_gp], '-', 'Color', col, 'LineWidth', lw);

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
    % ylabel('Variance in forward velocity (mm s-1)')
    ax.FontSize = 15;
    ylim(rng)
    
    %% ACCLIM PATT

    subplot(1,3,2)

    % Mean +/- SEM
    if value_to_plot == "var"
        mean_data = nanvar(d2')';
    elseif value_to_plot == "mean"
        mean_data = nanmean(abs(d2), 2);
    end 
    mean_gp = mean(mean_data);
    n_ind = size(d2, 1);
    sem_data = nanstd(mean_data); %/sqrt(n_ind);

    % Plot each fly as an individual data point
    for id = 1:n_ind
        jit_num = group_id + (rand(1,1)/5)-0.1;
        if value_to_plot == "var"
            mean_ind = nanvar(d2(id, :));
        elseif value_to_plot == "mean"
            mean_ind = nanmean(abs(d2(id, :)));
        end
        plot(jit_num, mean_ind, 'o', 'Color', [0.88 0.88 0.88], 'MarkerSize', 8);
        hold on
    end 

    xvals = ones(1, n_ind)*group_id;
    % boxplot(mean_data, 'positions', group_id, "Colors", 'k')
    b = boxchart(xvals', mean_data, 'BoxFaceColor', col, 'MarkerColor', 'k'); 
    % errorbar(group_id, mean_gp, sem_data, 'Color', col, 'LineWidth', lw, 'CapSize', 10);
    % plot([group_id-0.1, group_id+0.1], [mean_gp mean_gp], '-', 'Color', col, 'LineWidth', lw);

    xlim([0 3.5])
    xticks([1,2,3])
    xticklabels({''})
    box off
    ax = gca;
    ax.TickDir = 'out';
    ax.LineWidth = 1.2;
    ax.TickLength = [0.02 0.02];
    title('Static pattern')
    ax.FontSize = 15;
    ylim(rng)

    %% ACCLIM OFF 2

    subplot(1,3,3)

    % Mean +/- SEM
    if value_to_plot == "var"
        mean_data = nanvar(d3')';
    elseif value_to_plot == "mean"
        mean_data = nanmean(abs(d3), 2);
    end 
    mean_gp = mean(mean_data);
    n_ind = size(d3, 1);
    sem_data = nanstd(mean_data); %/sqrt(n_ind);

    % Plot each fly as an individual data point
    for id = 1:n_ind
        jit_num = group_id + (rand(1,1)/5)-0.1;
        if value_to_plot == "var"
            mean_ind = nanvar(d3(id, :));
        elseif value_to_plot == "mean"
            mean_ind = nanmean(abs(d3(id, :)));
        end
        plot(jit_num, mean_ind, 'o', 'Color', [0.88 0.88 0.88], 'MarkerSize', 8);
        hold on
    end 

    xvals = ones(1, n_ind)*group_id;
    % boxplot(mean_data,  'positions', group_id, "Colors", 'k')
    b = boxchart(xvals', mean_data, 'BoxFaceColor', col, 'MarkerColor', 'k'); 
    % errorbar(group_id, mean_gp, sem_data, 'Color', col, 'LineWidth', lw, 'CapSize', 10);
    % plot([group_id-0.1, group_id+0.1], [mean_gp mean_gp], '-', 'Color', col, 'LineWidth', lw);

    xlim([0 3.5])
    xticks([1,2,3])
    xticklabels({''})
    box off
    ax = gca;
    ax.TickDir = 'out';
    title('OFF end')
    ax.LineWidth = 1.2;
    ax.TickLength = [0.02 0.02];
    ax.FontSize = 15;
    ylim(rng)

    % Increase group_id number
    group_id = group_id + 1;

end 

% sgtitle("Max")
f = gcf;
f.Position = [1   706   804   341];



%% ANOVA to compare groups

n_gps = numel(gps2plot);

mean_off1 = nan(200, n_gps);
mean_patt = nan(200, n_gps);
mean_off2 = nan(200, n_gps);

for grp = 1:n_gps

    gp = gps2plot(grp);

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

        d1 = vertcat(d1, data1); % acclim OFF 1
        d2 = vertcat(d2, data2); % Acclim patt
        d3 = vertcat(d3, data3); % acclim OFF 2

    end 

    d1 = abs(d1);
    d2 = abs(d2);
    d3 = abs(d3);

    mean_off1(1:size(d1, 1), grp) = nanmean(d1,2);   
    mean_patt(1:size(d2, 1), grp) = nanmean(d2,2); 
    mean_off2(1:size(d3, 1), grp) = nanmean(d3,2); 
end 

%% Tests to do before ANOVA
data = mean_off2;

% Shapiro-Wilk test for normality
for i = 1:3
    disp(swtest(data(:, i)))
end 

vartestn(data) % Levene's test for homogeneity of variance

% ANOVA. 
aov = anova(data)
groupmeans(aov)
multcompare(aov)

% If data is non-parametric:
[p, tbl, stats] = kruskalwallis(data)
multcompare(stats)