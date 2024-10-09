
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




%%

t_len = 5; % Length of time in s to plot the 'tail' of the trajectory


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






















