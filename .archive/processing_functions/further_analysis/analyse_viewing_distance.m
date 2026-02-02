% VIEWING DISTANCE


% Load the DATA

strain = "jfrc100_es_shibire_kir";
sex= "F";

data = DATA.(strain).(sex); 
n_exp = length(data); % Number of experiments run for this strain / sex.

dist_data = data(1).R1_condition_1.dist_data;
x_data = data(1).R1_condition_1.x_data;
y_data = data(1).R1_condition_1.y_data;
heading_wrap = data(1).R1_condition_1.heading_wrap;

fly_id = 1;

distt = dist_data(fly_id, :);
x = x_data(fly_id, :);
y = y_data(fly_id, :);
heading = heading_wrap(fly_id, :);

figure; plot(heading)
figure; plot(distt)


%% Work out "viewing distance" from one fly in one frame. 

frame_id = 1;

x_f = x(frame_id);
y_f = y(frame_id);
theta = heading(frame_id); 

% Define arrow length
arrow_length = 10;

% Convert heading angle to radians
theta_rad = deg2rad(theta);

% Compute arrow direction
dx = arrow_length * cos(theta_rad);
dy = arrow_length * sin(theta_rad);

% Plot the position of the fly. - units in mm. 

% Centre of arena = [528, 520]
% radius = 496
PPM = 4.1691; %calib.PPM; 
CoA = [528, 520]/PPM;
x_c = CoA(1);
y_c = CoA(2);
R = 496/PPM;

%%

% Compute quadratic coefficients
A = 1; % Since cos^2 + sin^2 = 1
B = 2 * ((x_f - x_c) * cos(theta_rad) + (y_f - y_c) * sin(theta_rad));
C = (x_f - x_c)^2 + (y_f - y_c)^2 - R^2;

% Solve quadratic equation for t
D = B^2 - 4*A*C; % Discriminant
if D < 0
    error('No intersection found - check inputs');
end

t1 = (-B + sqrt(D)) / (2*A);
t2 = (-B - sqrt(D)) / (2*A);

% Choose the positive t (looking forward)
d_view = max(t1, t2);

% Display the result
fprintf('Viewing distance: %.2f mm\n', d_view);

% Plot the fly, heading, and arena
figure; hold on;
viscircles([x_c, y_c], R, 'Color', [0.8 0.8 0.8]); % Arena
plot(x_f, y_f, 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8, 'LineWidth', 1.2); % Fly position
quiver(x_f, y_f, cos(theta_rad)*d_view, sin(theta_rad)*d_view, 0, 'Color', [1 0.5 0.5], 'LineWidth', 2); % Heading direction

axis equal;
xlim([x_c-R-20, x_c+R+20]);
ylim([y_c-R-20, y_c+R+20]);








%% Visualise the changing viewing distance. 

% Set up video writer
video_filename = 'viewing_distance.avi';
v = VideoWriter(video_filename, 'Motion JPEG AVI'); % Use MJPEG for better quality
v.FrameRate = 90; % 3X sped up. Acquired at 30fps.
open(v);

% Create figure for plotting
fig = figure;
hold on;
axis equal;
xlim([x_c-R-20, x_c+R+20]);
ylim([y_c-R-20, y_c+R+20]);

for frame_id = 1:1800

    if frame_id >300 && frame_id<1200
        col = [1 0 0];
    else 
        col = [1 0.6 0.6];
    end 

    x_f = x(frame_id);
    y_f = y(frame_id);
    theta = heading(frame_id); 
    theta_rad = deg2rad(theta);
    
    % Compute quadratic coefficients
    A = 1; % Since cos^2 + sin^2 = 1
    B = 2 * ((x_f - x_c) * cos(theta_rad) + (y_f - y_c) * sin(theta_rad));
    C = (x_f - x_c)^2 + (y_f - y_c)^2 - R^2;
    
     % Solve quadratic equation for intersection
    D = B^2 - 4*A*C;
    if D < 0
        d_view = NaN; % No valid intersection
    else
        t1 = (-B + sqrt(D)) / (2*A);
        t2 = (-B - sqrt(D)) / (2*A);
        d_view = max(t1, t2); % Forward distance
    end

    clf;
    hold on;
    
    viscircles([x_c, y_c], R, 'Color', [0.8 0.8 0.8]); % Arena
    plot(x_f, y_f, 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8, 'LineWidth', 1.2); % Fly position
    if ~isnan(d_view)
        quiver(x_f, y_f, cos(theta_rad)*d_view, sin(theta_rad)*d_view, 0, 'Color', col, 'LineWidth', 2); % Heading direction
    end 

    axis equal;
    axis off;
    xlim([x_c-R-20, x_c+R+20]);
    ylim([y_c-R-20, y_c+R+20]);

    % Capture the frame and write to video
    frame_data = getframe(fig);
    writeVideo(v, frame_data);

end 

% Close the video file
close(v);

%% Calculate the viewing distance per fly



for frame_id = 1:1800

    x_f = x(frame_id);
    y_f = y(frame_id);
    theta = heading(frame_id); 
    theta_rad = deg2rad(theta);
    
    % Compute quadratic coefficients
    A = 1; % Since cos^2 + sin^2 = 1
    B = 2 * ((x_f - x_c) * cos(theta_rad) + (y_f - y_c) * sin(theta_rad));
    C = (x_f - x_c)^2 + (y_f - y_c)^2 - R^2;
    
     % Solve quadratic equation for intersection
    D = B^2 - 4*A*C;
    if D < 0
        d_view = NaN; % No valid intersection
    else
        t1 = (-B + sqrt(D)) / (2*A);
        t2 = (-B - sqrt(D)) / (2*A);
        d_view = max(t1, t2); % Forward distance
    end

end 




