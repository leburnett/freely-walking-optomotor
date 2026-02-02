% Script to generate the patterns with the centre of the arena translated. 

% Load the new patterns made from the other computer:
pattern1 = load("C:\MatlabRoot\FreeWalkOptomotor\Patterns_optomotor_offset\0001_30deg_gratings_7on_0off_0shift_Pattern_G4.mat");
pattern2 = load("C:\MatlabRoot\FreeWalkOptomotor\Patterns_optomotor_offset\0002_30deg_gratings_7on_0off_0-75shift_Pattern_G4.mat");
pattern3 = load("C:\MatlabRoot\FreeWalkOptomotor\Patterns_optomotor_offset\0003_30deg_gratings_7on_0off_-0-75shift_Pattern_G4.mat");
pattern4 = load("C:\MatlabRoot\FreeWalkOptomotor\Patterns_optomotor_offset\0004_30deg_gratings_7on_0off_0-5shift_Pattern_G4.mat");

% Covert from values of 0 and 7, to values of 0 and 1. 
pats = pattern1.pattern.Pats;
pats(pats(:, :, :)>=0)=1;
pattern1.pattern.Pats = pats;

pats = pattern2.pattern.Pats;
pats(pats(:, :, :)>=0)=1;
pattern2.pattern.Pats = pats;

pats = pattern3.pattern.Pats;
pats(pats(:, :, :)>=0)=1;
pattern3.pattern.Pats = pats;

pats = pattern4.pattern.Pats;
pats(pats(:, :, :)>=0)=1;
pattern4.pattern.Pats = pats;

pattern.x_num = 192; % There are 192 pixel around the display (24x8) 
pattern.y_num = 4; % frames of Y, 4 different positions for the centre of the arena.
% 1 - centre
% 2 = 0.75
% 3 = -0.75
% 4 = 0.5

pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will use 2 intensity levels
pattern.row_compression = 1;

Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	%initializes the array with zeros
% choose contrast levels from 2 numbers that are <=7 and sum up to 9 or less

% HERE - load the pattern made on the tethered flight arena computer to
% have the arena translated by 0-1. Load it as pattern2. 

%30 degree wavelength - 16 pixels

% Use the top three rows from the pattern generated on the other
% computer as the pattern here. 

% First 'condition' = centre of the arena.
for j = 1:12
    Pats(:, :, (j*16)-15:16*j, 1) = pattern1.pattern.Pats(1:3, :, 1:16);
end 


% Second condition = centre shifted by 0.75. Three quarters of the distance
% from the centre of the arena to the edge. 
% - - - - - LOAD NEW PATTERN
for j = 1:12
    Pats(:, :, (j*16)-15:16*j, 2) = pattern2.pattern.Pats(1:3, :, 1:16);
end

% Third condition = centre shifted by -0.75. Three quarters of the distance
% from the centre of the arena to the edge on the other side.
% - - - - - LOAD NEW PATTERN
for j = 1:12
    Pats(:, :, (j*16)-15:16*j, 3) = pattern3.pattern.Pats(1:3, :, 1:16);
end

% Second condition = centre shifted by 0.75. Three quarters of the distance
% from the centre of the arena to the edge. 
% - - - - - LOAD NEW PATTERN
for j = 1:12
    Pats(:, :, (j*16)-15:16*j, 4) = pattern4.pattern.Pats(1:3, :, 1:16);
end

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);
directory_name = 'C:\MatlabRoot\Patterns';
str = [directory_name '\Pattern_09_optomotor_8pixel_shifted_binary.mat'] 	% name must begin with ‘Pattern_’
save(str, 'pattern');
