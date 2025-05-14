
% Plot phototaxis trajectories. 

% x_all = DATA.jfrc100_es_shibire_kir.attP2.F(1).R1_condition_7.x_data;
% y_all = DATA.jfrc100_es_shibire_kir.attP2.F(1).R1_condition_7.y_data;
% trial = 'R1_condition_7';
% % flyID = 1;
% 
% x_all = DATA.jfrc100_es_shibire_kir.attP2.F(1).(trial).x_data;
% y_all = DATA.jfrc100_es_shibire_kir.attP2.F(1).(trial).y_data;
% 
% col = [0.5 0.5 0.5];
% 
% figure
% 
% for flyID = 1:15
% 
%     x = x_all(flyID, :);
%     y = y_all(flyID, :);
% 
%     nframes = numel(x);
% 
%     if contains(trial, 'condition')
% 
%         f_flicker = DATA.jfrc100_es_shibire_kir.attP2.F(1).(trial).start_flicker_f;
% 
%         %% Plot - during condition and flicker:
% 
% 
%         for idx = 1:3
% 
%             subplot(1,3,idx)
% 
%             switch idx
%                 case 1
%                     rng = 1:f_flicker/2;
%                     % rng = 1:f_flicker/2-180;
%                 case 2
%                     rng = f_flicker/2:f_flicker;
%                     % rng = f_flicker/2-180:f_flicker;
%                 case 3 
%                     rng = f_flicker+1:nframes-1;
%                     % rng = f_flicker:nframes-1;
%             end 
% 
%             for i = rng
%                 x1 = x(i);
%                 x2 = x(i+1);
%                 y1 = y(i);
%                 y2 = y(i+1);
%                 plot([x1, x2], [y1 y2], 'Color', col, 'LineWidth', 1)
%                 hold on 
%             end
% 
%             % Start position 
%             plot(x(rng(1)), y(rng(1)), 'Marker', 'o', 'MarkerSize', 5, 'MarkerFaceColor', [1,1,1], 'MarkerEdgeColor', 'k', 'LineWidth', 0.1)
%             % End position
%             plot(x(rng(end)), y(rng(end)), 'k.', 'MarkerSize', 10)
% 
% 
%             viscircles([125, 125], 120, 'Color', [0.7 0.7 0.7])
%             if idx == 1
%                 plot(160, 240, 'r.', 'MarkerSize', 20)
%                 plot(75, 15, 'r.', 'MarkerSize', 20)
%             elseif idx == 2
%                 plot(245, 108, 'b.', 'MarkerSize', 20)
%                 plot(6, 138, 'b.', 'MarkerSize', 20)
%             end 
%             % Centre
%             plot(120, 120, 'm+', 'MarkerSize', 10)
% 
%             xlim([0 250])
%             ylim([0 250])
%             axis off
%             axis square
% 
%             switch idx
%                 case 1
%                     title('Pos1')
%                 case 2
%                     title('Pos2')
%                 case 3 
%                     title('Interval')
%             end 
%         end 
% 
%     else
%         %% Plot - acclim
% 
%         figure
% 
%         for i = 1:nframes-1
%             x1 = x(i);
%             x2 = x(i+1);
%             y1 = y(i);
%             y2 = y(i+1);
%             plot([x1, x2], [y1 y2], 'Color', col, 'LineWidth', 1)
%             hold on 
%         end
% 
%         % Start position 
%         plot(x(1), y(1), 'Marker', 'o', 'MarkerSize', 5, 'MarkerFaceColor', [1,1,1], 'MarkerEdgeColor', 'k', 'LineWidth', 0.1)
%         % End position
%         plot(x(end), y(end), 'k.', 'MarkerSize', 10)
% 
%         viscircles([125, 125], 120, 'Color', [0.7 0.7 0.7])
% 
%         plot(200, 220, 'r.', 'MarkerSize', 20)
%         plot(40, 40, 'r.', 'MarkerSize', 20)
% 
%         plot(222, 55, 'b.', 'MarkerSize', 20)
%         plot(35, 205, 'b.', 'MarkerSize', 20)
% 
%         % Centre
%         plot(120, 120, 'm+', 'MarkerSize', 10)
% 
% 
%         xlim([0 250])
%         ylim([0 250])
%         axis off
%         axis square
% 
%         title(strrep(trial, '_', '-'))
% 
%         f = gcf;
%         f.Position = [898   729   263   245];
% 
%     end 
% 
% end 
% 
%  f = gcf;
%  f.Position = [176   729   721   242];







