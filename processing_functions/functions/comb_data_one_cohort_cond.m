function DATA = comb_data_one_cohort_cond(LOG, comb_data, protocol)

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


    % Initialise a struct 'DATA' to store data in. 
    DATA = struct();
    
    % Get key information about strain and sex:
    strain = LOG.meta.fly_strain;
    strain = check_strain_typos(strain);

    % Check for landing site field in LOG. 
    % If there is no field - i.e. before added - use 'attP2' if Kir, 
    % 'attP5' if shibire and 'none' is other. 
    % if isfield(LOG.meta, 'landing_site')
    %     landing = LOG.meta.landing_site;
    %     if contains(landing, 'su')
    %         landing = landing(end-4:end);
    %     end 
    %     if contains(strain, 'shibire') && contains(landing, 'attP2') % correct for wrong landing with Shibire
    %         landing = 'attP5';
    %     end 
    % else
    %     if contains(strain, 'kir')
    %         landing = "attP2";
    %     elseif contains(strain, 'shibire')
    %         landing = "attP5";
    %     else
            landing = "none";
    %     end 
    % end 

    sex = LOG.meta.fly_sex;

    %% Extract all of the data from the entire experiment:
    
    if isfield(DATA, strain)
        if isfield(DATA.(strain), landing)
            if isfield(DATA.(strain).(landing), sex)
                sz = length(DATA.(strain).(landing).(sex))+1;
            else
                sz = 1;
            end 
        else
            sz = 1;
        end 
    else 
        sz = 1; 
    end 

    %% Start filling in the struct.
    DATA.(strain).(landing).(sex)(sz).meta = LOG.meta;

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

    DATA.(strain).(landing).(sex)(sz).acclim_off1.vel_data = comb_data.vel_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_off1.fv_data = comb_data.fv_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_off1.dist_data = comb_data.dist_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_off1.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_off1.av_data = comb_data.av_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_off1.curv_data = comb_data.curv_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_off1.heading_data = comb_data.heading_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_off1.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_off1.x_data = comb_data.x_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_off1.y_data = comb_data.y_data(:, start_f:stop_f);

    %% Add data from acclim_patt
    Log = LOG.acclim_patt;
    start_f = Log.start_f(1);
    stop_f = Log.stop_f(end);
    DATA.(strain).(landing).(sex)(sz).acclim_patt.vel_data = comb_data.vel_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_patt.fv_data = comb_data.fv_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_patt.dist_data = comb_data.dist_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_patt.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_patt.av_data = comb_data.av_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_patt.curv_data = comb_data.curv_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_patt.heading_data = comb_data.heading_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_patt.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_patt.x_data = comb_data.x_data(:, start_f:stop_f);
    DATA.(strain).(landing).(sex)(sz).acclim_patt.y_data = comb_data.y_data(:, start_f:stop_f);

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

        if LOG.acclim_off1.stop_t(end)<3 && log_n == 1
            framesb4 = 0;
        else
            framesb4 = 300;
        end
        % framesb4 = 300; % include 10s before the start of the trial in the data

        start_f = Log.start_f(1)-framesb4;
        stop_f = Log.stop_f(end);

        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).trial_len = Log.trial_len;
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).n_trials = Log.num_trials;
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).optomotor_pattern = Log.optomotor_pattern;
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).optomotor_speed = Log.optomotor_speed;
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).flicker_pattern = Log.flicker_pattern;
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).flicker_speed = Log.flicker_speed;
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).start_flicker_f = Log.start_f(end)-start_f;

        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).fv_data = comb_data.fv_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).av_data = comb_data.av_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).curv_data = comb_data.curv_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).x_data = comb_data.x_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).(strcat(rep_str, string(condition_n))).y_data = comb_data.y_data(:, start_f:stop_f);

    end 

    %% Add data from acclim_off2
    Log = LOG.acclim_off2;
    start_f = Log.start_f(1);
    stop_f = Log.stop_f(end);
    DATA.(strain).(landing).(sex)(sz).acclim_off2.vel_data = comb_data.vel_data(:, start_f:end);
    DATA.(strain).(landing).(sex)(sz).acclim_off2.fv_data = comb_data.fv_data(:, start_f:end);
    DATA.(strain).(landing).(sex)(sz).acclim_off2.dist_data = comb_data.dist_data(:, start_f:end);
    DATA.(strain).(landing).(sex)(sz).acclim_off2.dist_trav = comb_data.dist_trav(:, start_f:end);
    DATA.(strain).(landing).(sex)(sz).acclim_off2.av_data = comb_data.av_data(:, start_f:end);
    DATA.(strain).(landing).(sex)(sz).acclim_off2.curv_data = comb_data.curv_data(:, start_f:end);
    DATA.(strain).(landing).(sex)(sz).acclim_off2.heading_data = comb_data.heading_data(:, start_f:end);
    DATA.(strain).(landing).(sex)(sz).acclim_off2.heading_wrap = comb_data.heading_wrap(:, start_f:end);
    DATA.(strain).(landing).(sex)(sz).acclim_off2.x_data = comb_data.x_data(:, start_f:end);
    DATA.(strain).(landing).(sex)(sz).acclim_off2.y_data = comb_data.y_data(:, start_f:end);

end 