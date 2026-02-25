
% Things to add to patterns made on the tethered flight computer with the
% GUI.

pattern.num_panels = 72; % This is the number of unique Panel IDs required.
pattern.row_compression = 0;
A = 1:72;              	% define panel structure vector
pattern.Panel_map = fliplr(flipud(reshape(A, 3, 24)));
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = make_pattern_vector(pattern);












