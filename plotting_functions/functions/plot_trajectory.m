% PLOT_TRAJECTORY - Plot fly trajectories colored by stimulus direction
%
% SCRIPT CONTENTS:
%   - Section 1: Basic trajectory plot with color-coded stimulus periods
%   - Section 2: Find stimulus direction transition frames
%   - Section 3: Generate horsetail plots centered on transition frames
%
% DESCRIPTION:
%   This script visualizes fly trajectories with color coding based on
%   stimulus direction. Blue indicates clockwise (dir=1) stimulus, magenta
%   indicates counter-clockwise (dir=-1) stimulus, and black indicates
%   intervals/no stimulus.
%
%   The horsetail plot analysis centers all trajectories on the fly's
%   position at stimulus direction transitions, then rotates so the arena
%   center is always along the positive x-axis. This allows visualization
%   of whether flies turn toward or away from center during transitions.
%
% INPUTS (from workspace):
%   trx  - FlyTracker trajectory struct with fields x, y
%   Log  - Stimulus timing struct with fields dir, start_f, stop_f
%   feat - FlyTracker feature struct (for distance from wall)
%
% PARAMETERS:
%   t_len = 3 seconds before/after transition
%   fps = 30 frames per second
%   arena_centre = [512, 512] pixels
%
% OUTPUTS:
%   - Trajectory figures with color-coded segments
%   - Horsetail plots showing movement relative to arena center at transitions
%
% See also: generate_trajectory_plots, plot_traj_xcond

% Plot trajectories.
% What is important to plot?
% Quantify whether they turn in out of circle.
% Horsetail plot. centre on position at transition. Take away those xy
% values from subsequent ones. Plots them with different time intervals. 


x = trx.x;
y = trx.y;

smooth_kernel = [1 2 1]/4;
x(2:end-1) = conv(x,smooth_kernel,'valid');
y(2:end-1) = conv(y,smooth_kernel,'valid');

% x = downsample(x, 5);
% y = downsample(y, 5);

nframes = numel(x);

rows_blue = find(Log.dir == 1);
frames_blue = [];
for j = 1:numel(rows_blue)
    row = rows_blue(j);
    vals = Log.start_f(row):1:Log.stop_f(row);
    frames_blue = [frames_blue, vals];
end 
% fblue = downsample(frames_blue/5);


rows_pink = find(Log.dir == -1);
frames_pink = [];
for j = 1:numel(rows_pink)
    row = rows_pink(j);
    vals = Log.start_f(row):1:Log.stop_f(row);
    frames_pink = [frames_pink, vals];
end 
% fpink = ceil(frames_pink/5);


% Plot 
figure
for i= 1:nframes-1
    x1 = x(i);
    x2 = x(i+1);
    y1 = y(i);
    y2 = y(i+1);
    if ismember(i, frames_blue)
        col = 'b';
    elseif ismember(i, frames_pink)
        col = 'm';
    else 
        col = 'k';
    end 
    plot([x1, x2], [y1 y2], col, 'LineWidth', 1)
    hold on 
end 
%Start position
plot(x(1), y(1), 'r.', 'MarkerSize', 20)
% End position
plot(x(end), y(end), 'b.', 'MarkerSize', 20)
viscircles([512, 512], 500, 'Color', [0.7 0.7 0.7])
xlim([0 1024])
ylim([0 1024])
axis off
axis square




%% Find frames when transitions happen

% % %  1 to -1 transitions

% Find the last frame of the '1' dir stimulus. 
rows1 = find(Log.dir == 1);

frames_transition1 = [];
for j = 1:numel(rows1)
    row = rows1(j);

    if Log.dir(row+1) == -1
        f_stop1 = Log.stop_f(row);
        f_start_1 = Log.start_f(row+1);
        if f_stop1 ~= f_start_1
            val = ceil(mean([f_stop1, f_start_1]));
        else 
            val = f_stop1;
        end 
        frames_transition1 = [frames_transition1, val];
    end 
end 

% % %  -1 to 1 transitions

rows_1 = find(Log.dir == -1);

frames_transition2 = [];
frames_transition3 = [];

for j = 1:numel(rows_1)
    row = rows_1(j);

    if Log.dir(row+1) == 1 % Goes back to '1' dir

        f_stop_1 = Log.stop_f(row);
        f_start1 = Log.start_f(row+1);
        if f_stop_1 ~= f_start1
            val = ceil(mean([f_stop_1, f_start1]));
        else 
            val = f_stop_1;
        end 
        frames_transition2 = [frames_transition2, val];

    elseif Log.dir(row+1) ~= 1 % Goes on to Flicker next.

        f_stop_1 = Log.stop_f(row);
        f_start1 = Log.start_f(row+1);
        if f_stop_1 ~= f_start1
            val = ceil(mean([f_stop_1, f_start1]));
        else 
            val = f_stop_1;
        end 
        frames_transition3 = [frames_transition3, val];

    end 
end 

