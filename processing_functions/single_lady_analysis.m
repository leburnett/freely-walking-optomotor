function single_lady_analysis()

load("/Users/burnettl/Documents/Projects/oaky_cokey/results/DATA_ES_Shibire_Kir_group_vs_solo.mat", 'DATA');

protocol = "protocol_25";

% DATA = comb_data_across_cohorts_cond_v25(protocol_dir);

% % % % % Screen strains:
gp_data = {
    'jfrc100_es_shibire_kir', 'F', [0.7 0.7 0.7], 1; 
    'jfrc100_es_shibire_kir_solo', 'F', [0 0 0.8], 2; 
    };

%% Compare the responses of multiple experimental groups to the same condition. 
% Generate a plot of multiple different conditions - as above - but with
% different coloured lines for the different experimental groups: 

% The indices of the different groups to plot: 
close all

% P 25
cond_titles = {"60deg-gratings-4Hz"...
    , "60deg-gratings-8Hz"...
    , "60deg-flicker-4Hz"...
    };

plot_sem = 1;

data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta'};

for typ = 1:5

    data_type = data_types{typ};

    % Data in time series are downsampled by 10.
    f_xgrp = plot_allcond_acrossgroups_tuning(DATA, gp_data, cond_titles, data_type, gps2plot, plot_sem);
    f_xgrp.Position = [1   671   697   376];
    % f_scbox = scatter_boxchart_per_cond_per_grp(DATA, gp_data, cond_titles, data_type, gps2plot);
    % save as a PDF - 'Padding' option only for MATLAB online.
    % fname = fullfile(Xgrp_save_folder, strcat(join(string(gps2plot), "-"), '_', data_type) + ".pdf");
    % fname = fullfile(Xgrp_save_folder, strcat(grp_title, '_', data_type, ".pdf"));
    % exportgraphics(f_xgrp ...
    %     , fname ...
    %     , 'ContentType', 'vector' ...
    %     , 'BackgroundColor', 'none' ...
    %     ); 
end


end 

