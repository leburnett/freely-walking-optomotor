
pattern.x_num = 192; % There are 192 pixel around the display (24x8) 
pattern.y_num = 1; % frames of Y, at different contrast levels
pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will use 8 intensity levels
pattern.row_compression = 1;

% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	

% Initialise the first frame. Here it is an 8 pixel by 8 pixel stripe
% pattern. 
Pats(:, :, 1) = repmat([0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1], 3, 6); 

% Update the pattern for each frame
for j = 2:192 			%use ShiftMatrixPats to rotate stripe image
    Pats(:,:,j) = ShiftMatrix(Pats(:,:,j-1),1,'r','y');
end 

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\MatlabRoot\Patterns';
str = [directory_name '\Pattern_10_optomotor_16pixel_binary.mat']; 	% name must begin with ‘Pattern_’
save(str, 'pattern');


%% Code to view pattern to check 

 % % % % display stimulus
% figure;
% imshow(Pats(:,:,1))
% for k = 1:192
%     imagesc(Pats(:,:,k));
%     pause(0.01)
% end
