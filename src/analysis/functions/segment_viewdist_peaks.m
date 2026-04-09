function [flat, n_segs, n_excluded] = segment_viewdist_peaks( ...
        x_all, y_all, vd_all, arena_center, fps, ...
        smooth_win, min_prom, min_seg_frames, max_dist)
% SEGMENT_VIEWDIST_PEAKS  Extract peak-to-peak segments from view_dist.
%
%   [flat, n_segs, n_excluded] = SEGMENT_VIEWDIST_PEAKS(x_all, y_all,
%       vd_all, arena_center, fps, smooth_win, min_prom, min_seg_frames, max_dist)
%
%   Finds peaks in the smoothed view_dist signal for each fly and extracts
%   the trajectory between consecutive peaks. Returns a flat struct with
%   per-segment metrics.
%
%   INPUTS:
%     x_all, y_all   - [n_flies x n_frames] position data (mm)
%     vd_all          - [n_flies x n_frames] viewing distance data (mm)
%     arena_center    - [1 x 2] arena centre coordinates (mm)
%     fps             - frames per second
%     smooth_win      - moving average window (frames)
%     min_prom        - minimum peak prominence for findpeaks (mm)
%     min_seg_frames  - minimum frames in a valid segment
%     max_dist        - maximum bbox midpoint distance from centre (mm)
%
%   OUTPUT:
%     flat       - struct with fields: fly_id, area, aspect, tort, dist, dur
%     n_segs     - total number of valid segments
%     n_excluded - number of segments excluded (dist > max_dist)
%
%   See also: findpeaks, find_trajectory_loops

    flat.fly_id = [];  flat.area = [];  flat.aspect = [];
    flat.tort = [];    flat.dist = [];  flat.dur = [];
    n_segs = 0;  n_excluded = 0;

    for f = 1:size(x_all, 1)
        vd = vd_all(f,:);  xf = x_all(f,:);  yf = y_all(f,:);
        vdc = vd; vdc(isnan(vdc)) = 0;
        vds = movmean(vdc, smooth_win, 'omitnan');
        vds(isnan(vd)) = NaN;
        [~, pl] = findpeaks(vds, 'MinPeakProminence', min_prom, 'MinPeakDistance', 5);
        if numel(pl) < 2, continue; end

        for k = 1:(numel(pl)-1)
            sf = pl(k); ef = pl(k+1);
            if ef-sf+1 < min_seg_frames, continue; end
            xs = xf(sf:ef); ys = yf(sf:ef);
            v = ~isnan(xs) & ~isnan(ys);
            xv = xs(v); yv = ys(v);
            if numel(xv) < min_seg_frames, continue; end

            w = max(xv)-min(xv); h = max(yv)-min(yv);
            mx = (min(xv)+max(xv))/2; my = (min(yv)+max(yv))/2;
            dc = sqrt((mx-arena_center(1))^2 + (my-arena_center(2))^2);
            if dc > max_dist, n_excluded = n_excluded+1; continue; end

            dxs = diff(xv); dys = diff(yv);
            pl_len = sum(sqrt(dxs.^2+dys.^2));
            disp_len = sqrt((xv(end)-xv(1))^2+(yv(end)-yv(1))^2);
            if disp_len > 0.5, tort = pl_len/disp_len; else, tort = NaN; end

            flat.fly_id = [flat.fly_id; f];
            flat.area   = [flat.area; w*h];
            flat.aspect = [flat.aspect; max(w,h)/max(min(w,h),0.01)];
            flat.tort   = [flat.tort; tort];
            flat.dist   = [flat.dist; dc];
            flat.dur    = [flat.dur; (ef-sf)/fps];
            n_segs = n_segs+1;
        end
    end
end
