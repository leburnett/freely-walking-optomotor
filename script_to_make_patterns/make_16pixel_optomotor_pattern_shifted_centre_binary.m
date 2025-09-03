% Script to generate the patterns with the centre of the arena translated. 

clear
close all

pat_folder = 'C:\MatlabRoot\Patterns\patterns_oaky';
% pat_name = 'Pattern_21_0-8shift_60deg_1-875step_32frames_1bit_Pattern_G4.mat';
% pat_name = 'Pattern_22_0shift_60deg_1-875step_32frames_1bit_Pattern_G4.mat';
pat_name = 'Pattern_23_minus0-8shift_60deg_1-875step_32frames_1bit_Pattern_G4.mat';

load(fullfile(pat_folder, pat_name));

% Covert from values of 0 and 7, to values of 0 and 1. 
Pats = pattern.Pats;
Pats(Pats(:, :, :)>0)=1;
pattern.Pats = Pats;

pattern.x_num = 32; % Number of frames in the pattern
pattern.y_num = 1; 

pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will use 2 intensity levels
pattern.row_compression = 1;

% Pats = zeros(3, 192, pattern.x_num, pattern.y_num); 	%initializes the array with zeros
% choose contrast levels from 2 numbers that are <=7 and sum up to 9 or less

pattern.Pats = Pats;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);

% Save
save(fullfile(pat_folder, pat_name), 'pattern');
