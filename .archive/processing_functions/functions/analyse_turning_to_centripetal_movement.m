
% Turning versus centring. 
dist_data = DATA.jfrc100_es_shibire_kir.F(8).R1_condition_1.dist_data;
av_data = DATA.jfrc100_es_shibire_kir.F(8).R1_condition_1.av_data;
heading_wrap = DATA.jfrc100_es_shibire_kir.F(8).R1_condition_1.heading_wrap;
fv_data = DATA.jfrc100_es_shibire_kir.F(8).R1_condition_1.fv_data;

test_flies = [2,4,11,14];

%% 1 - Look at the entire time during the presentation of the grating stimuli. PLOT.

rng_b4 = 1:300; % Frames before the grating starts
rng = 301:1200; % Range of frames to look at. This is for the grating stimulus. 
rng_flicker = 1201:1800; % Frames during the interval. 

for fly_id = test_flies

    % Compute the change in heading (angle change between frames)
    delta_theta = diff(heading_wrap(fly_id, rng));
    % Calculate the total degrees turned by summing absolute heading changes
    degrees_turned = sum(abs(delta_theta));

    dist_data2 = dist_data(fly_id, rng);
    av_data2 = av_data(fly_id, rng);

    % Compute the net distance moved towards the center of the arena
    dist_moved_towards_centre = dist_data2(end) - dist_data2(1);
    dist_moved_towards_centre = dist_moved_towards_centre*-1;
    
    % Compute turn vs. centripetal movement (degrees turned per mm moved towards center)
    turn_v_centripetal = degrees_turned/dist_moved_towards_centre;
    disp(turn_v_centripetal)

    % Compute centripetal movement vs. turn (mm moved towards center per full turn)
    centre_v_turn = (dist_moved_towards_centre/degrees_turned)*360;
    disp(centre_v_turn)

    figure; 
    subplot(3,1,1)
    plot(av_data2)
    xlim([0 900])
    ylabel('Angular velocity (deg s^-^1)')

    subplot(3,1,2)
    plot(dist_data2)
    title(strcat(string(round(dist_moved_towards_centre)), " mm - ", string(round(dist_moved_towards_centre/30, 1)) , " mm s^-^1"))
    xlim([0 900])
    ylabel('Distance from centre (mm)')

    subplot(3,1,3)
    plot(abs(delta_theta))
    ylabel('Change in heading (deg frame^-^1)')
    title(strcat(string(round(degrees_turned)), " degrees - ", string(round(degrees_turned/30)), " deg s^-^1"))
    xlim([0 900])

    sgtitle(strcat("Fly ", string(fly_id), " - ", string(round(turn_v_centripetal)), " deg mm^-^1 - ", string(round(centre_v_turn, 2)), " mm turn^-^1"))

    f = gcf;
    f.Position =[202   401   333   619];
end 


% Would want to calculate the mean of these values across flies. Would differ depending on the starin / stimulus. 
% This could be useful for distinguishing between individuals that follow
% different strategies as well. 


%% Just the calculation. 

% Create empty array to store the values of centripetal movement verus
% turning per fly, for the time before the stimulus, during the stimulus
% and during the interval. 
n_flies = height(dist_data);

cent_v_turn = zeros([n_flies, 3]);
pos_start  = zeros([n_flies, 3]);
fv  = zeros([n_flies, 3]);

rng_b4 = 1:300; % Frames before the grating starts
rng_stim = 301:1200; % Range of frames to look at. This is for the grating stimulus. 
rng_interval = 1201:1800; % Frames during the interval. 

for cond = 1:3

    if cond == 1
        rng = rng_b4; 
    elseif cond == 2
        rng = rng_stim;
    elseif cond == 3
        rng = rng_interval;
    end 

    for fly_id = 1:n_flies
    
        % Compute the change in heading (angle change between frames)
        delta_theta = diff(heading_wrap(fly_id, rng));
        % Calculate the total degrees turned by summing absolute heading changes
        degrees_turned = sum(abs(delta_theta));
    
        dist_data2 = dist_data(fly_id, rng);
    
        % Compute the net distance moved towards the center of the arena
        dist_moved_towards_centre = dist_data2(end) - dist_data2(1);
        dist_moved_towards_centre = dist_moved_towards_centre*-1;
       
        % Compute centripetal movement vs. turn (mm moved towards center per full turn)
        centre_v_turn = (dist_moved_towards_centre/degrees_turned)*360;

        cent_v_turn(fly_id, cond) = centre_v_turn;
        pos_start(fly_id, cond) = dist_data2(1);
        fv(fly_id, cond) = mean(fv_data(fly_id, rng)); %mm s-1

    end 

end 

