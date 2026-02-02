% Make function with boxchart and scatter points on top - quantified value
% per condition for one group. Use to compare across stimulus parameters
% for a single experimental group. 

% This generates a plot comparing behavioural metrics across conditions for
% a single experimental group.

function f = scatter_boxchart_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot)

    if data_type == "dist_data_delta"
        data_type = "dist_data";
        delta = 1;
        d_fv = 0 ;
    elseif data_type == "dist_data_fv"
        data_type = "dist_data";
        delta = 1;
        d_fv = 1;
    else 
        delta = 0;
        d_fv = 0;
    end 

    % Generate new figure
    figure;

    % Get the data for the specific experimental group:
    strain = gp_data{grp2plot, 1};
    sex = gp_data{grp2plot, 3}; 
    col = gp_data{grp2plot, 4};
    data = DATA.(strain).(sex); 
    n_exp = length(data); % Number of experiments run for this strain / sex.

    % Find out which conditions exist for this group:
    % [min_val, max_val] = range_of_conditions(data);

    n_cond = numel(cond2plot);

    x_grp = [];
    y_grp = [];

    % Fixed colours for the different grating SF and TFs.
    % col_grp = [
    %     % 0.2, 0.2, 0.2, 0.7;...
    %     % 0.2, 0.2, 0.2, 0.3;...
    %     0.31, 0.12, 0.37, 0.7;... %curtains
    %     0.31, 0.12, 0.37, 0.3;...
    %     0.6, 0.1, 0.6, 0.7;...
    %     0.6, 0.1, 0.6, 0.3;...
    %     % 0.7, 0.7, 0.7, 0.7;...
    %     % 0.7, 0.7, 0.7, 0.3;...
    %     % 0.9, 0.5, 0, 0.7; ...
    %     % 0.9, 0.5, 0, 0.3; ...
    %     % 0.9, 0.75, 0, 0.7;...
    %     % 0.9, 0.75, 0, 0.3;...
    %     % 0.8, 0, 0, 0.7;...
    %     % 0.8, 0, 0, 0.3;...
    %     ];
      col_grp = [
        0.8, 0, 0, 0.7;... % 60 deg
        0.8, 0, 0, 0.3;...
        0.9, 0.5, 0, 0.7; ... % narrow bars
        0.9, 0.5, 0, 0.3; ...
        0.31, 0.12, 0.37, 0.3;... % curtains
        0.6, 0.1, 0.6, 0.3;...
        0.7, 0.7, 0.7, 0.7;... %reverse phi
        0.7, 0.7, 0.7, 0.3;...
        0.2, 0.2, 0.2, 0.7;... % flicker
        0.2, 0.2, 0.2, 0.3;...
        % 0.9, 0.75, 0, 0.7;...
        % 0.9, 0.75, 0, 0.3;...
        ];

    cond_idx = 1;

    %% Combine the data for one one group:
