% 16 pixel width bars - flicker - gs_val = 3, ON = 3.

pattern.x_num = 2; % Number of frames.
pattern.y_num = 1; % 
pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 3; % This pattern will use 8 intensity levels
pattern.row_compression = 1;

% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	

% Initialise the first frame. Here it is an 16 pixel by 16 pixel stripe
% pattern. 
off_value = 0;
on_value = 3; % max = 7; 
off_bar_pixels = ones(1,16)*off_value;
on_bar_pixels = ones(1,16)*on_value;

Pats(:, :, 1) = repmat([off_bar_pixels, on_bar_pixels], 3, 6); 
Pats(:, :, 2) = repmat([on_bar_pixels, off_bar_pixels], 3, 6); 

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\MatlabRoot\Patterns\patterns_oaky\';
str = [directory_name '\Pattern_65_flicker_16pixel_gs_val-3_on-3_off-0.mat']; 	% name must begin with ‘Pattern_’
save(str, 'pattern');


%% Code to view pattern to check 

% display stimulus
% figure;
% imshow(Pats(:,:,1))
% for k = 1:192
%     imagesc(Pats(:,:,k));
%     pause(0.01)
% end
% display ('end');