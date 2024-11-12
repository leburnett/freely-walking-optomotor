function combined_data = combine_data_one_cohort(feat, trx)
    % Combine the data about different features together to use when plotting
    % quick overview plots while processing. 

    FPS = 30; % videos acquired at 30 FPS
    
    % velocity % % % % % % % % % % % 
    vel_data = feat.data(:, :, 1);
    dist_trav = vel_data/FPS;

    % distance from centre % % % % % % % % % % % 

    dist_data  = 120 - feat.data(:, :, 9); % raw data is distance from wall. Must subtract from 120. 

    % angular velocity % heading% % % % % % % % % % % 

    % Fixed paramters: 
    n_flies = length(trx);
    fps = 30;
    samp_rate = 1/fps; 
    method = 'line_fit';
    t_window = 16;
    cutoff = [];

    heading_data = []; 
    heading_wrap = [];
    av_data = [];
    for idx = 1:n_flies
        D = rad2deg(unwrap(trx(idx).theta)); 
        heading_data_unwrap(idx, :) = D;
        heading_wrap(idx, :) = rad2deg(trx(idx).theta); 
        av_data(idx, :) = vel_estimate(D, samp_rate, method, t_window, cutoff);
    end

    % Combine the matrices into an overall struct
    combined_data.vel_data = vel_data;
    combined_data.dist_data = dist_data;
    combined_data.dist_trav = dist_trav;
    combined_data.av_data = av_data;
    combined_data.heading_data = heading_data_unwrap;
    combined_data.heading_wrap = heading_wrap;

end 

% sometimes you might get an error like: "Unable to perform assignment
% because the size of the left side is 1-by-31505 and the size of the right side is 30640-by-1."
% I think this is because flies have not been tracked properly and one fly
% has been split into two 'flies' and so you don't get full tracking across
% the entire experiment. I remove flies that have not been tracked to
% completion. 
% % 
% trx([1,9,13]) = [];
% feat.data([1,9,13], :, :) = [];
% move to correct folders:
% save('trx.mat', 'trx')
% save('REC__cam_0_date_2024_11_11_time_12_33_27_v001-feat.mat', 'feat')