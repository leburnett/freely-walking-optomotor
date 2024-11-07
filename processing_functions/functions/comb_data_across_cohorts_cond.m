function DATA = comb_data_across_cohorts_cond(protocol_dir)
    
    % [optomotor_pattern, flicker_pattern, opto_speed, flick_speed, trial_len]
    cond_array =[9, 10, 64, 8, 2;
            9, 10, 127, 16, 15;
            9, 10, 64, 8, 15;
            9, 10, 127, 16, 2;
            6, 7, 64, 8, 2;
            6, 7, 127, 16, 15;
            6, 7, 64, 8, 15;
            6, 7, 127, 16, 2;
            4, 5, 64, 8, 2;
            4, 5, 127, 16, 15;
            4, 5, 64, 8, 15;
            4, 5, 127, 16, 2;
            ];

    % Find all processed data for one protocol. 
    filelist = dir(fullfile(protocol_dir, '**/*.mat'));
    n_files = length(filelist);
    
    % Initialise a struct 'DATA' to store data in. 
    DATA = struct();
    
    for idx = 1:n_files
        
        fname = filelist(idx).name;
        f_folder = filelist(idx).folder; 
    
        % Load 'LOG', 'feat' and 'trx'
        load(fullfile(f_folder, fname));

        % Get key information about strain and sex:
        strain = LOG.meta.fly_strain;
        strain = check_strain_typos(strain);

        sex = LOG.meta.fly_sex;
    
        %% Extract all of the data from the entire experiment:
        comb_data = combine_data_one_cohort(feat, trx);
    
        if isfield(DATA, strain)
            if isfield(DATA.(strain), sex)
                sz = length(DATA.(strain).(sex))+1;
            else
                sz = 1;
            end 
        else
            sz = 1;
        end

        %% Start filling in the struct.
        DATA.(strain).(sex)(sz).meta = LOG.meta;
    
        %% Add data from acclim_off1
        Log = LOG.acclim_off1;
        start_f = Log.start_f(1);
        if start_f ==0 
            start_f = 1;
        end 
        stop_f = Log.stop_f(end);
        DATA.(strain).(sex)(sz).acclim_off1.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    
        %% Add data from acclim_patt
        Log = LOG.acclim_patt;
        start_f = Log.start_f(1);
        stop_f = Log.stop_f(end);
        DATA.(strain).(sex)(sz).acclim_patt.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    
        %% Then run through the next 16 logs. 
        for log_n = 1:16
    
            Log = LOG.(strcat('log_', string(log_n)));
    
            if log_n <9
                rep_str = 'R1_condition_';
            else
                rep_str = 'R2_condition_';
            end 

            % check if 'which_condition' is a field. 
            which_exists = isfield(Log, 'which_condition');
            if which_exists
                condition_n = Log.which_condition;
            else
                % Find the condition number before 'which_condition' has
                % been used as a parameter.
                optomotor_pattern = Log.optomotor_pattern;
                flicker_pattern = Log.flicker_pattern;
                opto_speed = Log.optomotor_speed;
                flick_speed = Log.flicker_speed;
                trial_len = Log.trial_len;
                params = [optomotor_pattern, flicker_pattern, opto_speed, flick_speed, trial_len];
                condition_n = find(ismember(cond_array, params, 'rows'));
            end 
    
            start_f = Log.start_f(1);
            stop_f = Log.stop_f(end);
    
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).trial_len = Log.trial_len;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).n_trials = Log.num_trials;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).optomotor_pattern = Log.optomotor_pattern;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).optomotor_speed = Log.optomotor_speed;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).flicker_pattern = Log.flicker_pattern;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).flicker_speed = Log.flicker_speed;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).start_flicker_f = Log.start_f(end-1);
    
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).vel_data = comb_data.vel_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).dist_data = comb_data.dist_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).dist_trav = comb_data.dist_trav(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).av_data = comb_data.av_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).heading_data = comb_data.heading_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    
        end 
    
        %% Add data from acclim_off2
        Log = LOG.acclim_off2;
        start_f = Log.start_f(1);
        stop_f = Log.stop_f(end);
        DATA.(strain).(sex)(sz).acclim_off2.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off2.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off2.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off2.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off2.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off2.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);

    
    end 

end 
