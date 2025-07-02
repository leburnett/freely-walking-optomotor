% analyse shifted centre of rotation stimulus


% From calibration file 
% centroid - [512, 520]
% PPM - 4.1691
% r = 496 

% These are all in pixels. 

% From the image of stimulus. 
% The part of the arena with the narrow gratings during the shifted CoR
% stimulus  =~ [600, 36] on the edge of the arena. 
% 0.8 * 496 = 396.8 = 99.2 pixels from the edge. 

A = [512, 520]; % Centre of arena
B = [600, 36]; % Point on the edge of the arena where the bars are the narrowest. 
t = 0.8; % degree shifted towards edge. 

P = (1 - t) * A + t * B; % Coordinates of the new shifted centre of rotation. 

% Calculate the distance from this point for all flies. 

%% Plot this point on a frame. 

video_files = dir('*.ufmf');
if isempty(video_files)
    disp('No .ufmf video files found in this folder.')
else
    filename = video_files(1).name;
end 

[readframe,~,fid,~] = get_readframe_fcn(filename);

im = readframe(1);
im2 = cat(3, im, im, im);
imshow(im2);
hold on
plot(P(1), P(2), 'r+', 'MarkerSize', 15, 'LineWidth', 2)

plot(A(1), A(2), 'k+', 'MarkerSize', 15, 'LineWidth', 2)
plot(B(1), B(2), 'b+', 'MarkerSize', 15, 'LineWidth', 2)


%% 

a = abs(DATA.jfrc100_es_shibire_kir.F(2).R1_condition_7.av_data);
% b = DATA.jfrc100_es_shibire_kir.F(2).R1_condition_7.IFD_data;
b = DATA.jfrc100_es_shibire_kir.F(2).R1_condition_7.view_dist;

figure; 
for i = 1% :16
    a_binned = 

    plot(b(i, 350:1200), a(i, 350:1200), 'Color', [0.8 0.8 0.8]); hold on
end 


figure; 
for i = 1:16
    imagesc(pattern.Pats(:, :, i));
    pause(0.5)
end 


figure;
imagesc(pattern.Pats(:, :, 3));




