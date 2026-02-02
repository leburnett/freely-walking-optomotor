function fig = generate_stim_image_from_array(Barpat_bin, inner_radius_prop)

    % Inputs
    % ______

    % Barpat_bin [double]
    %   Binary 2D array containing the LED pixel values of the frame that 
    %   is being presented. 

    % inner_radius_prop [float]
    %   Proportion of the circular area you want to fill with white 
    %   space in the middle to represent the floor. Default = 0.6.

    if isempty(inner_radius_prop)
        inner_radius_prop = 0.6;
    end 
    
    frame = Barpat_bin;
    output_size = 2000; % Size of the final MATLAB figure in pixels. (square output)
    [Hs, Ws] = size(frame);
    
    % Polar grid over your output canvas size
    [X, Y] = meshgrid(linspace(-1,1,output_size), linspace(-1.1,1.1,output_size));
    R     = sqrt(X.^2 + Y.^2);
    Theta = atan2(Y, X);                          % -pi..pi
    
    % Arena radii (normalized)
    inner_r = inner_radius_prop;       % hole radius
    outer_r = 1;
    
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
    thick_px = 0.1;              % thickness in pixels
    
    % Convert pixel thickness to a radial thickness
    dr = thick_px / (output_size/2);
    
    % Mask of ring (outline)
    ring_mask = abs(R - r_target) <= dr/2;
    ring_val = 0; 
    warped(ring_mask) = ring_val;
    
    % Convert to RGB intensity (NOT ind2rgb: this is not indexed)
    canvas = repmat(mat2gray(warped), 1, 1, 3);  % double, [0,1]
    
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

    % If you want to view the "frame" and the warped output run the
    % following code:

        % figure; 
        % subplot(4, 1, 1)
        % imshow(frame);
        % subplot(4, 1, 2:4)
        % imshow(canvas);

    figure;
    fig = imshow(canvas);
    axis square

end 
