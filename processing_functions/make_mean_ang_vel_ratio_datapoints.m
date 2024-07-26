function datapoints = make_mean_ang_vel_ratio_datapoints(Log, trx, feat, n_flies, n_conditions, fps)


    % % % % % % % % % % %

    contrast_vals = Log.contrast; 

    datapoints = zeros(n_conditions, n_flies+1);
    datapoints(1:n_conditions, 1) = contrast_vals;

    for idx = 1:n_flies

        % unwrap the heading data
        D = unwrap(trx(idx).theta); %unwrap
        D_deg = (rad2deg(D));
        % Find diff in angle moved per frame. 
        D_diff = diff(D_deg);

        % Find distance moved per frame in mm. 
        V = feat.data(idx, :, 1);
        
        for ii = 1:n_conditions
       
            st_fr = Log.start_f(ii);
            stop_fr = Log.stop_f(ii)-1;

            if st_fr == 0 
                st_fr = 1;
            end 
            % data = AVR(st_fr:stop_fr);
            
            % directional do not make abs
            AV = (D_diff(st_fr:stop_fr));
            AV(isnan(AV), 1)=0;

            vel_data = V(st_fr:stop_fr);

            ratio_data = sum(AV)/sum(vel_data);
            ratio_data(isnan(ratio_data), 1)=0;

            datapoints(ii, idx+1) = ratio_data;
        end 
    end 

    % Add direction to 'datapoints'
    datapoints(1:n_conditions, n_flies+2) = Log.dir;

end 