%%
% Phototaxis analysis;

% Bin data based on when the stimuli were shown. 

% Find out if the bars were presented and their locations.

% For each fly - find it's heading and then find the heading relative to
% both bars.

% Plot a distribution of angles with zero being directly headed towards
% a single bar.

% Combine the two distributions together. 

% Compare overall distribution to a random distribution. Get statistic. 



% For the first time just find for one fly over one condition / position of
% the bar. 

% 

%% 1 - Find the x, y and heading data 

trial = 'R1_condition_7';

exp_id = 4;

% flyID = 14;
for flyID = 1:15
    
    x_all = DATA.jfrc100_es_shibire_kir.attP2.F(exp_id).(trial).x_data;
    y_all = DATA.jfrc100_es_shibire_kir.attP2.F(exp_id).(trial).y_data;
    heading_all = DATA.jfrc100_es_shibire_kir.attP2.F(exp_id).(trial).heading_data;
    fv_all = DATA.jfrc100_es_shibire_kir.attP2.F(exp_id).(trial).fv_data;
    
    x = x_all(flyID, :);
    y = y_all(flyID, :);
    theta = heading_all(flyID, :);
    fv = fv_all(flyID, :);
    
    % Set frames where the forward velocity < 2mms-1 to NaN
    x(fv<2) = NaN;
    y(fv<2) = NaN;
    theta(fv<2) = NaN;
    
    %% 2 - Extract the data only during the time when the specific pattern was shown. 
    
    % Total number of frames within the condition:
    nframes = numel(x);
    
    % At what frame was the interval stimulus started?
    f_flicker = DATA.jfrc100_es_shibire_kir.attP2.F(1).(trial).start_flicker_f;
            
    % Get the duration and number of trials during the condition. 
    trial_len = DATA.jfrc100_es_shibire_kir.attP2.F(1).(trial).trial_len;
    n_trials = DATA.jfrc100_es_shibire_kir.attP2.F(1).(trial).n_trials;
    % Eventually add interval duration here and add this - for now hard code
    % it:
    interval_dur = 25;
    %Also hard code the camera acquisition rate:
    fps = 30;
    
    total_cond_time = (trial_len*n_trials)+interval_dur;
    disp(strcat("Total condition duration incl. interval: ", string(total_cond_time), "s"))
    est_cond_frames = total_cond_time*fps;
    diff_frames = est_cond_frames - nframes;
    
    % Display difference in number of frames. 
    % Negative number means that more frames acquired than expected.
    % Positive number means that less frames were acquired than expected.
    disp(strcat("Difference between estimated condition frames and acquired frames: ", string(diff_frames)))
    
    %% Cut the data into the two trials and the interval:
    
    nframes_t = trial_len*fps;
    
    % - - - Trial 1
    x_t1 = x(1:nframes_t);
    y_t1 = y(1:nframes_t);
    theta_t1 = theta(1:nframes_t);
    % Initialize empty arrays
    theta_bar_t1 = zeros([nframes_t, 4]);
    
    % - - - Trial 2
    x_t2 = x(nframes_t+1:nframes_t*2);
    y_t2 = y(nframes_t+1:nframes_t*2);
    theta_t2 = theta(nframes_t+1:nframes_t*2);
    % Initialize empty arrays
    theta_bar_t2 = zeros([nframes_t, 4]);
    
    % - - - Interval
    x_int = x(f_flicker:end);
    y_int = y(f_flicker:end);
    theta_int = theta(f_flicker:end);
    n_frames_int = numel(x_int);
    % Initialize empty arrays
    theta_bar_int = zeros([n_frames_int, 4]);
    
    %% Find the positions of the bars during each condition.
    % Condition 7 = ON bars
    % Condition 8 = OFF bars
    
    % Position of the two bars in trial 1
    %     bar_pos_1a = [160, 240];
    %     bar_pos_2a = [75, 15];
    % % Position of the two bars in trial 2
    %     bar_pos_1b = [245, 108];
    %     bar_pos_2b = [6, 138];
    
    %%
    
    for tri = 1:3 % Run through the two trials and the interval.
    
        % For all trials find the angle towards all of the bars. 
        % The distributions between the two bars that are not shown should be a
        % good control too. 
            bar_pos_1 = [160, 240]; % trial 1 position
            bar_pos_2 = [75, 15]; % trial 1 position
            bar_pos_3 = [245, 108]; % trial 2 position
            bar_pos_4 = [6, 138]; % trial 2 position
    
            if tri < 3
                nframes_tr = nframes_t;
            else 
                nframes_tr = n_frames_int;
            end 
    
            for bar_n = 1:4
                
                switch bar_n
                    case 1
                        bar_pos = [160, 240]; % trial 1 position
                    case 2
                        bar_pos = [75, 15]; % trial 1 position
                    case 3 
                        bar_pos = [245, 108]; % trial 2 position
                    case 4 
                        bar_pos = [6, 138]; % trial 2 position
                end 
    
                for i = 1:nframes_tr
                
                    % Fly's position
                    if tri == 1
                        x_fly = x_t1(i);
                        y_fly = y_t1(i);
                        theta_fly = theta_t1(i);
                    elseif tri == 2
                        x_fly = x_t2(i);
                        y_fly = y_t2(i);
                        theta_fly = theta_t2(i);
                    elseif tri == 3
                        x_fly = x_int(i);
                        y_fly = y_int(i);
                        theta_fly = theta_int(i);
                    end 
                
                    x_target = bar_pos(1);
                    y_target = bar_pos(2);
            
                    % Compute absolute angle to target
                    theta_target = atan2(-(y_target - y_fly), (x_target - x_fly)) * (180 / pi);
                    
                    % Compute relative heading (target direction w.r.t. fly's heading)
                    theta_relative = mod(theta_target - theta_fly + 180, 360) - 180;
            
                    % Fill in new values into correct arrays:
                    if tri == 1
                        theta_bar_t1(i, bar_n) = theta_relative;
                    elseif tri == 2
                        theta_bar_t2(i, bar_n) = theta_relative;
                    elseif tri == 3
                        theta_bar_int(i, bar_n) = theta_relative;
                    end 
                end 
            end 
    end 
    
    
    %% Generate a plot of the distributions:
    
    figure;
    
    for tri = 1:3
        for bar_n = 1:4
            if tri == 1
                data = theta_bar_t1;
            elseif tri == 2
                data = theta_bar_t2;
            elseif tri == 3
                data = theta_bar_int;
            end 
            subplot_n = (tri - 1) * 4 + bar_n;
            subplot(3,4, subplot_n)
            histogram(data(:, bar_n), 'BinEdges', -180:15:180, 'Normalization', 'percentage', "FaceColor", [0.8 0.8 0.8])
           
            if subplot_n < 5
                title(strcat("Bar position: ", string(bar_n)))
            end 
            
            if subplot_n == 1
                ylabel("Trial 1")
            elseif subplot_n == 5
                ylabel("Trial 2")
            elseif subplot_n == 9
                ylabel("Interval")
            end 
    
            % ylim([0 12])
        end 
    end 
    f = gcf;
    f.Position = [273   656   995   326];

end





