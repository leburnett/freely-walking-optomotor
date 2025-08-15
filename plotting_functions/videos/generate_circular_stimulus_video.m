% function pattern_video(pattern_array, filename, fps)
% pattern_video: Visualises cylindrical LED patterns from top view as a donut
%
% pattern_array: 3D array (X x Y x T) — pattern over time
% filename: name of output video file (e.g., 'pattern.mp4')
% fps: frames per second for video output

A = repmat(pattern.Pats, 100, 1);

filename = "test";
fps =30;
bg_val = 0.9;

% pattern_video_cylindrical
% Visualises a flat cylindrical LED arena pattern as viewed from above
%
% A: 3D array (H x W x T), H=vertical pixels, W=LED columns, T=time frames
% filename: e.g., 'arena_view.mp4'

    [H, W, T] = size(A);

    % Output resolution
    out_size = 1000; % pixels (square output)
    [X, Y] = meshgrid(linspace(-1,1,out_size), linspace(-1.1,1.1,out_size));
    R = sqrt(X.^2 + Y.^2);
    Theta = atan2(Y, X); % -pi to pi

    % Arena radii (normalized)
    inner_r = 0.6; % hole in center
    outer_r = 0.99;

    % Normalize angle to [0, W)
    col_idx = mod(Theta + 2*pi, 2*pi) / (2*pi) * W + 1;
    col_idx(col_idx > W) = 1; % wrap exactly W back to 1

    % Normalize radius to [0, H)
    row_idx = (outer_r - R) / (outer_r - inner_r) * (H - 1) + 1;

    % Mask for valid arena pixels
    valid_mask = (R >= inner_r) & (R <= outer_r);

    % Video writer
    v = VideoWriter(filename, 'MPEG-4');
    v.FrameRate = fps;
    open(v);

    fig = figure('Color','k','Position',[100 100 600 600]);
    ax = axes('Position',[0 0 1 1]); axis off equal;

    for t = 1:T
        % Current frame
        frame = double(A(:,:,t));

        % Interpolate pattern onto circular map
        warped = interp2(1:W, (1:H)', frame, col_idx, row_idx, 'nearest', NaN);

        % Fill background with light grey
        warped(~valid_mask) = bg_val;

        imagesc(warped, [0 1]); % keep consistent intensity range

        imagesc(warped, 'AlphaData', ~isnan(warped));
        axis off equal tight;
        colormap(gray); % change if you like
        drawnow;

        writeVideo(v, getframe(fig));
    end

    close(v);
    disp(['Video saved: ', filename]);

