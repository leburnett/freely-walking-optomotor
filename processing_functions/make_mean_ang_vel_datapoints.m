function datapoints = make_mean_ang_vel_datapoints(Log, trx, n_flies, n_conditions, fps)

    % Fixed paramters: 
    samp_rate = 1/fps; 
    method = 'line_fit';
    t_window = 16;
    cutoff = []; 

    % % % % % % % % % % %

    contrast_vals = Log.contrast; 

    datapoints = zeros(n_conditions, n_flies+1);
    datapoints(1:n_conditions, 1) = contrast_vals;

    for idx = 1:n_flies
        % unwrap the heading data
        D = unwrap(trx(idx).theta);
        % convert heading to angular velocity
        V = vel_estimate(D, samp_rate, method, t_window, cutoff);
        
        for ii = 1:n_conditions
       
            st_fr = Log.start_f(ii);
            stop_fr = Log.stop_f(ii)-1;

            if st_fr == 0 
                st_fr = 1;
            end 
            data = V(st_fr:stop_fr);
            datapoints(ii, idx+1) = mean(data);
        end 
    end 

    % Add direction to 'datapoints'
    datapoints(1:n_conditions, n_flies+2) = Log.dir;

end 










