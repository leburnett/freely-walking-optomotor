% Generate a background greyscale pattern for the interval stimulus.

bkg_val = 3; % With 'gs_val' the range is between 1 and 7. 

pattern.x_num = 2; % There are 192 frames in the pattern.
pattern.y_num = 1; % frames of Y, at different contrast levels
pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 4; % This pattern will use 8 intensity levels
pattern.row_compression = 1;

% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	

% Generate 2 frame pattern with identical frames.
Pats(:, :, 1) = repmat(ones(1,16)*bkg_val, 3, 12); % generate 3 x 192 array
Pats(:, :, 2) = Pats(:, :, 1);

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\MatlabRoot\Patterns\patterns_oaky';
str = [directory_name '\Pattern_25_bkg_3_gsval4_2frames.mat']; 	% name must begin with ‘Pattern_’
save(str, 'pattern');


%% Code to view pattern to check 

 % % % % display stimulus
% figure;
% imshow(Pats(:,:,1))
% for k = 1:192
%     imagesc(Pats(:,:,k));
%     pause(0.01)
% end
