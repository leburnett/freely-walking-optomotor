function generate_exp_data_struct(DATA)
    
    exp_data = struct();
    
    strain_names = fieldnames(DATA);
    n_strains = numel(strain_names);
    
    for j = 1:n_strains
    
        strain = strain_names{j};
        data = DATA.(strain).F;
    
        n_exp = length(data); % Total number of vials / experiments ran. 
        exp_data.(strain).n_vials = n_exp; 
    
        n_arena = nan(1, n_exp);
        n_rm = nan(1, n_exp);
        n_flies = nan(1, n_exp);
        fly_age = nan(1, n_exp); %cell(1, n_exp);
        temp_start = nan(1, n_exp);
        temp_end = nan(1, n_exp);
        time_start = nan(1, n_exp);
    
        for exp = 1:n_exp
            n_a = data(exp).meta.n_flies_arena;
            n_arena(exp) = n_a;
    
            n_r = data(exp).meta.n_flies_rm;
            n_rm(exp) = n_r;
    
            n_f = data(exp).meta.n_flies;
            n_flies(exp) = n_f;
    
            ag = data(exp).meta.fly_age;
            ag = str2double(ag(1));
            fly_age(exp) = ag;
    
            t_s = data(exp).meta.start_temp_ring;
            temp_start(exp) = t_s;
    
            t_e = data(exp).meta.end_temp_ring;
            temp_end(exp) = t_e;
    
            timeee = hour(data(exp).meta.time);
            time_start(exp) = timeee;
        end 
    
        exp_data.(strain).n_arena = n_arena;
        exp_data.(strain).n_rm = n_rm;
        exp_data.(strain).n_flies = n_flies;
        exp_data.(strain).fly_age = fly_age;
        exp_data.(strain).temp_start = temp_start;
        exp_data.(strain).temp_end = temp_end;
        exp_data.(strain).time_start = time_start;
    end 
   
end 
