function review_behavioural_data(which_videos)

% "/Volumes/reiserlab/oaky-cokey/data/2_processed/2025_03_17/protocol_27/jfrc100_es_shibire_kir"

% Script to help streamline the process of reviewing the behavioural videos
% and saving observations in an ordered and efficient way.
% Run within experiment folder that contains the pre-made '.mp4' files. 
% Sends observations to google form -> google sheet.

    % 0 - Find all of the MP4 files within the folder:
    mp4_files = dir('*.mp4');
    n_videos = length(mp4_files);
    
    curr_folder = cd;
    folder_strs = split(curr_folder, '/');
    strain = folder_strs{9};
    disp(strain)
    
    if which_videos == "all_videos"
        rangee = 1:n_videos;
    elseif which_videos == "gratings"
        rangee = [7,8,9,10];
    elseif which_videos == "flicker"
        rangee = [23, 24];
    elseif which_videos == "offset"
        rangee = [3,4];
    elseif which_videos == "static"
        rangee = [1, 2];
    elseif which_videos == "phototaxis"
        rangee = [5,6];
    elseif which_videos == "reversephi"
        rangee = [19, 20, 21, 22];
    end 

    for m = rangee
        
        % 1 - open the video
        fname = mp4_files(m).name;
        mp4_name = fullfile(mp4_files(m).folder, fname);
        
        % This will open the video outside of MATLAB:
        commandString = strcat("!open ", mp4_name);
        eval(commandString);
        
        % 2 - extract info about the experiment from the file name / folder.
        metadata.date = fname(1:10);
        metadata.time = fname(17:24);
        metadata.strain = strain;
    
        condition_strs = split(fname(26:end-9), '_');
        cond_str = condition_strs{1};
        condition_n = cond_str(10:end);
        metadata.condition_n = condition_n;
        metadata.condition_str = condition_strs{2};
        rep_str = fname(end-4);
        metadata.rep = rep_str;
        
        % 3 - open pop up GUI with metrics that the user can fill in. Include text
        % box too?
        disp("Centring goes from 0 (none) to 10 (very close to the centre)")
        observations = get_video_observations();
        
        prompt = "Additional observations: ";
        notes = input(prompt, 's');
        
        % 4 - The results from this pop up are returned to a google form. 
    
        % Google Form Response URL (Make sure it ends with /formResponse)
        googleFormURL = 'https://docs.google.com/forms/d/e/1FAIpQLScgK2F-PiaHaW9AiqUjHNZ9D1WYpF1-W19sEwlob2orr2wyfg/formResponse';
        
        % Use weboptions to set character encoding
        options = weboptions('MediaType', 'application/x-www-form-urlencoded', 'Timeout', 30);
        
        % Submit data using name-value pairs instead of struct
        webwrite(googleFormURL, ...
            'entry.104586054', metadata.date, ...
            'entry.1144953751', metadata.time, ...
            'entry.1017789798', metadata.strain, ...
            'entry.462337747', metadata.condition_n, ...
            'entry.635492352', metadata.condition_str, ...
            'entry.1832623891', metadata.rep, ...
            'entry.932164432', observations.centring, ...
            'entry.324082057', observations.turning, ...
            'entry.1509506971', observations.rebound, ...
            'entry.350553119', observations.distribution, ...
            'entry.1178542927', observations.locomotion, ...
            'entry.1494282419', observations.diversity, ...
            'entry.183573490', notes, ...
            options); % Include options for correct encoding
    
        disp(strcat("Data successfully exported to Google Sheets for ", strain, ": condition ", condition_n, ", rep ", rep_str));
        
    end 
    
end
