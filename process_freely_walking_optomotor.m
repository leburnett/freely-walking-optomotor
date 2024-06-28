%% Process data from freely-walking optomotor experiments. 
% Assessing the effect of circadian rhythm on flies' optomotor response. 
% 24/06/24 - created by Burnett

function process_freely_walking_optomotor(path_to_folder, save_figs, genotype)

    % Variables that would be inputted as parameters in the function: 
    % path_to_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/DATA/2024_06_17';
    % 
    % genotype = 'CSW1118';
    % 
    % % save figs?
    % save_figs = true;
    
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
    
    % Folders to save figures and data
    figure_save_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/Figures';
    data_save_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/ProcessedData';
    
    % Date 
    date_str = strrep(path_to_folder(end-9:end), '_', '-');
    
    % Find times of experiments 
    cd(path_to_folder)
    time_folders = dir('*_*');
    n_time_exps = length(time_folders);
    
    % video recording rate in frames per second
    fps = 30;
    
    % number of experimental conditions
    n_conditions = 33;
    
    for exp  = 1:n_time_exps
    
        time_str = time_folders(exp).name;

        title_str = strcat(genotype, '-', date_str, '-', time_str);
        title_str = strrep(title_str, '_', '-');
        
        % Move into the experiment directory 
        cd(fullfile(time_folders(exp).folder, time_folders(exp).name))
      
        %% load the files that you need:
        % Open the LOG 
        log_files = dir('LOG_*');
        load(fullfile(log_files(1).folder, log_files(1).name));
    
        rec_folder = dir('REC_*');
        if isempty(rec_folder)
            warning('REC_... folder does not exist inside the time folder.')
        end 
        cd(fullfile(rec_folder(1).folder, rec_folder(1).name))
    
        if ~isfile('movie/movie_JAABA/trx.mat')
            warning('Experiment has not been processed using FlyTracker. Make sure the data has been processed and that trx.mat exists within the movie/movie_JAABA/ directory.')
        else
            % load trx
            load('movie/movie_JAABA/trx.mat', 'trx');
        end 
    
        % Load in FEAT
        if ~isfile('movie/movie-feat.mat')
            warning('Experiment has not been processed using FlyTracker. Make sure the data has been processed and that trx.mat exists within the movie/movie_JAABA/ directory.')
        else
            % load trx
            load('movie/movie-feat.mat', 'feat');
        end 


        % Saving paths and filenames
        save_str = strcat(date_str, '_', time_str, '_', genotype);
    
        fig_date_save_folder = fullfile(figure_save_folder, date_str);
        if ~isfolder(fig_date_save_folder)
            mkdir(fig_date_save_folder);
        end 
        
        fig_exp_save_folder = fullfile(fig_date_save_folder, time_str);
        if ~isfolder(fig_exp_save_folder)
            mkdir(fig_exp_save_folder);
        end 
    
        % Number of flies tracked in the experiment
        n_flies = length(trx);
    
        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
    
        %% Plot the heading angle of each fly across the entire experiment
        
        plot_heading_angle_per_fly(Log, trx, n_flies, n_conditions, title_str, save_str, fig_exp_save_folder, save_figs)
    
        %% Plot the angular velocity:
       
        plot_ang_vel_per_fly(Log, trx, n_flies, n_conditions, fps, title_str, save_str, fig_exp_save_folder, save_figs)
    
        %% Make 'datapoints' 
    
        datapoints = make_mean_ang_vel_datapoints(Log, trx, n_flies, n_conditions, fps);
    
        %% Plot the mean ang velocity per condition for all flies as scatter points. "Fish plot" 
       
        % If you only want to plot the data from the conditions ramping up, up
        % until the first flicker, then use "data_to_use = datapoints(1:17, :)" 
        % else use "data_to_use = datapoints". 
        
        data_to_use = datapoints; %(1:17, :);
    
        % Update contrast values for acclim / flickers for plotting:
        % OFF ACCLIM
        data_to_use(1,1) = -0.2;
        % ON ACCLIM 
        data_to_use(2,1) = -0.1;
        % FLICKER 1
        data_to_use(17,1) = 1.2;
        % FLICKER 2 
        data_to_use(32,1) = 1.3;
        % OFF ACCLIM 2
        data_to_use(33,1) = 1.4;
        
        plot_scatter_ang_vel_all_flies(data_to_use, n_flies, title_str, save_str, fig_exp_save_folder, save_figs)
    
        %% Generate a line plot for mean ang vel at each contrast level. "Lips plot"
        
        % Individual flies in light pink/blue. 
        % Average across flies in bold.
        
        data_to_use = datapoints; %(1:17, :);
       
        plot_line_ang_vel_all_flies(data_to_use, n_flies, title_str, save_str, fig_exp_save_folder, save_figs)
    
        %% SAVE
        
        % save data
        save(fullfile(data_save_folder, strcat(save_str, '_data.mat')), 'datapoints', 'data_to_use', 'Log', 'trx');
        
    end 

end 


% unique_contrasts = unique(data_to_use(:, 1));
% n_unique_contrasts = numel(unique_contrasts);
% 
% data = zeros(n_unique_contrasts, 1);
% 
% for j = 1:n_unique_contrasts
%     contr = unique_contrasts(j);
%     all_contrast = find(data_to_use(:, 1)==contr);
%     % Find the mean & abs.
%     data(j, 1) = mean(mean(abs(data_to_use(all_contrast, :))));
% end 
% 
% % Plot the figure
% figure;
% plot(unique_contrasts, data, 'k', 'LineWidth', 1.2)
% box off
% ax = gca;
% ax.TickDir = 'out';
% xlim([-0.05 1.25])
% ylim([-0.05, 1.5])
% ax.LineWidth = 1.5;
% ax.FontSize = 12;
% xlabel('Contrast')
% ylabel('Average abs ang vel')
% f = gcf;
% f.Position = [422   637   809   390];

%% Generate a scatter plot of the mean angular velocity for ONE fly for each contrast value.
% Each conditions (i.e. clockwise and anticlockwise) are plotted as separate points. 

% ALL CONDITIONS
% figure; scatter(Log.contrast, (datapoints), 300, 'k.')
% 
% % ONLY THE FIRST HALF 
% % figure; scatter(Log.contrast(1:17), abs(datapoints(1:17)), 300, 'k.')
% ax = gca;
% ax.TickDir = 'out';
% xlim([-0.05 1.05])
% ylim([-0.05, 2.5])
% ax.LineWidth = 1.5;
% ax.FontSize = 12;
% xlabel('Contrast')
% ylabel('Average abs ang vel')
% f = gcf;
% f.Position = [422   637   809   390];


