% Make Reverse Phi stimulus:
% Greyscale version. 
% Swaps between ON and OFF bar every frame.
% 8 pixel width bar - 24 pixels of greyscale background in between. 

bkg_colour = 1; 
on_colour = 3;
off_colour = 0;

bar_width_px = 16; 
gap_px = 16;

shiftpx = 4;

pattern.x_num = 192/shiftpx; % There are 192 frames in this pattern
pattern.y_num = 1; % frames of Y, at different contrast levels
pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 2; % GREYSCALE - This pattern will use 7 intensity levels
pattern.row_compression = 1;

%% Generate separate ON and OFF patterns first:
Pats_ON = zeros(3, 192, pattern.x_num, pattern.y_num); 
Pats_OFF = zeros(3, 192, pattern.x_num, pattern.y_num); 

ON_pattern = repmat([ones(1,bar_width_px)*on_colour,  ones(1, gap_px)*bkg_colour], 3, 6); 
OFF_pattern = repmat([ones(1,bar_width_px)*off_colour,  ones(1, gap_px)*bkg_colour], 3, 6); 
Pats_ON(:, :, 1) = ON_pattern; 
Pats_OFF(:, :, 1) = OFF_pattern; 

% Update the pattern for each frame
for j = 2:192/shiftpx 			%use ShiftMatrixPats to rotate stripe image
    Pats_ON(:,:,j) = ShiftMatrix(Pats_ON(:,:,j-1),shiftpx,'r','y');
end

% Update the pattern for each frame
for j = 2:192/shiftpx 			%use ShiftMatrixPats to rotate stripe image
    Pats_OFF(:,:,j) = ShiftMatrix(Pats_OFF(:,:,j-1),shiftpx,'r','y');
end

%% Then generate a combined frame that swaps between the ON and OFF patterns every frame. 

% Generate empty array with zeros - [3, 192] x frames (192)
Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 

% Start with the ON bar
Pats(:, :, 1) = ON_pattern; 
% Update the pattern for each frame
for j = 2:192/shiftpx
    if mod(j, 2)==0 % even - use OFF bar stimulus
        Pats(:,:,j) = Pats_OFF(:,:,j);
    else % odd - use ON bar
        Pats(:,:,j) = Pats_ON(:,:,j);
    end 
end 

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\MatlabRoot\Patterns\patterns_oaky';
str = [directory_name '\Pattern_62_RevPhi_gsval2_0_1_3_16-16px_4px_step.mat']; 	% name must begin with ‘Pattern_’
save(str, 'pattern');


%% Code to view pattern to check 

%  % % % % display stimulus
% figure;
% imshow(Pats_ON(:,:,1))
% for k = 1:192
%     imagesc(Pats_ON(:,:,k));
%     pause(0.01)
% end
% 
% figure;
% imshow(Pats_OFF(:,:,1))
% for k = 1:192
%     imagesc(Pats_OFF(:,:,k));
%     pause(0.01)
% end
% 
% figure;
% imshow(Pats(:,:,1))
% for k = 1:192/shiftpx
%     imagesc(Pats(:,:,k));
%     pause(0.1)
% end


