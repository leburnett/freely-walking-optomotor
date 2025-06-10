function generate_movie_from_ufmf(add_tracks)
%% Generate movie from ufmf file. 
% Works within the folder that it is called. 

% Requires JAABA code from kristenBranson. 
% 'get_readframe_fcn' is from this repo. 

% WITHOUT TRACKS. 

% Get video file name.  
video_files = dir('*.ufmf');
if isempty(video_files)
    disp('No .ufmf video files found in this folder.')
else
    filename = video_files(1).name;
end 

% Load the LOG file. 
log_files = dir('LOG*');
if isempty(log_files)
    disp('No LOG files found in this folder.')
else
    load(log_files(1).name, 'LOG');
end 

trx_files = dir('**/trx.mat');
if isempty(trx_files)
    disp('No trx file found in this folder.')
else
    load(fullfile(trx_files(1).folder, trx_files(1).name), 'trx');
end

pr = LOG.meta.func_name;
if contains(pr, "10")
    cond_idxs = [2, 3];
elseif contains(pr, "19")
    cond_idxs = [2, 7]; %[1,2];
elseif contains(pr, "27")
    cond_idxs = 1:12;
    cond_titles = {"60deg-gratings-4Hz"...
    , "60deg-gratings-8Hz"...
    , "narrow-ON-bars-4Hz"...
    , "narrow-OFF-bars-4Hz"...
    , "ON-curtains-8Hz"...
    , "OFF-curtains-8Hz"...
    , "reverse-phi-2Hz"...
    , "reverse-phi-4Hz"...
    , "60deg-flicker-4Hz"...
    , "60deg-gratings-static"...
    , "60deg-gratings-0-8-offset"...
    , "32px-ON-single-bar"...
    };
elseif contains(pr, "31")
    cond_idxs = [1,2,3,4,6,7,8,9]; 
else 
    cond_idxs = []; % Don't make any videos.
end 

[readframe,~,fid,~] = get_readframe_fcn(filename);
    
%% Find within 'LOG' when condition 1 was:
% Run through the fields starting with 'log_' and check which has the field
% 'which_condition' == 1. 

for condition_n = cond_idxs

    disp(strcat("Video for condition ", string(condition_n)))
    fields = fieldnames(LOG);
    log_fields = fields(startsWith(fields, 'log_'));
    
    results = [];  % Initialize an empty array to store results
    
    for i = 1:length(log_fields)
        log_field = log_fields{i};
        entry = LOG.(log_field);
    
        if isfield(entry, 'which_condition') && entry.which_condition == condition_n
            if isfield(entry, 'start_f') && isfield(entry, 'stop_f')
                % Store results in a struct array
                results(end+1).field = log_field;
                results(end).start_f = entry.start_f;
                results(end).stop_f = entry.stop_f;
            else
                warning(['Missing start_f or stop_f in ', log_field]);
            end
        % else
        %     if i == 1
        %         disp(strcat("Condition ", string(condition_n), " not found in the LOG. No videos will be made."))
        %     end 
        end
    end
    
    for rep = 1:length(results) % There are normally 2 repetitions of each condition. 
    
        if condition_n == 12  % bar fixation 
            start_f = results(rep).start_f(1)-300;
            stop_f = results(rep).start_f(2)+300;

            % For stimulus presentation. 
            start_stim = results(rep).start_f(1);
            start_grey = results(rep).start_f(2);
        else
            start_f = results(rep).start_f(1)-300;
            stop_f = results(rep).start_f(3)+300;

            % For stimulus presentation. 
            start_gratings = results(rep).start_f(1);
            swap_dir = results(rep).start_f(2);
            start_grey = results(rep).start_f(3);
        end
        
        fr_int = 2;
        frame_rng = start_f:fr_int:stop_f;
        
        %% Open emty avi file. 
        if contains(pr, "27") 
            movie_name = strcat(filename(17:end-10), '_condition', string(condition_n),'_', cond_titles{condition_n}, '_rep', string(rep), '.mp4');
        else
            movie_name = strcat(filename(1:end-5), '_condition', string(condition_n), '_rep', string(rep), '.mp4');
        end 
        fps = 30;
        
        movie_obj = VideoWriter(movie_name, 'MPEG-4');
        set(movie_obj,'FrameRate',fps);
        set(movie_obj,'Quality', 100);
        open(movie_obj);
        
        %% Position of the stimulus video:
        x1 = 12; x2 = 200;
        y1 = 12; y2 = 118;
        
        % For the stimulus inset
        bar_width = 20;  % width of each black or white bar in pixels
        gray_value = 128;
        black = 0;
        white = 255;
        
        % Compute rectangle width
        rect_width = x2 - x1 + 1;
        rect_height = y2 - y1 + 1;
        
        % Create a horizontal grating pattern wider than the rectangle
        pattern_width = 5 * rect_width;  % to allow for shifts
        num_bars = ceil(pattern_width / bar_width);
        bar_pattern = repmat([black*ones(1,bar_width), white*ones(1,bar_width)], 1, ceil(num_bars/2));
        bar_pattern = bar_pattern(1:pattern_width);  % crop to exact size
        grating_pattern = repmat(bar_pattern, rect_height, 1);  % replicate for full height

        x1b = 106-24; x2b = 106+24;
        
        %% Generate the movie:
        
        phase = 0; 
        
        for f = frame_rng
            
            im = readframe(f);
        
            if condition_n ==12 % bar fixation

                % Static grey rectangle
                im(y1:y2, x1:x2) = gray_value;
                if f > start_stim && f < start_grey
                    im(y1:y2, x1b:x2b) = white;
                end 

            else

                if f < start_gratings || f >= start_grey
                    % Static grey rectangle
                    im(y1:y2, x1:x2) = gray_value;
            
                else
                    if contains(pr, "27")
                        if ~ismember(condition_n, [9, 10]) % %For flicker and static don't move the gratings.
    
                            % Determine direction
                            if f < swap_dir
                                phase = phase + 3;  % move right
                            else
                                phase = phase - 3;  % move left
                            end
                        end 
                    end 
            
                    % Wrap phase to stay within bounds
                    phase_mod = mod(phase, pattern_width - rect_width + 1);
            
                    % Extract shifting section of the grating
                    grating_crop = grating_pattern(:, phase_mod + (1:rect_width));
            
                    % Insert into image
                    im(y1:y2, x1:x2) = grating_crop;
                end

            end 
      
            im2 = cat(3, im, im, im);
            imshow(im2);
            % set(gcf,"Units","centimeters","Position",[5,5,11,10], 'Resize', 'off')
            set(gcf,'Resize', 'off')

            if add_tracks

                cmap = hsv(15);
                tail_length = 90;

                % PLOT TAIL
                rng = f-tail_length:1:f;
                n_flies = length(trx);
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
            
            frame = getframe(gcf);  % capture frame from axes
            writeVideo(movie_obj, frame);
        end
        
        close(movie_obj);
    end 
end 
fclose(fid);

end 