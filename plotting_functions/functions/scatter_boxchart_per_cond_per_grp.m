% Make function with boxchart and scatter points on top - quantified value
% per condition per group. 

function f = scatter_boxchart_per_cond_per_grp(DATA, gp_data, cond_titles, data_type, gps2plot)

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
    n_cond = length(cond_titles);
    t = tiledlayout(ceil(n_cond/2), 2); %
    t.TileSpacing = 'compact';

    n_groups = numel(gps2plot);

    %% Using the first group as an example, find out how many conditions there are:
    gp = gps2plot(1);
    strain = gp_data{gp, 1};
    sex = gp_data{gp, 3}; 
    data = DATA.(strain).(sex); 
    % Find out which conditions exist:
    [min_val, max_val] = range_of_conditions(data);

    %% Combine the data for one condition:
    % Run through the different conditions and combine the data across
    % flies, across repetitions and across experiments:
for idx2 = min_val:1:max_val 

    x_grp = [];
    y_grp = [];
    col_grp = [];
    col_grp_scatter = [];

        %% For each experimental group (strain-sex):
        for grp = 1:n_groups

            gp = gps2plot(grp);
        
            % % Eventually have this as the input to the function 
            strain = gp_data{gp, 1};
            sex = gp_data{gp, 3}; 
            col = gp_data{gp, 4};
        
            data = DATA.(strain).(sex); 
            n_exp = length(data); % Number of experiments run for this strain / sex.
    
            rep1_str = strcat('R1_condition_', string(idx2));   
            rep2_str = strcat('R2_condition_', string(idx2));  
    
            if isfield(data, rep1_str)
    
            p = cond_titles{idx2};
    
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
        
                    if idx == 1 || nf_comb == 0 % 

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
                        
                        % For 'cond_data' have one row per fly - mean of 2
                        % reps - not one row per rep. 
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
            x_data = ones(n_datapoints, 1)*grp; % Defines position of boxplot on x-axis.
            col_data = repmat(col, n_datapoints, 1);
            
            % DATA contains 10s of the interval before per condition:
            % 1:300 = interval before
            % 301:900 = 30s of stimulus if 2 x 15s trials happen *********
            % 901:end (1800) = 30s of interval.
    
            if data_type == "dist_data"
                % Look at the position during the last 5s of the stimulus:
                if d_fv == 1 % delta and forward vel
                    y_data = prctile(cond_data(:, 750:900)', 2)'; % Get the 2% value per rep. (min)
                    rng = [-15 5];
                    ylb = 'Distance from centre / fv-data - delta (s)';
                elseif delta == 1 % delta dist
                    y_data = prctile(cond_data(:, 750:900)', 2)'; % Get the 2% value per rep. (min)
                    % y_data = cond_data(:, 900)- cond_data(:, 300);
                    rng = [-100 60];
                    ylb = 'Distance from centre - delta (mm)';
                else % absolute dist
                    y_data = prctile(cond_data(:, 750:900)', 2)'; % Get the 2% value per rep. (min)
                    rng = [-5 120];
                    ylb = 'Distance from centre (mm)';
                end 

            elseif data_type == "av_data"
                y_data = median(abs(cond_data(:, 301:900)), 2);
                % y_data = prctile(abs(cond_data(:, 301:900))', 98)';
                if idx2 <3
                    rng = [0 400];
                elseif idx2 >=3 && idx2 < 5
                    rng = [0 250];
                else
                    rng = [0 100];
                end 
                % rng = [0 220];
                ylb = "Angular velocity (deg s-1)";
            elseif data_type == "fv_data"
                y_data = mean(abs(cond_data(:, 301:900)), 2);
                rng = [-2 25];
                ylb = "Forward velocity (mm s-1)";
            elseif data_type == "curv_data"
                % For turning rate - find the mean across the condition. abs.
                y_data = mean(abs(cond_data(:, 301:900)), 2);
                if idx2 <3
                    rng = [0 220];
                elseif idx2 >=3 && idx2 < 5
                    rng = [0 130];
                else
                    rng = [0 50];
                end 
                ylb = "Turning rate (deg mm-1)";
            end

            % Need to combine the x and y data across groups:
            x_grp = vertcat(x_grp, x_data);
            y_grp = vertcat(y_grp, y_data);
            col_grp = vertcat(col_grp, col);
            col_grp_scatter = vertcat(col_grp_scatter, col_data);

            end 
    
        end 

        %% Plot subplot for condition
        nexttile
        
        % Plot individual data points - fly and rep:
        swarmchart(x_grp, y_grp, 15, [0.7 0.7 0.7], 'MarkerEdgeAlpha', 0.8)
        hold on
        % Plot box plot
        boxplot(y_grp, x_grp, 'Colors', col_grp, 'symbol', '');
        ax = gca;
        h = findobj(ax,'Tag','Box');
        for j=1:length(h)
            patch(get(h(j),'XData'), get(h(j),'YData'), col_grp(numel(h)+1-j,:),'FaceAlpha',.5);
        end
        h2 = findobj(ax,'Tag','Median');
        set(h2,'LineWidth', 2.1);
        ylim(rng)

        if data_type == "dist_data"
            if delta == 1
                plot([0 n_groups+1], [0 0], 'Color', 'k', 'LineWidth', 0.1)
            else
                plot([0 n_groups+1], [60 60], 'k', 'LineWidth', 0.1)
            end 
        end 

        title(p, 'FontSize', 9)
        box off
        ax.TickDir = 'out';
        ax.XAxis.Visible = 'off';
        ax.TickLength = [0.02 0.02];
        xlim([0.5 n_groups+0.5])

end 

    f = gcf;
    f.Position = [171    71   342   976]; %[171    71   292   976]; 
    sgtitle(ylb, 'FontSize', 16)

end 