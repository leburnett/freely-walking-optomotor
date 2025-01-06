% Create 'curtain' patterns of ON moving edge. 16 pixel wide curtain area.

% 16 pixel total width
total_width = 16;

pattern.x_num = total_width+1; 
pattern.y_num = 1; % frames of Y, at different contrast levels
pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will use 8 intensity levels
pattern.row_compression = 1;

% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	

% Generate the curtain patterns:

for i = 0:total_width
    n_on = i;
    n_off = total_width - n_on;
    array  = [ones(1, n_on), zeros(1, n_off)];
    px_array = repmat(array, [1, 2]);
    Pats(:, :, i+1) = repmat(px_array, 3, 6); 
end 

pattern.Pats = Pats;

A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\MatlabRoot\Patterns\patterns_oaky';
str = [directory_name '\Pattern_19_ON_curtains_16px.mat']; 	% name must begin with ‘Pattern_’
save(str, 'pattern');


%% Code to view pattern to check 

% % % display stimulus
% figure;
% for k = 1:numel(Pats(1, 1, :))
%     imshow(Pats(:,:,k));
%     pause(0.25)
% end
