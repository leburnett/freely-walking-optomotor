function create_stim_video_loop(log, trx, video_filename, rep, add_tracks)
    
    % JAABA function determines the readframe function to use:
    [readframe,~,fid,~] = get_readframe_fcn(video_filename);
    
    % lowercase log is LOG.log_X. 
    optomotor_pattern = log.optomotor_pattern;
    interval_pattern = log.interval_pattern;
    optomotor_speed = log.optomotor_speed;
    interval_speed = log.interval_speed;
    condition_n = log.which_condition;

    % Output size of the video (pixels)
    output_size = 1700; % (square output)

    %% Load the patterns
    pattern_folder = "/Users/burnettl/Documents/GitHub/freely-walking-optomotor/patterns/Patterns_optomotor";
    pattern_list = dir(fullfile(pattern_folder, "Pattern_*"));

    % Load the optomotor pattern
    pattern_str = sprintf('Pattern_%02d', optomotor_pattern);
    pattern_idx = contains({pattern_list.name}, pattern_str);
    pattern_file = pattern_list(pattern_idx).name;
    load(fullfile(pattern_folder, pattern_file), 'pattern');
    opto_pattern = pattern;

    % Load the interval pattern:
    pattern_str = sprintf('Pattern_%02d', interval_pattern);
    pattern_idx = contains({pattern_list.name}, pattern_str);
    pattern_file = pattern_list(pattern_idx).name;
    load(fullfile(pattern_folder, pattern_file), 'pattern');
    int_pattern = pattern;


    % num_sections will be 3 if the stimulus changes direction
    % 2 if static.
    num_sections = numel(log.start_f);


    % Only present every other frame to save space.
    fr_int = 2;
    frame_rng = start_f:fr_int:stop_f;


    %% Open empty avi file. 
    movie_name = strcat(video_filename(17:end-10), '_condition', string(condition_n),'_pattern', string(optomotor_pattern), '_rep', string(rep), '.mp4');
    fps = 30;
    movie_obj = VideoWriter(movie_name, 'MPEG-4');
    set(movie_obj,'FrameRate',fps);
    set(movie_obj,'Quality', 100);
    open(movie_obj);

    % Show the behaviour before the stimulus as well. 
    time_before_stim = 10;
    frames_before_stim = time_before_stim*fps;

    frame_rng  = log.start_f(1)-frames_before_stim:log.stop_f(end);
    
    % Start with the interval pattern
    current_patt = int_pattern;

    %% Generate the movie:

    % If there are 3 sections 

    % From 1 : log.start_f(1) -- - -interval stimulus 
    % log.start_f(1)+1:log.stop_f(1) - - - - stimulus moving +
    % log.start_f(2)+1:log.stop_f(2) - - - - -stimulus moving - 
    % log.start_f(3)+1: log.stop_f(3) - - - interval. 

    % If there are 2 
    % From 1 : log.start_f(1) -- - -interval stimulus 
    % log.start_f(1)+1:log.stop_f(1) - - - - stimulus
    % log.start_f(2)+1:log.stop_f(2) - - - - - interval


    for f = frame_rng
        
        % Load the frame:
        im = readframe(f);
        
        % Need an imshow here
       
        %% Add trajectories of flies if required. 
        if add_tracks 
            set(gcf,"Units","centimeters","Position",[5,5,11,10], 'Resize', 'off')
        else
            set(gcf, 'Resize', 'off')
        end 

        if add_tracks

            tail_length = 3*fps; % 3s

            % PLOT TAIL
            rng = f-tail_length:1:f;
            n_flies = length(trx);
            cmap = hsv(n_flies);
            hold on

            for fly = 1:n_flies

                x = trx(fly).x;
                y = trx(fly).y;
                col = cmap(fly, :);

                if length(x) ~= length(y)
                    error('x and y must be the same length');
                end

                plot(x(rng), y(rng), '-', 'Color', col, 'LineWidth', 1); % Plot trajectory   
            end 
            hold off
            drawnow;
        end 

        % Apply a black mask to the outside of the video and resize. 
        N = size(im, 1);
        [Xi, Yi] = meshgrid(linspace(-1,1,N), linspace(-1,1,N));
        Ri = sqrt(Xi.^2 + Yi.^2);
        % Circle inscribed in the square: keep R<=1
        circle_mask = (Ri <= 1);
        % Set outside to black
        if ismatrix(im)
            im(~circle_mask) = 0;
        else
            % RGB: apply per channel
            im(repmat(~circle_mask, 1, 1, size(im,3))) = 0;
        end
        im = imresize(im, [1000, 1024]);
        
        %% Add the stimulus.

        A = repmat(pattern.Pats, 300, 1);
    
        bg_val = 0;
        [H, W, T] = size(A);
    
        [X, Y] = meshgrid(linspace(-1,1,output_size), linspace(-1.1,1.1,output_size));
        R = sqrt(X.^2 + Y.^2);
        Theta = atan2(Y, X); % -pi to pi
        % Arena radii (normalized)
        inner_r = 0.65; % hole in center
        outer_r = 0.95;
        % Normalize angle to [0, W)
        col_idx = mod(Theta + 2*pi, 2*pi) / (2*pi) * W + 1;
        col_idx(col_idx > W) = 1; % wrap exactly W back to 1
        % Normalize radius to [0, H)
        row_idx = (outer_r - R) / (outer_r - inner_r) * (H - 1) + 1;
        % Mask for valid arena pixels
        valid_mask = (R >= inner_r) & (R <= outer_r);
        frame = double(A(:,:,t));
        % Interpolate pattern onto circular map
        warped = interp2(1:W, (1:H)', frame, col_idx, row_idx, 'nearest', NaN);
        % Fill background with light grey
        warped(~valid_mask) = bg_val;


        % IMAGE - BEHAV
        H = output_size; W = output_size;              % canvas size
        bg = uint8(0);                   % background level
        % 1) Make canvas and paste the 1024 image in the center (hard overwrite)
        canvas = repmat(bg, H, W);
        r0 = floor((H-1024)/2)+100;
        c0 = floor((W-1000)/2)+1;
        canvas(r0:r0+999, c0:c0+1023) = im;
    
    
        if ~isa(stim1750,'uint8')
            s = double(warped);
            s(~isfinite(s)) = 0;                    % NaN/Inf -> 0
            if min(s(:)) >= 0 && max(s(:)) <= 1+eps % treat as [0,1]
                stim_u8 = uint8(round(255*s));
            else                                    % treat as [0,255]
                stim_u8 = uint8(round(min(max(s,0),255)));
            end
        else
            stim_u8 = warped;
        end
        % 3) Ensure mask is logical
        mask = valid_mask ~= 0;
        % 4) Hard replace canvas pixels wherever mask==1 with stimulus pixels
        canvas(mask) = stim_u8(mask);
        frame_out = canvas;   % uint8, ready for VideoWriter



        %%
        frame = getframe(gcf);  % capture frame from axes
        writeVideo(movie_obj, frame);
    end
    
    close(movie_obj);

    fclose(fid);




  
   

end 