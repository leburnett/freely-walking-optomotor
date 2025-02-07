% Generate a stimulus for freely walking bar fixation.
% ON background with OFF bars. 
% For the time being make the pattern binary - but this could be changed to
% be 4-bit in the future. 

% 2 x 4 pixel bars at 180 degrees from each other. 

pattern.x_num = 2; % There are 2 frames. 
pattern.y_num = 1; % frames of Y, at different contrast levels
pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will use 8 intensity levels
pattern.row_compression = 1;

% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	

% Generate 2 frame pattern with identical frames.
array1 = repmat([zeros(1, 4), ones(1, 92)], 3, 2);
array2 = repmat([ones(1, 46), zeros(1, 4), ones(1, 46)], 3, 2);

Pats(:, :, 1) = array1; % generate 3 x 192 array
Pats(:, :, 2) = array2;

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\MatlabRoot\Patterns\patterns_oaky';
str = [directory_name '\Pattern_30_4px_bar_fixation.mat']; 	% name must begin with ‘Pattern_’
save(str, 'pattern');


%% Code to view pattern to check 

 % % % % display stimulus
% figure;
% imshow(Pats(:,:,1))
% for k = 1:192
%     imagesc(Pats(:,:,k));
%     pause(0.01)
% end
