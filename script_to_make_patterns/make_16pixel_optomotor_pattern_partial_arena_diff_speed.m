% Make 16 pixel - 60 deg gratings - 1/2 arena different speeds

% pattern 78 = one half twice as fast.
% pattern 79 = one half three times as fast. 
% pattern 80 = one half 60 deg going double speed to other half 30 deg.

pattern.x_num = 192; % There are 192 pixel around the display (24x8)- if moves by 1 pixel each frame.
pattern.y_num = 1; % frames of Y, at different contrast levels
pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will use 8 intensity levels
pattern.row_compression = 1;

%% Create full pattern moving at 1 pixel per frame.
% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	
Pats(:, :, 1) = repmat([0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1], 3, 6); 
% Update the pattern for each frame
for j = 2:192 			%use ShiftMatrixPats to rotate stripe image
    Pats(:,:,j) = ShiftMatrix(Pats(:,:,j-1),1,'r','y');
end

%% Create another full pattern moving at 2 pixels per frame.
% Generate empty array with zeros - [3, 192] x frames (192)
Pats2 = zeros(3, 192, pattern.x_num, pattern.y_num); 	
Pats2(:, :, 1) = repmat([0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1], 3, 6); 
% Update the pattern for each frame
for j = 2:192 			%use ShiftMatrixPats to rotate stripe image
    Pats2(:,:,j) = ShiftMatrix(Pats2(:,:,j-1),3,'r','y');
end

%% % % % % % % %% 60 versus 30

%% Create full pattern moving at 1 pixel per frame.
% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	
Pats(:, :, 1) = repmat([0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1], 3, 6); 
% Update the pattern for each frame
for j = 2:192 			%use ShiftMatrixPats to rotate stripe image
    Pats(:,:,j) = ShiftMatrix(Pats(:,:,j-1),2,'r','y');
end

%% Create another full pattern moving at 2 pixels per frame.
% Generate empty array with zeros - [3, 192] x frames (192)
Pats2 = zeros(3, 192, pattern.x_num, pattern.y_num); 	
Pats2(:, :, 1) = repmat([0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1], 3, 6); 
% Update the pattern for each frame
for j = 2:192 			%use ShiftMatrixPats to rotate stripe image
    Pats2(:,:,j) = ShiftMatrix(Pats2(:,:,j-1),1,'r','y');
end

%%
Pats(:, 97:192, :) = Pats2(:, 97:192, :);

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\Users\labadmin\Documents\GitHub\freely-walking-optomotor\patterns\Patterns_optomotor';
% str = [directory_name '\Pattern_78_optomotor_16pixel_binary_97-192_2px_per_frame.mat']; 	% name must begin with ‘Pattern_’
% str = [directory_name '\Pattern_79_optomotor_16pixel_binary_97-192_3px_per_frame.mat']; 	% name must begin with ‘Pattern_’
str = [directory_name '\Pattern_80_optomotor_binary_1-96_60deg_2px_97-192_30deg_1px.mat'];

save(str, 'pattern');

%% Code to view pattern to check 

 % % % % display stimulus
% figure;
% imshow(Pats(:,:,1))
% for k = 1:192
%     imagesc(Pats(:,:,k));
%     pause(0.01)
% end
