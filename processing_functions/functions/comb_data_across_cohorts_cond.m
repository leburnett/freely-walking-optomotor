function comb_data_across_cohorts_cond(protocol_dir)
    
    % Find all processed data for one protocol. 
    filelist = dir(fullfile(protocol_dir, '**/*.mat'));
    n_files = length(filelist);
    
    % Initialise a struct 'DATA' to store data in. 
    DATA = struct();
    sz = size(DATA, 1);
    
    for idx = 1:n_files
        
        fname = filelist(idx).name;
        f_folder = filelist(idx).folder; 
    
        % Load 'LOG', 'feat' and 'trx'
        load(fullfile(f_folder, fname));

        % Get key information about strain and sex:
        strain = LOG.meta.fly_strain;
        sex = LOG.meta.fly_sex;
    
        %% Extract all of the data from the entire experiment:
        comb_data = combine_data_one_cohort(feat, trx);
    
        %% Start filling in the struct.
        DATA(sz).(strain).(sex).meta = LOG.meta;
    
        %% Add data from acclim_off1
        Log = LOG.acclim_off1;
        start_f = Log.start_f(1);
        stop_f = Log.stop_f(end);
        DATA(sz).(strain).(sex).acclim_off1.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_off1.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_off1.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_off1.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_off1.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_off1.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    
        %% Add data from acclim_patt
        Log = LOG.acclim_patt;
        start_f = Log.start_f(1);
        stop_f = Log.stop_f(end);
        DATA(sz).(strain).(sex).acclim_patt.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_patt.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_patt.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_patt.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_patt.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_patt.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    
        %% Then run through the next 16 logs. 
        for log_n = 1:16
    
            Log = LOG.(strcat('log_', string(log_n)));
    
            % check is 
            condition_n = Log.which_condition;
    
            start_f = Log.start_f(1);
            stop_f = Log.stop_f(end);
    
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).trial_len = Log.trial_len;
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).n_trials = Log.num_trials;
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).optomotor_pattern = Log.optomotor_pattern;
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).optomotor_speed = Log.optomotor_speed;
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).flicker_pattern = Log.flicker_pattern;
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).flicker_speed = Log.flicker_speed;
    
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).vel_data = comb_data.vel_data(:, start_f:stop_f);
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).dist_data = comb_data.dist_data(:, start_f:stop_f);
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).dist_trav = comb_data.dist_trav(:, start_f:stop_f);
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).av_data = comb_data.av_data(:, start_f:stop_f);
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).heading_data = comb_data.heading_data(:, start_f:stop_f);
            DATA(sz).(strain).(sex).(strcat('condition_', string(condition_n))).heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    
        end 
    
        %% Add data from acclim_off2
        Log = LOG.acclim_off2;
        start_f = Log.start_f(1);
        stop_f = Log.stop_f(end);
        DATA(sz).(strain).(sex).acclim_off2.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_off2.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_off2.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_off2.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_off2.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA(sz).(strain).(sex).acclim_off2.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    
        % To add data from next file into a new row.
        sz = sz+1;
    
    end 

end 
