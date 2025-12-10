% Make 16 pixel - 60 deg gratings - only 1/3 or 1/2 of the arena. 

pattern.x_num = 192; % There are 192 pixel around the display (24x8)- if moves by 1 pixel each frame.
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

% Make 2/3 of the arena dark. 1/3 of the arena = 64 pixels.

% 74
% Pats(:, 1:128 ,:) = zeros(size(Pats(:, 1:128 ,:)));

% 75
% Pats(:, 1:64 ,:) = zeros(size(Pats(:, 1:64 ,:)));
% Pats(:, 129:192 ,:) = zeros(size(Pats(:, 129:192 ,:)));

% 76
% Pats(:, 65:192 ,:) = zeros(size(Pats(:, 65:192 ,:)));

% 77 
Pats(:, 1:96 ,:) = zeros(size(Pats(:, 1:96, :)));

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
% directory_name = 'C:\MatlabRoot\Patterns';
directory_name = 'C:\Users\labadmin\Documents\GitHub\freely-walking-optomotor\patterns\Patterns_optomotor';
% str = [directory_name '\Pattern_74_optomotor_16pixel_binary_129-192_only.mat']; 	% name must begin with ‘Pattern_’
str = [directory_name '\Pattern_77_optomotor_16pixel_binary_97-192_only.mat']; 	% name must begin with ‘Pattern_’

save(str, 'pattern');


%% Code to view pattern to check 

 % % % % display stimulus
% figure;
% imshow(Pats(:,:,1))
% for k = 1:192
%     imagesc(Pats(:,:,k));
%     pause(0.01)
% end
