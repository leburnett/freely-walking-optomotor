function canvas = combine_stimulus_and_frame(frame, im, f, trx)
    % Function to take in pattern and frame and combine them together

    % frame = stimulus frame [3 x 192] - individual frame
    % im = behavioural video frame
    % f = frame number of behavioural video. 
    % trx - contains tracking data

    % Output size of the video (pixels)
    output_size = 1500; % (square output)
    add_tracks = 1;
    fps = 30;

    %% Draw the stimulus from pattern.Pats:

    [Hs, Ws] = size(frame);
    
    % Polar grid over your output canvas size
    [X, Y] = meshgrid(linspace(-1,1,output_size), linspace(-1.1,1.1,output_size));
    R     = sqrt(X.^2 + Y.^2);
    Theta = atan2(Y, X);                          % -pi..pi
    
    % Arena radii (normalized)
    inner_r = 0;       % hole radius
    outer_r = 0.99;
    
    % Map angle to column in [1..W]
    col_idx = mod(Theta, 2*pi) / (2*pi) * Ws + 1;
    col_idx = min(max(col_idx, 1), Ws);           % clamp
    
    % Map radius to row in [1..H]: outer_r->row=1, inner_r->row=H
    row_idx = (outer_r - R) / (outer_r - inner_r) * (Hs - 1) + 1;
    row_idx = min(max(row_idx, 1), Hs);           % clamp
    
    % Valid ring mask
    valid_mask = (R >= inner_r) & (R <= outer_r);
    
    % Interpolate; give an extrapolation value to avoid NaNs
    bg_val = 1;  % in [0,1]
    warped = interp2(1:Ws, (1:Hs)', frame, col_idx, row_idx, 'nearest', bg_val);

    % Fill outside the ring
    warped(~valid_mask) = bg_val;

    % Add outline of the arena in black.
    r_target = 0.99;
    thick_px = 3;              % thickness in pixels
    % Convert pixel thickness to a radial thickness
    dr = thick_px / (output_size/2);
    
    % Mask of ring (outline)
    ring_mask = abs(R - r_target) <= dr/2;
    ring_val = 0; 
    warped(ring_mask) = ring_val;
    
    % Convert to RGB intensity (NOT ind2rgb: this is not indexed)
    canvas = repmat(mat2gray(warped), 1, 1, 3);  % double, [0,1]

    % %  Recolor white parts of stimulus to be green.
        % Define "white" with a tolerance (adjust if needed)
        white_tol = 0.999;
        
        % Only recolor white pixels that are inside the valid ring and not in the outline
        green_mask = valid_mask & ~ring_mask & (warped >= white_tol);
        
        % Make those pixels pure green
        r = canvas(:,:,1);
        r(green_mask) = 0; 
        canvas(:, :, 1) = r;
    
        g = canvas(:,:,2);
        g(green_mask) = 0.75;   
        canvas(:,:,2) = g;
    
        b = canvas(:,:,3);
        b(green_mask) = 0;
        canvas(:,:,3) = b;
        
        % Ensure outside the ring stays exactly bg_val on all channels
        for ch = 1:3
            tmp = canvas(:,:,ch);
            tmp(~valid_mask) = bg_val;
            canvas(:,:,ch) = tmp;
        end

    [Hc, Wc, ~] = size(canvas);

    %% Add behavioural video frame in the centre
    
    % Find the pixels to show:
    mask1 = im>uint8(255/2); % Find bright pixels. 
    mask = imfill(mask1, 'holes');
    m3   = repmat(mask, 1, 1, 3);

    % Convert to RGB
    im_rgb = repmat(mat2gray(im), 1, 1, 3);
    [Hi,Wi,~] = size(im_rgb);
    
    % Overwrite the pixel values in "im" with the trajectories.
    if add_tracks
        tail_length = 3*fps;                % 3s
        rng = max(1, f-tail_length):f;      % safe indices
        n_flies = numel(trx);
        cmap = hsv(n_flies);                % colors in [0,1]
        line_radius = 2;                    % thickness control (pixels)
        SE = strel('disk', line_radius);    % change radius for thicker/thinner
    
        % For each fly, build a mask of its path, dilate once, then paint
        for fly = 1:n_flies
            x = round(trx(fly).x(rng));
            y = round(trx(fly).y(rng));
    
            % Clip to image bounds
            x = min(max(x,1), Wi);
            y = min(max(y,1), Hi);
    
            % Accumulate all segment pixels into a mask
            m = false(Hi,Wi);
            for k = 2:numel(x)
                [xx, yy] = bresenham(x(k-1), y(k-1), x(k), y(k));   % integer coords
                m(sub2ind([Hi,Wi], yy, xx)) = true;
            end
    
            % Thicken the mask
            m = imdilate(m, SE);
    
            % Paint (overwrite) in color for this fly
            col = cmap(fly,:);  % [r g b] in [0,1]
            im_rgb(:,:,1) = im_rgb(:,:,1).*(~m) + col(1).*m;
            im_rgb(:,:,2) = im_rgb(:,:,2).*(~m) + col(2).*m;
            im_rgb(:,:,3) = im_rgb(:,:,3).*(~m) + col(3).*m;
        end
    end
        
    r0 = floor((Hc - Hi)/2) -10;
    c0 = floor((Wc - Wi)/2) + 1;
    
    % Paste only masked pixels
    sub = canvas(r0:r0+Hi-1, c0:c0+Wi-1, :);
    sub(m3) = im_rgb(m3);
    canvas(r0:r0+Hi-1, c0:c0+Wi-1, :) = sub;

end 