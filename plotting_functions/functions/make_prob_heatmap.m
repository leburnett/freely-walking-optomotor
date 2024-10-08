function make_prob_heatmap(data_folder)
% Generate a spatial heatmap of where the fly was during different parts of
% the experiment. 

    % Protocol v6 - 7 clockwise and anti trials - flicker
    cd(data_folder)

    % Information about the strain / protocol.

    subfolders = split(data_folder, '/');
    % protocol v6
    cond = subfolders{end};
    % sex = subfolders{end-1};
    strain = subfolders{end-2};
    protocol = subfolders{end-3};

    % protocol v5
    % sex = subfolders{end};
    % strain = subfolders{end-1};
    % protocol = subfolders{end-2};


    % Load log
    PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey/'; 
    load(fullfile(PROJECT_ROOT, strcat('/example_logs/', protocol,'_log.mat')), 'Log');
    
    % get a list of all .mat results files. 
    data_files = dir('*.mat');
    n_files = length(data_files);

    % Generate figure
    figure
    tiledlayout(1,3);

 for subpl = 1:3

     nexttile

     if protocol == "protocol_v6" || protocol == "protocol_v1" 
         if subpl == 1
             % off
             range = 1: Log.stop_f(2);
             sub_tit = 'ACCLIM';
         elseif subpl ==2 
             %opto
             range = [Log.start_f(3):Log.stop_f(16), Log.start_f(18):Log.stop_f(31)]; 
             sub_tit = 'OPTOMOTOR';
         elseif subpl ==3 
             %flicker
              range = [Log.start_f(17):Log.stop_f(17), Log.start_f(32):Log.stop_f(32)];
              sub_tit = 'FLICKER';
         end 
     elseif protocol == "protocol_v5"
         if subpl == 1
             % off
             range = 1: Log.stop_f(2);
             sub_tit = 'ACCLIM';
         elseif subpl ==2 
             %opto
             range = [Log.start_f(3):Log.stop_f(10), Log.start_f(12):Log.stop_f(19)]; 
             sub_tit = 'OPTOMOTOR';
         elseif subpl ==3 
             %flicker
              range = [Log.start_f(11):Log.stop_f(11), Log.start_f(20):Log.stop_f(20)];
              sub_tit = 'FLICKER';
         end 
     end 


        for i = 1:n_files
        
            load(data_files(i).name);
    
            n_flies = length(trx);
    
            im_size = 1024;
            smooth_kernel = [1 2 1]/4;
            bin_size = 16;
            num_bins = im_size / bin_size;
            
            % Create an empty array to hold the bin counts
            pos_data  = zeros(num_bins, num_bins);
    
            for idx = 1:n_flies
                % Find the distance travelled. 
                x = trx(idx).x;
                y = trx(idx).y;
                
                % Added this step from feat_compute.m from FlyTracker
                x(2:end-1) = conv(x,smooth_kernel,'valid');
                y(2:end-1) = conv(y,smooth_kernel,'valid');
    
                for f = range
                    % Calculate the bin index for the x and y position
                    x_bin = floor(x(f) / bin_size) + 1;
                    y_bin = floor(y(f) / bin_size) + 1;
    
                    if ~isnan(x_bin) && ~isnan(y_bin)
                        pos_data(x_bin, y_bin) = pos_data(x_bin, y_bin) +1; 
                    end 
                end 
    
            end 
            
        end 
        pos_data = pos_data/sum(sum(pos_data));
        max_lim = max(max(pos_data))*0.4;

        % plot
        imagesc(pos_data); clim([0 max_lim])
        hold on
        plot(num_bins/2, num_bins/2, 'c+', 'MarkerSize', 12, 'LineWidth', 2.5);
        viscircles([num_bins/2, num_bins/2], num_bins/2, "Color", 'w', "LineWidth", 0.4); 

        infern = cmap_inferno();
        colormap(infern)
        % set(gcf, 'Position', [178  819  1487 205])
        set(gcf, 'Position', [178   738   950   286])
        axis off
        title(sub_tit)
        xlim([0 num_bins])
        ylim([0 num_bins])

        if subpl == 3
            hcb=colorbar;
            hcb.Title.String = "Probability";
            hcb.Ruler.SecondaryLabel.Units = 'normalized';
            hcb.Ruler.SecondaryLabel.Position = [1.07 0.95];
        end 
 end 

 if protocol == "protocol_v6"
    sgtitle(strcat(strrep(strain, '_', '-'), '-', strrep(cond, '_', '-')))
 else
    sgtitle(strrep(strain, '_', '-'))  
 end 

end 


