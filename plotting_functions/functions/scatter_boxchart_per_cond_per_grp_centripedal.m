% Make function with boxchart and scatter points on top - quantified value
% per condition per group. 

function f = scatter_boxchart_per_cond_per_grp_centripedal(DATA, gp_data, cond_titles, gps2plot)

    % Generate new figure
    figure;
    n_cond = 2; %length(cond_titles);
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
for idx2 = [1, 2] %min_val:1:max_val 

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
                cond_data_hw = [];
     
                nf_comb = size(cond_data, 2);
        
                fl_start_f = [];
            
                for idx = 1:n_exp
                    rep1_data = data(idx).(rep1_str);
            
                    if ~isempty(rep1_data) % check that the row is not empty.
        
                        % Wrapped heading data:
                        rep1_data_hw = rep1_data.heading_wrap;
                        rep2_data_hw = data(idx).(rep2_str).heading_wrap;
    
                        % Distance to centre data. 
                        rep1_data = rep1_data.dist_data;
                        rep2_data = data(idx).(rep2_str).dist_data;
            
                        % % % % Combine the data together across experiments 
                        % - trim if needed: 
    
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
                        rep1_data_hw = rep1_data_hw(:, 1:nf);
                        rep2_data_hw = rep2_data_hw(:, 1:nf);
    
                        % Initialise empty arrays:
                        rep_data = zeros(size(rep1_data));
                        rep_data_hw = zeros(size(rep1_data_hw));
    
                        nf_comb = size(cond_data, 2);
            
                        if idx == 1 || nf_comb == 0 % 
    
                            for rr = 1:size(rep1_data, 1)
                                rep_data(rr, :) = mean(vertcat(rep1_data(rr, :), rep2_data(rr, :)));
                            end 
                            cond_data = vertcat(cond_data, rep_data);
    
                            for rr = 1:size(rep1_data_hw, 1)
                                rep_data_hw(rr, :) = mean(vertcat(rep1_data_hw(rr, :), rep2_data_hw(rr, :)));
                            end 
                            cond_data_hw = vertcat(cond_data_hw, rep_data_hw);
    
                        else
    
                            if nf>nf_comb % trim incoming data
                                rep1_data = rep1_data(:, 1:nf_comb);
                                rep2_data = rep2_data(:, 1:nf_comb);
                                rep1_data_hw = rep1_data_hw(:, 1:nf_comb);
                                rep2_data_hw = rep2_data_hw(:, 1:nf_comb);
                            elseif nf_comb>nf % Add NaNs to end
                                diff_f = nf_comb-nf+1;
                                n_flies = size(rep1_data, 1);
                                rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                                rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                                rep1_data_hw(:, nf:nf_comb) = NaN(n_flies, diff_f);
                                rep2_data_hw(:, nf:nf_comb) = NaN(n_flies, diff_f);
                            end 
                            
                            % For 'cond_data' have one row per fly - mean of 2
                            % reps - not one row per rep. 
                            rep_data = mean(vertcat(rep1_data, rep2_data));
                            cond_data = vertcat(cond_data, rep_data);
                            rep_data_hw = mean(vertcat(rep1_data_hw, rep2_data_hw));
                            cond_data_hw = vertcat(cond_data_hw, rep_data_hw);
    
                        end
        
                        fl_start = data(idx).(rep1_str).start_flicker_f;
                        fl_start_f = [fl_start_f, fl_start];
          
                    end 
                end 
           
                %% Based on the data type - find a specific metric per fly and per rep:
        
                n_datapoints = size(cond_data, 1); % n_flies * n_reps (2)
    
                % % % % % Calculate the metric - distance moved towards centre
                % vs turning. (mm moved per 360 deg)
    
                D2T_data = zeros(size(cond_data, 1), 1);
                rng = 301:1200;
    
                for j = 1:n_datapoints
                    delta_theta = diff(cond_data_hw(j, rng));
                    degrees_turned = sum(abs(delta_theta));
                    dist_data2 = cond_data(j, rng);
                    dist_moved_towards_centre = dist_data2(end) - dist_data2(1);
                    dist_moved_towards_centre = dist_moved_towards_centre*-1;
                    centre_v_turn = (dist_moved_towards_centre/degrees_turned)*360;
                    D2T_data(j, 1) = centre_v_turn;
                end 
        
                % x_array = repmat({strain}, n_datapoints, 1);
                x_data = ones(n_datapoints, 1)*grp; % Defines position of boxplot on x-axis.
                col_data = repmat(col, n_datapoints, 1);
                
                % DATA contains 10s of the interval before per condition:
                % 1:300 = interval before
                % 301:900 = 30s of stimulus if 2 x 15s trials happen *********
                % 901:end (1800) = 30s of interval.
        
                y_data = D2T_data; 
                rng = [-6 8];
                ylb = 'Distance towards centre vs turning (mm 360deg^-^1)';
    
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