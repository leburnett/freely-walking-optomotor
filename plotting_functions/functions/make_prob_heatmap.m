function make_prob_heatmap()
% Generate a spatial heatmap of where the fly was during different parts of
% the experiment. 

% Protocol v6 - 7 clockwise and anti trials - flicker

    % get a list of all .mat results files. 
    data_files = dir('*.mat');
    n_files = length(data_files);
    t = tiledlayout(1,7);

 for subpl = 1:7

     nexttile

     if subpl == 1
         % off
         range = 1: Log.stop_f(1);
         sub_tit = 'OFF';
     elseif subpl ==2 
         % on
         range = Log.start_f(2) : Log.stop_f(2);
         sub_tit = 'ON';
     elseif subpl ==3 
         %opto 1
         range = Log.start_f(3):Log.stop_f(16); 
         sub_tit = 'OPTO';
     elseif subpl ==4 
         %flicker
          range = Log.start_f(17):Log.stop_f(17);
          sub_tit = 'FLICKER';
     elseif subpl ==5 
         %opto 2
         range = Log.start_f(18):Log.stop_f(31);
         sub_tit = 'OPTO';
     elseif subpl ==6 
         % flicker 2
         range = Log.start_f(32):Log.stop_f(32);
         sub_tit = 'FLICKER';
     elseif subpl == 7
         % off 2
         range = Log.start_f(33):Log.stop_f(33)-2;
         sub_tit = 'OFF';
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
        max_lim = max(max(pos_data))*0.6;
        imagesc(pos_data); clim([0 max_lim])
        colormap("gray")
        set(gcf, 'Position', [178  819  1487 205])
        axis off
        title(sub_tit)

 end 


end 


