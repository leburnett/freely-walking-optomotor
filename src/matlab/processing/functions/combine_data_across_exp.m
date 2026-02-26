function combined_data = combine_data_across_exp(path_to_data)

    % move into the folder.
    cd(path_to_data)

    FPS = 30; % videos acquired at 30 FPS
    
    % get a list of all .mat results files. 
    data_files = dir('*.mat');
    n_files = length(data_files);
    
    all_velocity_data = []; 
    all_dist_data = []; 
    all_av_data = [];
    all_heading_data = [];
    all_dist_trav = [];
    
    for i = 1:n_files

        load(data_files(i).name);
        % disp(data_files(i).name) % good for troubleshooting

        % velocity % % % % % % % % % % % 
        vel_data = feat.data(:, :, 1);
        dist_trav = vel_data/FPS;
    
        % distance from centre % % % % % % % % % % % 

        dist_data  = 120 - feat.data(:, :, 9); % raw data is distance from wall. Must subtract from 120. 
    
        % angular velocity % % % % % % % % % % % 

        % Fixed paramters: 
        n_flies = length(trx);
        fps = 30;
        samp_rate = 1/fps; 
        method = 'line_fit';
        t_window = 16;
        cutoff = [];

        heading_data = []; 
        av_data = [];
        for idx = 1:n_flies
            D = rad2deg(unwrap(trx(idx).theta)); 
            heading_data(idx, :) = D;
            av_data(idx, :) = vel_estimate(D, samp_rate, method, t_window, cutoff);
        end
 
        % Fill with NaNs to account for different numbers of frames across
        % experiments. % % % % % % % % % 

        % assume that all of the features have the same number of frames -
        % should do - the data is from the same experiments! 
        [rowsall, colsall] = size(all_velocity_data);
        [rowsdata, colsdata]  = size(vel_data);
        n_cols_diff = colsall-colsdata;

        if n_cols_diff >=0 
            vel_data = [vel_data, NaN(rowsdata, n_cols_diff)];
            dist_data = [dist_data, NaN(rowsdata, n_cols_diff)];
            dist_trav = [dist_trav, NaN(rowsdata, n_cols_diff)];
            av_data = [av_data, NaN(rowsdata, n_cols_diff)];
            heading_data = [heading_data, NaN(rowsdata, n_cols_diff)];
        elseif n_cols_diff < 0 
            all_velocity_data = [all_velocity_data, NaN(rowsall, n_cols_diff*-1)];
            all_dist_data = [all_dist_data, NaN(rowsall, n_cols_diff*-1)];
            all_dist_trav = [all_dist_trav, NaN(rowsall, n_cols_diff*-1)];
            all_av_data = [all_av_data, NaN(rowsall, n_cols_diff*-1)];
            all_heading_data = [all_heading_data, NaN(rowsall, n_cols_diff*-1)];
        end 

        % Combine data across results files / different experiments. % % % % %

        all_velocity_data = vertcat(all_velocity_data, vel_data);
        all_dist_data = vertcat(all_dist_data, dist_data);
        all_dist_trav = vertcat(all_dist_trav, dist_trav);
        all_av_data = vertcat(all_av_data, av_data);
        all_heading_data = vertcat(all_heading_data, heading_data);

    end 

    % Combine the matrices into an overall struct
    combined_data.vel_data = all_velocity_data;
    combined_data.dist_data = all_dist_data;
    combined_data.dist_trav = all_dist_trav;
    combined_data.av_data = all_av_data;
    combined_data.heading_data = all_heading_data;

end 