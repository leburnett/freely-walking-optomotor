% Make a pattern with 8 pixel width bars to generate a 30 degree B&W
% grating.

shiftby = 2; % Shift the pattern by 2 pixels per frame not 1. 

pattern.x_num = 192/shiftby; % Number of frames
pattern.y_num = 1; % frames of Y, at different contrast levels
pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will use 8 intensity levels
pattern.row_compression = 1;

% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	

% Check how many times the pattern goes around the entire arena.
% array = repmat([0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1], 3, 12);
% array(1) = 4;
% Pats(:, :, 1) = array; 

Pats(:, :, 1) = repmat([0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1], 3, 12); 

% Update the pattern for each frame
for j = 2:(192/shiftby)			%use ShiftMatrixPats to rotate stripe image
    Pats(:,:,j) = ShiftMatrix(Pats(:,:,j-1),shiftby,'r','y');
end 

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\MatlabRoot\Patterns\patterns_oaky';
str = [directory_name '\Pattern_26_optomotor_8pixel_binary_2pxsteps.mat']; 	% name must begin with ‘Pattern_’
save(str, 'pattern');


%% Code to view pattern to check 

 % % % % display stimulus
% figure;
% imshow(Pats(:,:,1))
% for k = 1:96
%     imagesc(Pats(:,:,k));
%     pause(0.01)
% end
