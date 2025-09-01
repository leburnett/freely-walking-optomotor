function create_stim_video_loop(log, trx, video_filename, rep)
    
    % JAABA function determines the readframe function to use:
    [readframe,~,fid,~] = get_readframe_fcn(video_filename);
    
    % lowercase log is LOG.log_X. 
    optomotor_pattern = log.optomotor_pattern;
    interval_pattern = 47; %log.interval_pattern;
    optomotor_speed = log.optomotor_speed;
    % interval_speed = log.interval_speed;
    condition_n = log.which_condition;

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
    n_sections = numel(log.start_f); % normally 3 [cw, ccw, int] excpet for static and bar. 

    for section = 1:n_sections+1

        % section 1 = before stimulus - interval pattern
        % section 2 = clock  - optomotor pattern 
        % section 3 = counter clock - optomotor pattern 
        % section 4 = interval 

        % Select the pattern for this section of the trial.
        if ismember(section , [1,n_sections+1])
            curr_pattern = int_pattern;
        else
            curr_pattern = opto_pattern;
        end

        % Find the range of video frames to show for each section.
        switch section 
            case 1
                curr_rng = frame_rng(1) : log.start_f(1);
            case 2
                curr_rng = log.start_f(1)+1:log.stop_f(1);
                stim_dir = 1;
            case 3
                curr_rng = log.start_f(2)+1:log.stop_f(2);
                stim_dir = -1;
            case 4
                curr_rng = log.stop_f(2):frame_rng(end);
        end 

        % Generate video with every other frame to save space:
        curr_rng = curr_rng(1):2:curr_rng(end);

        for f = curr_rng

            max_stim_frames = curr_pattern.x_num;

            if f == curr_rng(1) && section ~=3
                t = 1; % start on the first frame.
            end 

            % Read in the stimulus frame:
            stim_frame = double(curr_pattern.Pats(:,:,t)); % stim_frame
    
            % Load the the behavioural video frame:
            im = readframe(f);
            canvas = combine_stimulus_and_frame(stim_frame, im, f, trx);

            imshow(canvas);
            % set(gcf,"Units","centimeters","Position",[5,5,11,10],'Resize','off');
            curr_frame = getframe(gcf);  % capture frame from axes

            writeVideo(movie_obj, curr_frame);

            % If it's not an interval or static section...
            if ~ismember(section , [1, n_sections+1]) && optomotor_speed>1

                % ... then move the stimulus. 
                sp_int = 8; % Move every 10th frame.

                if ismember(f, curr_rng(sp_int):sp_int:curr_rng(end)) 

                    if stim_dir > 0 % clockwise
                        t = t+1;
                    else
                        t = t-1;
                    end 
        
                    % reset when going ccw
                    if t < 1
                        t = max_stim_frames;
                    end
        
                    % reset when cw
                    if t > max_stim_frames
                        t = 1;
                    end 

                end 
            end 

        end 
    end 

    close(movie_obj);

    fclose(fid);
   

end 