function datapoints = make_mean_vel_datapoints(Log, feat, n_flies, n_conditions, fps)

 
    % % % % % % % % % % %

    contrast_vals = Log.contrast; 
    
    datapoints = zeros(n_conditions, n_flies+1);
    datapoints(1:n_conditions, 1) = contrast_vals;

   
    for idx = 1:n_flies
        
        for ii = 1:n_conditions
            st_fr = Log.start_f(ii);
            stop_fr = Log.stop_f(ii)-1;
            if st_fr == 0 
                st_fr = 1;
            end 
            raw_data = feat.data(idx,:,1);
            data = raw_data(st_fr:stop_fr);
            datapoints(ii, idx+1) = mean(data);
        end 
    end 

    % Add direction to 'datapoints'
    datapoints(1:n_conditions, n_flies+2) = Log.dir;

end 










