% Create 'curtain' patterns of OFF moving edge. 16 pixel wide curtain area.

% 16 pixel total width
total_width = 32;
bkg_colour = 4;
curt_colour = 0; % max 14

pattern.x_num = total_width+1;
pattern.y_num = 1; % frames of Y, at different contrast levels
pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 4; % This pattern will use 8 intensity levels
pattern.row_compression = 1;

% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	

% Generate the curtain patterns:

for i = 0:total_width
        n_off = i;
        n_on = total_width - n_off;
        array  = [ones(1, n_off)*curt_colour, ones(1, n_on)*bkg_colour];
        px_array = repmat(array, [1, 2]);
        Pats(:, :, i+1) = repmat(px_array, 3, 192/(total_width*2)); 
end 

pattern.Pats = Pats;

A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\MatlabRoot\Patterns\patterns_oaky';
str = [directory_name '\Pattern_55_OFF_curtains_32px_4_0.mat']; 	% name must begin with ‘Pattern_’
save(str, 'pattern');


%% Code to view pattern to check 

% % % % display stimulus
figure;
for k = 1:numel(Pats(1, 1, :))
    imagesc(Pats(:,:,k));
    pause(0.25)
end
