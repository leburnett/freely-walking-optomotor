function [datapoints_mean, datapoints_med]  = make_mean_datapoints(Log, feat, trx, n_flies, n_conditions, feature)

    % Fixed paramters for angular velocity: 
    fps = 30;
    samp_rate = 1/fps; 
    method = 'line_fit';
    t_window = 16;
    cutoff = []; 

    % % % % % % % % % % %

    contrast_vals = Log.contrast; 
    
    datapoints_mean = zeros(n_conditions, n_flies+1);
    datapoints_mean(1:n_conditions, 1) = contrast_vals;

    datapoints_med = zeros(n_conditions, n_flies+1);
    datapoints_med(1:n_conditions, 1) = contrast_vals;

    for idx = 1:n_flies

        if feature == "angvel"
            % unwrap the heading data
            D = unwrap(trx(idx).theta);
            % convert heading to angular velocity
            AV = vel_estimate(D, samp_rate, method, t_window, cutoff);
        elseif feature == "vel"
            V = feat.data(idx,:,1);
        elseif feature == "ratio"
            D = unwrap(trx(idx).theta);
            D_deg = (rad2deg(D));
            D_diff = diff(D_deg);
            V = feat.data(idx,:,1);
        elseif feature == "dist"
            V = feat.data(idx,:,9);
        end 

        for ii = 1:n_conditions

            st_fr = Log.start_f(ii);
            stop_fr = Log.stop_f(ii)-1;

            if st_fr == 0 
                st_fr = 1;
            end 

            if feature == "angvel" 
                if stop_fr > numel(AV)
                    stop_fr = numel(AV);
                end
            elseif feature == "ratio"
                if stop_fr > numel(D_diff)
                    stop_fr = numel(D_diff);
                end
            else
                if stop_fr > numel(V)
                    stop_fr = numel(V);
                end
            end 
            
            if feature == "angvel"
                data = AV(st_fr:stop_fr);
            elseif feature == "vel" || feature == "dist" 
                data = V(st_fr:stop_fr);
            elseif feature == "ratio"
                % directional do not make abs
                AV = (D_diff(st_fr:stop_fr));
                AV(isnan(AV), 1)=0;
                vel_data = V(st_fr:stop_fr);
                ratio_data = sum(AV)/sum(vel_data);
                ratio_data(isnan(ratio_data), 1)=0;
            end 

            if feature == "ratio"
                datapoints_mean(ii, idx+1) = ratio_data;
                datapoints_med = datapoints_mean;
            elseif feature == "vel" || feature == "angvel" || feature == "dist"
                datapoints_mean(ii, idx+1) = nanmean(data);
                datapoints_med(ii, idx+1) = nanmedian(data);
            end 
        end 
    end 

    % Add direction to 'datapoints'
    datapoints_mean(1:n_conditions, n_flies+2) = Log.dir;
    datapoints_med(1:n_conditions, n_flies+2) = Log.dir;

end 










