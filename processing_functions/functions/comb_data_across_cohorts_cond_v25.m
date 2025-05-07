function DATA = comb_data_across_cohorts_cond_v25(protocol_dir)
    % Example 'protocol_dir' would be:
    % '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_10'

    % Used for "single lady" experiments. 

    % [optomotor_pattern, flicker_pattern, opto_speed, flick_speed, trial_len]

    strs = split(protocol_dir, '/');
    protocol = strs{end};

    % Find all processed data for one protocol. 
    filelist = dir(fullfile(protocol_dir, '**/*.mat'));
    % Remove the DATA file if it already exits:
    idxToRemove = contains({filelist.name}, "DATA");
    filelist(idxToRemove) = [];

    str_spl = split(protocol_dir, '/');
    protocol_name = str_spl{end};

    n_files = length(filelist);
    
    % Initialise a struct 'DATA' to store data in. 
    DATA = struct();
    
    for idx = 1:n_files
        
        fname = filelist(idx).name;
        disp(fname)
        f_folder = filelist(idx).folder; 
    
        % Load 'combined_data', 'LOG', 'feat' and 'trx'
        load(fullfile(f_folder, fname));
        cond_array = LOG.meta.cond_array;

        % Get key information about strain and sex:
        strain = LOG.meta.fly_strain;
        strain = check_strain_typos(strain);
        strain = strrep(strain, '-', '_');

        sex = LOG.meta.fly_sex;
    
        %% Extract all of the data from the entire experiment:
        % [comb_data, feat, trx] = combine_data_one_cohort(feat, trx);
    
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
        DATA.(strain).(sex)(sz).meta.n_flies = length(trx);
    
        %% Add data from acclim_off1
        Log = LOG.acclim_off1;
        start_f = Log.start_f(1);
        if start_f ==0 
            start_f = 1;
        end 

        if Log.stop_t(end)<3
            stop_f = 600; %
        else
            stop_f = Log.stop_f(end);
        end

        DATA.(strain).(sex)(sz).acclim_off1.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.fv_data = comb_data.fv_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.curv_data = comb_data.curv_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.x_data = comb_data.x_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.y_data = comb_data.y_data(:, start_f:stop_f);
    
        %% Add data from acclim_patt
        Log = LOG.acclim_patt;
        start_f = Log.start_f(1);
        stop_f = Log.stop_f(end);
        DATA.(strain).(sex)(sz).acclim_patt.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.fv_data = comb_data.fv_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.curv_data = comb_data.curv_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.x_data = comb_data.x_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.y_data = comb_data.y_data(:, start_f:stop_f);

        % Find out how many unique conditions there are:
        fields = fieldnames(LOG);
        logfields = fields(startsWith(fields, 'log_'));
        n_cond = height(logfields);

        %% Then run through the next 16 logs. 
        for log_n = 1:n_cond
    
            Log = LOG.(logfields{log_n});

            if log_n <(n_cond/2)+1
                rep_str = 'R1_condition_';
            else
                rep_str = 'R2_condition_';
            end 

            condition_n = Log.which_condition;

            if LOG.acclim_off1.stop_t(end)<3 && log_n == 1
                framesb4 = 0;
            else
                framesb4 = 300;
            end

            start_f = Log.start_f(1)-framesb4;
            stop_f = Log.stop_f(end);

            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).trial_len = Log.trial_len;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).interval_dur = Log.interval_dur;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).optomotor_pattern = Log.optomotor_pattern;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).optomotor_speed = Log.optomotor_speed;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).interval_pattern = Log.interval_pattern;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).interval_speed = Log.interval_speed;
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).start_flicker_f = Log.start_f(end)-start_f;

            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).vel_data = comb_data.vel_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).fv_data = comb_data.fv_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).dist_data = comb_data.dist_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).dist_trav = comb_data.dist_trav(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).av_data = comb_data.av_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).curv_data = comb_data.curv_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).heading_data = comb_data.heading_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).x_data = comb_data.x_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).y_data = comb_data.y_data(:, start_f:stop_f);

        end 
    
        %% Add data from acclim_off2
        Log = LOG.acclim_off2;
        start_f = Log.start_f(1);
        stop_f = Log.stop_f(end);
        DATA.(strain).(sex)(sz).acclim_off2.vel_data = comb_data.vel_data(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.fv_data = comb_data.fv_data(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.dist_data = comb_data.dist_data(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.dist_trav = comb_data.dist_trav(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.av_data = comb_data.av_data(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.curv_data = comb_data.curv_data(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.heading_data = comb_data.heading_data(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.heading_wrap = comb_data.heading_wrap(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.x_data = comb_data.x_data(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.y_data = comb_data.y_data(:, start_f:end);
    
    end 

    % todaysdate =  string(datetime('now', 'Format','yyyy-MM-dd'));
    % save(string(fullfile(protocol_dir, strcat(protocol, '_DATA_', todaysdate, '.mat'))), 'DATA');

end 
