function process_data_features(PROJECT_ROOT, path_to_folder, save_folder, date_str)
    % Processes optomotor freely-walking data from FlyTracker and saves the
    % mean/ med values per 'condition' within the experiment in arrays. it
    % also saves all of the variables with the full data across the entrie
    % experiments, such as velocity, angular velocity, distance from the
    % wall and heading in the same file. 
    
    % Inputs
    % ______
    
    % path_to_folder : Path
    %               Path of data to analyse.
    
    % save_folder : path 
    %          Path to save the processed data.        
   
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
    % PROJECT_ROOT = '\Users\burnettl\Documents\oakey-cokey\';

    cd(path_to_folder)

    % Find times of experiments
    time_folders = dir('*_*');

    % Remove '.DS_Store' file if it exists.
    time_names = {time_folders.name};
    time_folders = time_folders(~strcmp(time_names, '.DS_Store'));

    n_time_exps = length(time_folders);
    
    for exp  = 1:n_time_exps
    
        clear feat LOG trx

        time_str = time_folders(exp).name;
        disp(time_str)

        % Move into the experiment directory 
        cd(fullfile(time_folders(exp).folder, time_folders(exp).name))

        data_path = cd;
        if contains(data_path, '/') % Mac
            subfolders = split(data_path, '/');
        elseif contains(data_path, '\') % Windows
            subfolders = split(data_path, '\');
        end 

        if height(subfolders)>12 % landing site included.
            sex = subfolders{end-1};
            landing = subfolders{end-2}; 
            strain = subfolders{end-3};
            protocol = subfolders{end-4};
            date_str = strrep(date_str, '_', '-');
            time_str = strrep(time_str, '_', '-');
            save_str = strcat(date_str, '_', time_str, '_', strain, '_', landing, '_',  protocol, '_', sex);
        else % no landing site specified
            sex = subfolders{end-1};
            strain = subfolders{end-2};
            protocol = subfolders{end-3};
            date_str = strrep(date_str, '_', '-');
            time_str = strrep(time_str, '_', '-');
            save_str = strcat(date_str, '_', time_str, '_', strain, '_', protocol, '_', sex);
        end 

        % Check in case there is something wrong with the folder structure.
        if protocol(1)~='p'
            disp('protocol string does not start with a p - check folder structure.')
        end

        %% load the files that you need:
        
        % Open the LOG 
        log_files = dir('LOG_*');
        load(fullfile(log_files(1).folder, log_files(1).name), 'LOG');
    
        rec_folder = dir('REC_*');
        if isempty(rec_folder)
            warning('REC_... folder does not exist inside the time folder.')
        end 

        % Move into recording folder
        isdir = [rec_folder.isdir]==1;
        rec_folder = rec_folder(isdir);
        cd(fullfile(rec_folder(1).folder, rec_folder(1).name))

        movie_folder = dir();
        movie_folder = movie_folder([movie_folder.isdir]);
        mfolder = movie_folder(3).name;

        %% Load 'feat'

        if contains(mfolder, 'movie') % movie folder configuration
            feat_file_path = strcat('movie', delim, 'movie-feat.mat');
        else
            feat_file_path = strcat(rec_folder(1).name, '-feat.mat');
        end

        if ~isfile(feat_file_path)
            warning('Experiment has not been processed using FlyTracker. Make sure the data has been processed and that "{moviename}-feat.mat" exists within the movie/movie_JAABA/ directory.')
        else
            load(feat_file_path, 'feat');
        end

        %% Load 'trx'

        if contains(mfolder, 'movie') % movie folder configuration
            trx_file_path = strcat('movie', delim, 'movie_JAABA', delim, 'trx.mat');
            % trx_file_path = 'movie/movie_JAABA/trx.mat';

        else
            trx_file_path = strcat(mfolder, delim, 'trx.mat');
        end

        if ~isfile(trx_file_path)
            warning('Experiment has not been processed using FlyTracker. Make sure the data has been processed and that "{moviename}-track.mat" exists within the movie/movie_JAABA/ directory.')
        else
            load(trx_file_path, 'trx');
        end

        %% Generate quick overview plots:
        n_flies_in_arena = length(trx);
        [comb_data, feat, trx] = combine_data_one_cohort(feat, trx);
        n_flies_tracked = length(trx);
        n_flies_removed = n_flies_in_arena - n_flies_tracked;
        n_fly_data = [n_flies_in_arena, n_flies_tracked, n_flies_removed];
        
        if n_flies_in_arena>1
            % 1 - histograms of locomotor parameters
            f_overview = make_overview(comb_data, strain, sex, protocol);

            hist_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/overview_figs/loco_histograms';
            hist_save_folder = strrep(hist_save_folder, '/', '\'); % windows
            if ~isfolder(hist_save_folder)
                mkdir(hist_save_folder);
            end
            saveas(f_overview, fullfile(hist_save_folder, strcat(save_str, '_hist.png')), 'png')
        end

        % 2 - features - with individual traces per fly across entire
        % experiment.
        f_feat = plot_all_features_filt(LOG, comb_data, protocol, save_str);
        f_acclim = plot_all_features_acclim(LOG, comb_data, save_str);

        feat_save_folder = fullfile(PROJECT_ROOT, 'figures/overview_figs/feat_overview');
        % feat_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/overview_figs/feat_overview';
        if ~isfolder(feat_save_folder)
            mkdir(feat_save_folder);
        end
        saveas(f_feat, fullfile(feat_save_folder, strcat(save_str, '_feat.png')), 'png')
        saveas(f_acclim, fullfile(feat_save_folder, strcat(save_str, '_feat_acclim.png')), 'png')

        % 3 - Make plot with data per condition for only the one cohort
        DATA = comb_data_one_cohort_cond(LOG, comb_data, protocol);
        plot_sem = 1;

        data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data'};

        for typ = 1:numel(data_types)
            data_type = data_types{typ};
            fig_save_folder = fullfile(PROJECT_ROOT, 'figures/overview_figs/', data_type);
            if ~isfolder(fig_save_folder)
                mkdir(fig_save_folder);
            end
            % fig_save_folder = strcat('/Users/burnettl/Documents/Projects/oaky_cokey/figures/overview_figs/', data_type);
            strain = check_strain_typos(strain);
            f_cond = plot_allcond_onecohort_tuning(DATA, sex, strain, data_type, plot_sem);
            fname = fullfile(fig_save_folder, strcat(save_str, '_', data_type, '.pdf'));
            exportgraphics(f_cond ...
                , fname ...
                , 'ContentType', 'vector' ...
                , 'BackgroundColor', 'none' ...
                ); 

            if protocol == "protocol_30" % different contrasts
                f_contrasts = plot_errorbar_tuning_curve_diff_contrasts(DATA, strain, [0.8 0.8 0.8], data_type);
                con_save_folder = fullfile(PROJECT_ROOT, 'figures\overview_figs\contrast_tuning');
                if ~isfolder(con_save_folder)
                    mkdir(con_save_folder);
                end
                fname_con = fullfile(con_save_folder, strcat(save_str, '_', data_type, 'contrast_tuning.pdf'));
                exportgraphics(f_contrasts ...
                , fname_con ...
                , 'ContentType', 'vector' ...
                , 'BackgroundColor', 'none' ...
                );

            elseif protocol == "protocol_31" % different speeds
                f_ebar = plot_errorbar_tuning_diff_speeds(DATA, strain, data_type);
                sp_save_folder = fullfile(PROJECT_ROOT, 'figures\overview_figs\speed_tuning');
                if ~isfolder(sp_save_folder)
                    mkdir(sp_save_folder);
                end
                fname_ebar = fullfile(sp_save_folder, strcat(save_str, '_', data_type, 'speed_tuning.pdf'));
                exportgraphics(f_ebar ...
                , fname_ebar ...
                , 'ContentType', 'vector' ...
                , 'BackgroundColor', 'none' ...
                );
            end 

        end 
        
        % close open figures and move into the time directory with ufmf file.
        close all
        cd("../")

        % Generate videos of each condition
        add_tracks = 0;
        generate_movie_from_ufmf(add_tracks)

        % Generate videos of each condition
        add_tracks = 0;
        generate_movie_from_ufmf(add_tracks)

        %% SAVE
        if ~isfolder(save_folder)
            mkdir(save_folder);
        end
                
        % save data
        save(fullfile(save_folder, strcat(save_str, '_data.mat')) ...
            , 'LOG' ...
            , 'feat' ...
            , 'trx' ...
            , 'comb_data' ...
            , 'n_fly_data'...
            );
    end

    close all
end 