for idx2 = cond2plot

    rep1_str = strcat('R1_condition_', string(idx2));   
    rep2_str = strcat('R2_condition_', string(idx2));  
    
    if isfield(data, rep1_str)
    
        % contains one row per fly and rep - combines data across all flies and all reps.
        cond_data = []; 
        if d_fv 
            cond_data_fv = [];
        end 
        nf_comb = size(cond_data, 2);

        fl_start_f = [];
    
        for idx = 1:n_exp
            rep1_data = data(idx).(rep1_str);
    
            if ~isempty(rep1_data) % check that the row is not empty.

                if d_fv 
                    rep1_data_fv = rep1_data.fv_data;
                    rep2_data_fv = data(idx).(rep2_str).fv_data;
                end 

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

                % Initialise empty array:
                rep_data = zeros(size(rep1_data));

                if d_fv 
                    rep1_data_fv = rep1_data_fv(:, 1:nf);
                    rep2_data_fv = rep2_data_fv(:, 1:nf);
                    rep_data_fv = zeros(size(rep1_data_fv));
                end 

                nf_comb = size(cond_data, 2);
    
                if idx == 1 || nf_comb == 0 % 

                    for rr = 1:size(rep1_data, 1)
                        rep_data(rr, :) = mean(vertcat(rep1_data(rr, :), rep2_data(rr, :)));
                    end 
                    cond_data = vertcat(cond_data, rep_data);
                    if d_fv
                        for rr = 1:size(rep1_data_fv, 1)
                            rep_data_fv(rr, :) = mean(vertcat(rep1_data_fv(rr, :), rep2_data_fv(rr, :)));
                        end 
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
                    
                    % For 'cond_data' have one row per fly - mean of 2
                    % reps - not one row per rep. 
                    rep_data = mean(vertcat(rep1_data, rep2_data));
                    cond_data = vertcat(cond_data, rep_data);

                    if d_fv
                        rep_data_fv = mean(vertcat(rep1_data_fv, rep2_data_fv));
                        cond_data_fv = vertcat(cond_data_fv, rep_data_fv);
                    end 
                end

                fl_start = data(idx).(rep1_str).start_flicker_f;
                fl_start_f = [fl_start_f, fl_start];
  
            end 
        end 
       
        %% Based on the data type - find a specific metric per fly and per rep:

        n_datapoints = size(cond_data, 1); % n_flies * n_reps (2)

        % Subtract initial value when stimulus starts if required. 
        if delta == 1
            for j = 1:n_datapoints
                cond_data(j, :) = cond_data(j, :) - cond_data(j, 300); % largest difference from the position when the stimulus started.
            end 
        end 

        if d_fv == 1
            for j = 1:n_datapoints
                cond_data(j, :) = cond_data(j, :)./cond_data_fv(j, :);
            end 
        end 
    
        % x_array = repmat({strain}, n_datapoints, 1);
        x_data = ones(n_datapoints, 1)*cond_idx; % Defines position of boxplot on x-axis.
        col_data = repmat(col, n_datapoints, 1);
        
        % DATA contains 10s of the interval before per condition:
        % 1:300 = interval before
        % 301:900 = 30s of stimulus if 2 x 15s trials happen *********
        % 901:end (1800) = 30s of interval.

        if data_type == "dist_data"
            % Look at the position during the last 5s of the stimulus:
            if d_fv == 1 % delta and forward vel
                y_data = prctile(cond_data(:, 750:900)', 2)'; % Get the 2% value per rep. (min)
                rng = [-25 10];
                ylb = 'Distance from centre / fv-data - delta (s)';
            elseif delta == 1 % delta dist
                y_data = prctile(cond_data(:, 750:900)', 2)'; % Get the 2% value per rep. (min)
                % y_data = cond_data(:, 900)- cond_data(:, 300);
                rng = [-80 40];
                ylb = 'Distance from centre - delta (mm)';
            else % absolute dist
                y_data = prctile(cond_data(:, 750:900)', 2)'; % Get the 2% value per rep. (min)
                rng = [-5 120];
                ylb = 'Distance from centre (mm)';
            end 

        elseif data_type == "av_data"
            y_data = median(abs(cond_data(:, 301:900)), 2);
            % y_data = prctile(abs(cond_data(:, 301:900))', 98)';
            % if idx2 <3
            %     rng = [0 400];
            % elseif idx2 >=3 && idx2 < 5
            %     rng = [0 250];
            % else
            %     rng = [0 120];
            % end 
            rng = [0 210];
            ylb = "Anglar velocity (deg s-1)";
        elseif data_type == "fv_data"
            y_data = mean(abs(cond_data(:, 301:900)), 2);
            rng = [-2 25];
            ylb = "Forward velocity (mm s-1)";
        elseif data_type == "curv_data"
            % For turning rate - find the mean across the condition. abs.
            y_data = mean(abs(cond_data(:, 301:900)), 2);
            rng = [0 200];
            ylb = "Turning rate (deg mm-1)";
        end

        % Need to combine the x and y data across groups:
        x_grp = vertcat(x_grp, x_data);
        y_grp = vertcat(y_grp, y_data);

    end 

        % Increase condition index by 1 - plot at next x value.
        cond_idx = cond_idx+1;

end 
    
    % Plot individual data points - fly and rep:
    swarmchart(x_grp, y_grp, 15, [0.7 0.7 0.7], 'MarkerEdgeAlpha', 0.8)
    hold on
    % Plot box plot
    boxplot(y_grp, x_grp, 'Colors', col_grp(:, 1:3), 'symbol', '');
    ax = gca;
    h = findobj(ax,'Tag','Box');
    for j=1:length(h)
        patch(get(h(j),'XData'), get(h(j),'YData'), col_grp(numel(h)+1-j,1:3),'FaceAlpha',col_grp(numel(h)+1-j,4));
    end
    h2 = findobj(ax,'Tag','Median');
    set(h2,'LineWidth', 2.1);
    ylim(rng)

    if data_type == "dist_data"
        if delta == 1
            plot([0 n_cond+1], [0 0], 'Color', 'k', 'LineWidth', 0.1)
        else
            plot([0 n_cond+1], [60 60], 'k', 'LineWidth', 0.1)
        end 
    end 

    title(strrep(strain, '_', '-'), 'FontSize', 12)
    box off
    ax.TickDir = 'out';
    xticks(1:1:n_cond)
    xticklabels({''})
    ax.TickLength = [0.02 0.02];
    ax.LineWidth = 1.2;
    ax.FontSize = 12;
    xlim([0.5 n_cond+0.5])
    ylabel(ylb)

    f = gcf;
    f.Position = [514   703   273   267]; %[ 514   703   455   267]; %

end 