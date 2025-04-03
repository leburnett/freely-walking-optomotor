function process_screen_p27_data()

    ROOT_DIR = '\Users\burnettl\Documents\oakey-cokey\';
    % Move to the directory to where the results per experiment are saved:
    protocol_dir = fullfile(ROOT_DIR, 'results', 'protocol_27');
    cd(protocol_dir);
    
    if contains(protocol_dir, '/') % Mac
        strs = split(protocol_dir, '/');
    elseif contains(protocol_dir, '\') % Windows
        strs = split(protocol_dir, '\');
    end 
    protocol = strs(end);
    
    % Get all of the strain folders that are inside the protocol folder.
    strain_folders = dir;
    strain_folders = strain_folders([strain_folders.isdir]); % Keep only directories
    strain_folders = strain_folders(~ismember({strain_folders.name}, {'.', '..'})); % Remove '.' and '..'
    n_strains = height(strain_folders);
    
    % Check and change DCH VCH name. 
    folderMatch = any(contains({strain_folders.name}, "ss1209_DCH-VCH_shibire_kir"));
    if folderMatch
        index = find(contains({strain_folders.name}, "ss1209_DCH-VCH_shibire_kir"));
        strain_folders(index).name = strrep(strain_folders(index).name, "ss1209_DCH-VCH_shibire_kir", "ss1209_DCH_VCH_shibire_kir");
    end 
    
    % Generate the struct 'DATA' that combines data across experiments and
    % separates data into conditions.
    DATA = comb_data_across_cohorts_cond(protocol_dir);
    
    % Which colour to plot each group in. 
    gp_data = {
        'jfrc100_es_shibire_kir', 'F', [0.7 0.7 0.7]; % light grey
        'ss324_t4t5_shibire_kir', 'F', [0.6 0.8 0.6]; % green
        'l1l4_jfrc100_shibire_kir', 'F', [0.4 0.8 1]; % blue
        'ss26283_H1_shibire_kir', 'F', [0.8, 0 , 0]; % red
        'ss01027_H2_shibire_kir', 'F', [0.8, 0.4, 0]; % orange
        'ss1209_DCH_VCH_shibire_kir', 'F', [0.52, 0.12, 0.57]; % purple
        'ss34318_Am1_shibire_kir', 'F', [1, 0.85, 0]; % gold
        };
    
    % Store figures in folders of the day that they were created too. Can go
    % back and look at previous versions. 
    date_str = string(datetime('now','TimeZone','local','Format','yyyy_MM_dd'));
    
    % If saving the figures - create a folder to save them in:
    save_folder = fullfile(ROOT_DIR, "figures", protocol, date_str);
    if ~isfolder(save_folder)
        mkdir(save_folder);
    end
    
    %Save the groups that were used for the plots
    writecell(gp_data, fullfile(save_folder,'group_data.txt'), 'Delimiter', ';')
    
    cond_titles = {"60deg-gratings-4Hz"...
        , "60deg-gratings-8Hz"...
        , "narrow-ON-bars-4Hz"...
        , "narrow-OFF-bars-4Hz"...
        , "ON-curtains-8Hz"...
        , "OFF-curtains-8Hz"...
        , "reverse-phi-2Hz"...
        , "reverse-phi-4Hz"...
        , "60deg-flicker-4Hz"...
        , "60deg-gratings-static"...
        , "60deg-gratings-0-8-offset"...
        , "32px-ON-single-bar"...
        };
    
    writecell(cond_titles, fullfile(save_folder,'cond_titles.txt'), 'Delimiter', ';')
    
    %% Plot the timeseries responses of different strains versus ES for different data metrics.

    plot_sem = 1;
    data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta'};
    
    for strain = 2:n_strains
    
        grp_title = gp_data{strain, 1};

        if isfield(DATA, grp_title) % Check if there is data for the strain in DATA
            disp(strcat("Plotting the data for " , grp_title))
        
            for typ = 1:5
        
                % Data type to plot
                data_type = data_types{typ};
        
                % Plot the chosen strain against the ES controls.
                gps2plot = [1, strain];
        
                % Data in time series are downsampled by 10.
                f_xgrp = plot_allcond_acrossgroups_tuning(DATA, gp_data, cond_titles, data_type, gps2plot, plot_sem);
            
                fname = fullfile(save_folder, strcat(grp_title, '_', data_type, ".pdf"));
                exportgraphics(f_xgrp ...
                    , fname ...
                    , 'ContentType', 'vector' ...
                    , 'BackgroundColor', 'none' ...
                    ); 
                close
            end
        else 
            disp(strcat("No data for ", grp_title))
        end 
    
    end 

% FIX ME - ADD PLOTS OF THE 'baseline' LOCOMOTION / TURNING during the
% ACCLIM period before.... 

end 
