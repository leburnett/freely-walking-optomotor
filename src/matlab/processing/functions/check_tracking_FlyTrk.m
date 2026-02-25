function idxes = check_tracking_FlyTrk(trx)
% Check the data that is returned from FlyTracker and return the rows that
% do not have the mode number of data points. Assumption is that something
% has gone wrong with the tracking and one fly has been split into two, or
% a non-fly object has been tracked accidentally.

% Extract the number of frames for all flies:
d = [trx.nframes];

% Mode = probable number of frames in video - can this be gathered from
% elsewhere?
nframes_video = mode(d);

% Find which rows do not have this many frames - likely messed up tracking.
fun = @(x) trx(x).nframes ~= nframes_video;
tf2 = arrayfun(fun, 1:numel(d));
idxes = find(tf2);

disp(strcat(num2str(numel(idxes)), " flies had poor tracking and will be ignored."))

end 