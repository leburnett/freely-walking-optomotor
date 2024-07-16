function [datapoints_mean, datapoints_med] = make_mean_ang_vel_ratio_datapoints(Log, trx, feat, n_flies, n_conditions, fps)

    % Fixed paramters: 
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
        % unwrap the heading data
        D = (trx(idx).theta); %unwrap
        D_deg = (rad2deg(D));
        % D_deg = D_deg/max(D_deg);
        % convert heading to angular velocity
        % AV = vel_estimate(D, samp_rate, method, t_window, cutoff);
        AV = vel_estimate(D_deg, samp_rate, method, t_window, cutoff);
        AV = abs(AV)/max(abs(AV));
        V = feat.data(idx, :, 1);
        V = V/max(V);
        AVR = AV./V;
        AVR(1, V==0)=0;

        % AVR = rad2deg(AVR);
        max_val_AVR = max(abs(AVR));
        AVR_norm = AVR/max_val_AVR;
        
        for ii = 1:n_conditions
       
            st_fr = Log.start_f(ii);
            stop_fr = Log.stop_f(ii)-1;

            if st_fr == 0 
                st_fr = 1;
            end 
            % data = AVR_norm(st_fr:stop_fr);
            data = AVR_norm(st_fr:stop_fr);
            % ang_vel_data = AV(st_fr:stop_fr);
            % vel_data = V(st_fr:stop_fr);

            datapoints_mean(ii, idx+1) = nanmean(data);
            datapoints_med(ii, idx+1) = nanmedian(data);
        end 
    end 

    % Add direction to 'datapoints'
    datapoints_mean(1:n_conditions, n_flies+2) = Log.dir;
    datapoints_med(1:n_conditions, n_flies+2) = Log.dir;

end 

