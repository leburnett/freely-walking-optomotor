
% Plot trajectories. 

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


figure
for i= 12410:12714
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
% plot(x(1), y(1), 'r.', 'MarkerSize', 20)
% End position
% plot(x(end), y(end), 'b.', 'MarkerSize', 20)
viscircles([512, 512], 500, 'Color', [0.7 0.7 0.7])
xlim([0 1024])
ylim([0 1024])
axis off
axis square
title('Flicker')






