function idxes = check_tracking_FlyTrk(trx)

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