%% Plot for 1 to -1 transitions. 

smooth_kernel = [1 2 1]/4;
t_len = 3; % Length of time in s to plot the 'tail' of the trajectory
fps = 30;

arena_centre_x = 512; 
arena_centre_y = 512;

figure
for fly_id = 1:length(trx)

    % % New figure for each fly.
    % figure

    x = trx(fly_id).x;
    y = trx(fly_id).y;
    x(2:end-1) = conv(x,smooth_kernel,'valid');
    y(2:end-1) = conv(y,smooth_kernel,'valid');

    dist_data = 120-feat.data(fly_id, :, 9);

    n_trans = numel(frames_transition2);
    % Extract only the frames around the transition.
    for trns = 1:n_trans

        % Frame when transition happens
        f_trans = frames_transition2(trns); 
        % x and y position of the fly when the transition happens.
        x_trans = x(f_trans);
        y_trans = y(f_trans);

        % start and stop frames based on transition frame. 
        f_start = f_trans - t_len * fps;
        f_end = f_trans + t_len * fps;
        
        % subset of x and y positions to plot, only for frames around
        % transition
        x_fly = x(f_start:f_end);
        y_fly = y(f_start:f_end); 

        nframes = numel(x_fly);

        % Empty arrays to fill with the updated positions. 
        x_adj = zeros(size(x_fly));
        y_adj = zeros(size(x_fly));
        coa_x_adj = zeros(size(x_fly));
        coa_y_adj = zeros(size(x_fly));

        for i = 1:nframes

            % 1. Shift coordinates so that the transition frame fly is at [0, 0]
            x_shift = x_fly(i) - x_trans;
            y_shift = y_fly(i) - y_trans;

            % 2. Calculate the vector from the current fly position to the arena center
            dx = arena_centre_x - x_fly(i);
            dy = arena_centre_y - y_fly(i);

            % 3. Calculate the angle between this vector and the positive X-axis
            theta = atan2(dy, dx);

            % 4. Compute rotation angle to align arena center along the X-axis
            alpha = -theta;

            % 5. Compute cosine and sine of the rotation angle
            c = cos(alpha);
            s = sin(alpha);
            
            % 6. Rotate the shifted fly position
            x_rot = x_shift * c - y_shift * s;
            y_rot = x_shift * s + y_shift * c;
            
            x_adj(i) = x_rot;
            y_adj(i) = y_rot;
            
            % 7. Rotate the arena center vector (should end up on the X-axis)
            coa_x_rot = dx * c - dy * s;
            coa_y_rot = dx * s + dy * c;
            
            coa_x_adj(i) = coa_x_rot;
            coa_y_adj(i) = coa_y_rot;

        end 

        % Subplot per fly
        subplot(5,3,fly_id)

        % % % % % % for j = 1:nframes-1
        % % % % % % 
        % % % % % %     x1 = x_adj(j);
        % % % % % %     x2 = x_adj(j+1);
        % % % % % %     y1 = y_adj(j);
        % % % % % %     y2 = y_adj(j+1);
        % % % % % % 
        % % % % % %     if j>t_len*fps+1
        % % % % % %         col = 'm';
        % % % % % %     elseif j <= t_len*fps
        % % % % % %         col = 'b';
        % % % % % %     end 
        % % % % % % 
        % % % % % %     plot([x1, x2], [y1 y2], 'Color', col, 'LineWidth', 1)
        % % % % % %     hold on 
        % % % % % % end 
        % % % % % % 
        % % % % % % % Plot the position of the fly at the transition.
        % % % % % % plot(0, 0, 'k.', 'MarkerSize', 10)
        % % % % % % % Plot the centre of the arena at the transition. 
        % % % % % % plot(coa_x_adj(t_len*fps+1), coa_y_adj(t_len*fps+1), 'k+')
        % % % % % % text(coa_x_adj(t_len*fps+1), 40, num2str(coa_x_adj(t_len*fps+1)/4, 2))
        % % % % % % % Plot a line - to the left is away from centre - to right is
        % % % % % % % towards centre. 
        % % % % % % plot([0 0], [-300 300], 'k', 'LineWidth', 0.5)
        % % % % % % 
        % % % % % % xlim([-300 300])
        % % % % % % ylim([-300 300])
        % % % % % % box off
        % % % % % % axis square

        plot(x_adj)
        hold on
        plot([0 (t_len*fps)*2], [0 0], 'k', 'LineWidth', 0.6)
        plot([(t_len*fps) (t_len*fps)], [-(t_len*fps) (t_len*fps)], 'k', 'LineWidth', 0.6)
        
    end 
    % sgtitle('blue before - magenta after')
    sgtitle('change in distance to centre.')

end 


% Colour coordinate tracks based on whether angular velocity is positive or
% negative. 

% Quantify the difference between x positions in subsequent frames after
% this processing. Should give a magnitude of how much the fly moves
% towards the centre of the arena. 

% Separate figure with overlaid x_adj values. 












