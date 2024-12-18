function DATA = comb_data_across_cohorts_cond_v14(protocol_dir)

    % Example 'protocol_dir' would be:
    % '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_14'

    % Find all processed data for one protocol. 
    filelist = dir(fullfile(protocol_dir, '**/*.mat'));

    str_spl = split(protocol_dir, '/');
    protocol_name = str_spl{end};

    % Remove the DATA file. 
    dnames = {filelist.name};
    filelist = filelist(~ismember(dnames, strcat(protocol_name, '_DATA*')));

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

        % Check for landing site field in LOG. 
        % If there is no field - i.e. before added - use 'attP2' if Kir, 
        % 'attP5' if shibire and 'none' is other. 
        if isfield(LOG.meta, 'landing_site')
            landing = LOG.meta.landing_site;
            if contains(landing, 'su')
                landing = landing(end-4:end);
            end 
            if contains(strain, 'shibire') && contains(landing, 'attP2') % correct for wrong landing with Shibire
                landing = 'attP5';
            end 
        else
            if contains(strain, 'kir')
                landing = "attP2";
            elseif contains(strain, 'shibire')
                landing = "attP5";
            else
                landing = "none";
            end 
        end 

        sex = LOG.meta.fly_sex;
    
        %% Extract all of the data from the entire experiment:
        comb_data = combine_data_one_cohort(feat, trx);
    
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
        Log = LOG.Log;
        start_f = Log.start_f(1);
        if start_f ==0 
            start_f = 1;
        end 
        stop_f = Log.stop_f(1);
        DATA.(strain).(landing).(sex)(sz).acclim_off1.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_off1.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_off1.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_off1.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_off1.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_off1.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    
        %% Add data from acclim_patt

        start_f = Log.start_f(2);
        stop_f = Log.stop_f(2);
        DATA.(strain).(landing).(sex)(sz).acclim_patt.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_patt.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_patt.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_patt.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_patt.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_patt.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    
        %% Then run through the next logs: 

        for log_n = 1:4

            for rep = 1:2

                if rep == 1
                    if log_n == 1
                        st_row = 3; end_row = 5;
                    elseif log_n == 2
                        st_row = 6; end_row = 8;
                    elseif log_n == 3
                        st_row = 9; end_row = 11;
                    elseif log_n == 4 
                        st_row = 12; end_row = 14;
                    end 
                elseif rep == 2
                    if log_n == 1
                        st_row = 15; end_row = 17;
                    elseif log_n == 2
                        st_row = 18; end_row = 20;
                    elseif log_n == 3
                        st_row = 21; end_row = 23;
                    elseif log_n == 4 
                        st_row = 24; end_row = 26;
                    end 
                end 

                str_cond = strcat('rep', string(rep), '_cond', string(log_n));

                start_f = Log.start_f(st_row);
                stop_f = Log.stop_f(end_row);
        
                DATA.(strain).(landing).(sex)(sz).(str_cond).trial_len = LOG.trial_len;
                DATA.(strain).(landing).(sex)(sz).(str_cond).optomotor_pattern = LOG.optomotor_pattern;
                DATA.(strain).(landing).(sex)(sz).(str_cond).optomotor_speed = LOG.optomotor_speed;
                DATA.(strain).(landing).(sex)(sz).(str_cond).flicker_pattern = LOG.flicker_pattern;
                DATA.(strain).(landing).(sex)(sz).(str_cond).flicker_speed = LOG.flicker_speed;
                DATA.(strain).(landing).(sex)(sz).(str_cond).contrast = Log.contrast(end_row);
                DATA.(strain).(landing).(sex)(sz).(str_cond).dir = Log.dir(end_row);
        
                DATA.(strain).(landing).(sex)(sz).(str_cond).vel_data = comb_data.vel_data(:, start_f:stop_f);
                DATA.(strain).(landing).(sex)(sz).(str_cond).dist_data = comb_data.dist_data(:, start_f:stop_f);
                DATA.(strain).(landing).(sex)(sz).(str_cond).dist_trav = comb_data.dist_trav(:, start_f:stop_f);
                DATA.(strain).(landing).(sex)(sz).(str_cond).av_data = comb_data.av_data(:, start_f:stop_f);
                DATA.(strain).(landing).(sex)(sz).(str_cond).heading_data = comb_data.heading_data(:, start_f:stop_f);
                DATA.(strain).(landing).(sex)(sz).(str_cond).heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
            end 
    
        end 
    
        %% Add data from acclim_off2
        start_f = Log.start_f(27);
        stop_f = Log.stop_f(27);
        DATA.(strain).(landing).(sex)(sz).acclim_off2.vel_data = comb_data.vel_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_off2.dist_data = comb_data.dist_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_off2.dist_trav = comb_data.dist_trav(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_off2.av_data = comb_data.av_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_off2.heading_data = comb_data.heading_data(:, start_f:stop_f);
        DATA.(strain).(landing).(sex)(sz).acclim_off2.heading_wrap = comb_data.heading_wrap(:, start_f:stop_f);
    
    end 

    strs = split(protocol_dir, '/');
    todaysdate =  string(datetime('now', 'Format','yyyy-MM-dd'));
    save(string(fullfile(protocol_dir, strcat(strs(end), '_DATA_', todaysdate, '.mat'))), 'DATA');

end 
