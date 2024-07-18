%% Investigate clustering behaviour of groups of flies to optomotor behaviour

% trx.x
% trx.y

data_path = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/data/oaky_cokey/difftimes/rev'; 
cd(data_path)
all_data = dir();
dnames = {all_data.name};
all_data = all_data(~ismember(dnames, '.DS_Store'));
all_data = all_data(3:end, :);

n_files = length(all_data);

hull_area_data = cell(n_files, 1);

for idx = 1:n_files

    load(fullfile(all_data(idx).folder,all_data(idx).name), 'trx', 'Log');

    tbl = struct2table(trx);

    num_frames = trx.nframes;
    num_flies = length(trx);

    % Extract x values
    a = cell2mat(tbl.x);
    x_vals = reshape(a, num_frames, num_flies)';
    x_vals(isnan(x_vals))=0;

    % Extract y values
    b = cell2mat(tbl.y);
    y_vals = reshape(b, num_frames, num_flies)';
    y_vals(isnan(y_vals))=0;

    file_hull_data = zeros(num_frames, 1);

    for n = 1:num_frames
        DT = delaunayTriangulation(x_vals(:, n),y_vals(:,n));
        [C, area_hull] = convexHull(DT);
        file_hull_data(n, 1) = area_hull;
    end 

    hull_area_data(idx) = {file_hull_data};

end 

% n_conditions = 33; 
n_conditions = 69;
h = 570000;
min_val = 0;
max_val = 570000;

figure

for ii = 1:n_conditions
    
    % create the plot
    st_fr = Log.start_f(ii);
    stop_fr = Log.stop_f(ii)-1;
    w = stop_fr - st_fr;
    dir_id = Log.dir(ii);

    if dir_id == 0 
        if ii == 1 || ii == 33
            col = [0.5 0.5 0.5 0.3];
        elseif ii == 17 || ii == 32
            col = [0 0 0 0.3];
        else
            col = [1 1 1];
        end 
    elseif dir_id == 1
        col = [0 0 1 Log.contrast(ii)*0.75];
    elseif dir_id == -1
        col = [1 0 1 Log.contrast(ii)*0.75];
    end 
    
    % Add rectangles denoting the different types of experiment.
    rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
    ylim([min_val, max_val])
    hold on 
    box off
    ax = gca;
    ax.XAxis.Visible = 'off';
end 


for i = 1:n_files
    plot(hull_area_data{i}, 'Color', [0 0 0], 'LineWidth', 0.3)
    hold on
end 

