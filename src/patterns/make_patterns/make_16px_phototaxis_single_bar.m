% Phototaxis - single bright bar - 32 pixels width - 60 deg VA - binary - black
% background.

pattern.x_num = 1; % There are 2 frames. 
pattern.y_num = 1; % frames of Y, at different contrast levels
pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will use 8 intensity levels
pattern.row_compression = 1;

% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	

bar_pw = 32;
int_pw = 192-bar_pw;
array1 = repmat([ones(1, bar_pw), zeros(1, int_pw)], 3, 1);

Pats(:, :, 1) = array1; 

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\MatlabRoot\Patterns\patterns_oaky';
str = [directory_name '\Pattern_57_32px_single_bar_ON.mat']; 	% name must begin with ‘Pattern_’
save(str, 'pattern');

%% Code to view pattern to check 

 % % % % display stimulus
% figure;
% imshow(Pats(:,:,1))
% for k = 1:192
%     imagesc(Pats(:,:,k));
%     pause(0.01)
% end
