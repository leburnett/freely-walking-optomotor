function DATA = comb_data_across_cohorts_cond(protocol_dir)
    % Example 'protocol_dir' would be:
    % '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_10'

    % NOTE: a separate function exists for processing protocol 14. This
    % function works for all protocols that have been generated in the
    % style of protocol 10 with a random condition structure.
    
    % [optomotor_pattern, flicker_pattern, opto_speed, flick_speed, trial_len]

    strs = split(protocol_dir, '/');
    protocol = strs{end};

    if protocol == "protocol_10"
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
    elseif protocol == "protocol_15"
        cond_array = [
            4, 5, 64, 8, 15; % standard 4ON 4OFF
            13, 14, 64, 8, 15; % 4ON 12OFF
            16, 14, 64, 8, 15; % 12 ON 4OFF
            ];
    elseif protocol == "protocol_18"
        cond_array = [
            9, 10, 127, 8, 15, 1; % Normal gratings
            9, 10, 64, 8, 15, 2;
            19, 10, 64, 8, 15, 3; % ON curtain
            19, 10, 127, 8, 15, 4;
            20, 10, 64, 8, 15, 5; % OFF curtain
            20, 10, 127, 8, 15, 6;
        ];
    % elseif protocol == "protocol_19" % BEFORE JAN 2025
    %     cond_array =  [
    %         9, 10, 127, 8, 15, 1; % normal stripes - wide
    %         9, 10, 64, 8, 15, 2;
    %         19, 10, 64, 8, 15, 3; % ON curtain
    %         19, 10, 127, 8, 15, 4;
    %         20, 10, 64, 8, 15, 5; % OFF curtain
    %         20, 10, 127, 8, 15, 6;
    %         17, 18, 64, 8, 15, 7; % 2ON 14OFF grating
    %         17, 18, 127, 8, 15, 8;
    %     ];
    elseif protocol == "protocol_19" % AFTER JAN 2025
        % cond_array =  [
        %     9, 10, 64, 8, 15, 1; % normal stripes - wide
        %     9, 10, 127, 8, 15, 2;
        %     19, 10, 64, 8, 15, 3; % ON curtain
        %     19, 10, 127, 8, 15, 4;
        %     20, 10, 64, 8, 15, 5; % OFF curtain
        %     20, 10, 127, 8, 15, 6;
        %     17, 10, 64, 8, 15, 7; % 2ON 14OFF grating
        %     17, 10, 127, 8, 15, 8;
        %     24, 10, 64, 8, 15, 9; % 2OFF 14ON grating
        %     24, 10, 127, 8, 15, 10;
        % ];
        cond_array = [  % From 27th Jan onwards - added thin gratings back in. 
            9, 10, 64, 8, 15, 1; % grating - 60 deg
            9, 10, 127, 8, 15, 2;
            19, 10, 64, 8, 15, 3; % ON curtain - - 5
            19, 10, 127, 8, 15, 4; % - - 6
            20, 10, 64, 8, 15, 5; % OFF curtain - - 7
            20, 10, 127, 8, 15, 6; % - - 8
            17, 10, 64, 8, 15, 7; % 2ON 14OFF grating - - 9
            17, 10, 127, 8, 15, 8; % - - 10
            24, 10, 64, 8, 15, 9; % 2OFF 14ON grating - - 11
            24, 10, 127, 8, 15, 10; %  - - 12
            4, 10, 64, 8, 15, 11; % grating - 15 deg - - 3
            4, 10, 127, 8, 15, 12; % - - 4
            ];
    elseif protocol == "protocol_21"
        cond_array = [ 
                27, 29, 64, 1, 15, 1; % grating - 60 deg
                27, 29, 127, 1, 15, 2;
                26, 29, 64, 1, 15, 3; % grating - 30 deg - - 3
                26, 29, 127, 1, 15, 4; % - - 4
                19, 29, 16, 1, 15, 5; % ON curtain - - 5
                19, 29, 32, 1, 15, 6; % - - 6
                20, 29, 16, 1, 15, 7; % OFF curtain - - 7
                20, 29, 32, 1, 15, 8; % - - 8
                10, 29, 4, 1, 15, 9; % Flicker as a stimulus - 60 deg - slow
                10, 29, 8, 1, 15, 10; % Flicker as a stimulus - 60 deg - fast
            ]; 
    elseif protocol == "protocol_22"
        cond_array = [ 
            30, 29, 1, 1, 15, 1; % 1 = bar fixation
            31, 29, 32, 1, 15, 2; % reverse phi - 1px step
            32, 29, 32, 1, 15, 3; % 4 px step
            33, 29, 32, 1, 15, 4; % 8 px step
            34, 29, 32, 1, 15, 5; % FoE - 30deg
            35, 29, 32, 1, 15, 6; % 15 deg
            36, 29, 32, 1, 15, 7; % 60 deg
        ]; 
    elseif protocol == "protocol_23"
        cond_array = [ 
            45, 9, 1, 127, 60, 7; % 1 = bar fixation
            46, 9, 1, 127, 60, 8; % 2 = bar fixation
        ]; 
    end 

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

        if protocol == "protocol_24" || protocol == "protocol_27"
            cond_array = LOG.meta.cond_array;
        end 

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
        DATA.(strain).(sex)(sz).acclim_off1.view_dist = comb_data.view_dist(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.IFD_data = comb_data.IFD_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_off1.IFA_data = comb_data.IFA_data(:, start_f:stop_f);
    
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
        DATA.(strain).(sex)(sz).acclim_patt.view_dist = comb_data.view_dist(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.IFD_data = comb_data.IFD_data(:, start_f:stop_f);
        DATA.(strain).(sex)(sz).acclim_patt.IFA_data = comb_data.IFA_data(:, start_f:stop_f);

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
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).view_dist = comb_data.view_dist(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).IFD_data = comb_data.IFD_data(:, start_f:stop_f);
            DATA.(strain).(sex)(sz).(strcat(rep_str, string(condition_n))).IFA_data = comb_data.IFA_data(:, start_f:stop_f);

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
        DATA.(strain).(sex)(sz).acclim_off2.view_dist = comb_data.view_dist(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.IFD_data = comb_data.IFD_data(:, start_f:end);
        DATA.(strain).(sex)(sz).acclim_off2.IFA_data = comb_data.IFA_data(:, start_f:end);
    
    end 

    % todaysdate =  string(datetime('now', 'Format','yyyy-MM-dd'));
    % save(string(fullfile(protocol_dir, strcat(protocol, '_DATA_', todaysdate, '.mat'))), 'DATA');

end 