% all_data = [];
% for ii = 1:n_files
%     dtt = hull_area_data{ii};
%     dtt = dtt(1:14500);
%     all_data = horzcat(all_data, dtt);
% end 
% 
% av_resp = nanmean(all_data');
% plot(av_resp, 'k', 'LineWidth', 8)
% plot(av_resp, 'w', 'LineWidth', 2)
xlabel('frame')
ylabel('Area of convex hull (mm2?)')
box off
ax =gca;
ax.TickDir = 'out';
ax.LineWidth = 1.1;
ax.FontSize = 12; 
ax.TickLength = [0.007 0.007];
f = gcf;
f.Position = [169  677  1382  269];



% 1 - convex hull around points. 


% plot(DT.Points(:,1),DT.Points(:,2),'.','MarkerSize',10)
% hold on
% plot(DT.Points(C,1),DT.Points(C,2),'r') 

%% Create video of points and the convex hull

% 
% % Create video only for one example experiment: 2024_06_25_17_30_29_csw1118_data.mat
% 
% v = VideoWriter('Hokey_cokey_behaviour.avi'); 
% v.FrameRate = 1000;
% % v.Width = 1024;
% % v.Height = 1024;
% open(v);
% 
% load('/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/ProcessedData/2024_06_25_17_30_29_csw1118_data.mat', 'trx', 'Log');
% 
% tbl = struct2table(trx);
% 
% num_frames = trx.nframes;
% num_flies = length(trx);
% 
% % Extract x values
% a = cell2mat(tbl.x);
% x_vals = reshape(a, num_frames, num_flies)';
% x_vals(isnan(x_vals))=0;
% 
% % Extract y values
% b = cell2mat(tbl.y);
% y_vals = reshape(b, num_frames, num_flies)';
% y_vals(isnan(y_vals))=0;
% 
% file_hull_data = zeros(num_frames, 1);
% 
% for n = 1:num_frames
%     DT = delaunayTriangulation(x_vals(:, n),y_vals(:,n));
%     [C, area_hull] = convexHull(DT);
%     file_hull_data(n, 1) = area_hull;
% 
%     % plot 
%     rectangle('Position', [0 0 1024 1024], 'FaceColor', [0.9 0.9 0.9])
%     hold on
%     plot(DT.Points(:,1),DT.Points(:,2),'k.','MarkerSize', 15)
%     plot(DT.Points(C,1),DT.Points(C,2),'r', 'LineWidth', 1.5) 
%     axis tight
%     box off
%     axis off
%     f = getframe(gcf);
%     writeVideo(v, f);
% end 
% 
% close(v);


%% 2 - Distance to wall. 

dist_wall_files = dir('**/dist_to_wall.mat');
n_files = length(dist_wall_files);

figure

% Background
n_conditions = 69; % 33
h = 570000;
min_val = -10;
max_val = 570000;
for ii = 1:n_conditions
    
    % create the plot
    st_fr = Log.start_f(ii);
    stop_fr = Log.stop_f(ii)-1;
    w = stop_fr - st_fr;
    dir_id = Log.dir(ii);

    if dir_id == 0 
        if ii == 1 || ii == 33
            col = [0.5 0.5 0.5 0.3];
        elseif ii == 17 || ii == 32
            col = [0 0 0 0.3];
        else
            col = [1 1 1];
        end 
    elseif dir_id == 1
        col = [0 0 1 Log.contrast(ii)*0.75];
    elseif dir_id == -1
        col = [1 0 1 Log.contrast(ii)*0.75];
    end 
    
    % Add rectangles denoting the different types of experiment.
    rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
    ylim([min_val, max_val])
    hold on 
    box off
    ax = gca;
    % ax.XAxis.Visible = 'off';
    xticks([])
end 
ylim([-10 130])

% Add data traces
for idx = 1:n_files 
    % Load the data
    load(fullfile(dist_wall_files(idx).folder, dist_wall_files(idx).name), 'data');

    n_flies = numel(data);

    for i = 1:n_flies
        plot(120 - data{1,i}, 'Color', [0.3 0.3 0.3], 'LineWidth', 0.1); 
        hold on 
    end
end 

% % Add mean 
% all_data = [];
% for ii = 1:n_files
%     % Load the data
%     load(fullfile(dist_wall_files(ii).folder, dist_wall_files(ii).name), 'data');
%     n_flies = numel(data);
%     for jj = 1: n_flies
%         dtt = data{jj};
%         if numel(dtt)<14500
%             continue
%         else
%             dtt = dtt(1:14500);
%             all_data = vertcat(all_data, dtt);
%         end 
%     end 
% end 

% Add mean 
all_data = [];
for ii = 1:n_files
    % Load the data
    load(fullfile(dist_wall_files(ii).folder, dist_wall_files(ii).name), 'data');
    n_flies = numel(data);
    for jj = 1: n_flies
        dtt = data{jj};
        if numel(dtt)<18840
            continue
        else
            dtt = dtt(1:18840);
            all_data = vertcat(all_data, dtt);
        end 
    end 
end 

av_resp = 120 - nanmean(all_data);
plot(av_resp, 'k', 'LineWidth', 3)
xlabel('frame')
ylabel('Distance from centre (mm)')
f = gcf;
f.Position = [23  623  1716  403];
ax = gca;
ax.LineWidth = 1.2;
ax.FontSize = 12;
ax.TickDir = 'out';
ax.TickLength  =[0.005 0.005];
title('Distance from centre of arena - N = 15')

% 
hold on
plot([0 18840], [0 0], 'w', 'LineWidth', 1)
plot([0 18840], [20 20], 'w', 'LineWidth', 1)





