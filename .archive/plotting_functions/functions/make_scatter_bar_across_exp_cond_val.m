function f = make_scatter_bar_across_exp_cond_val(combined_data, strain, protocol, cond_val, feature)
% For combined data across exp = generate combined data 
% Currently for protocol v1

    if feature == "vel"
        data = combined_data.vel_data;
        ylims = [0 30];
    elseif feature == "angvel"
        data = abs(combined_data.av_data);
        ylims = [0 20];
    elseif feature == "dist"
        data = combined_data.dist_data;
        ylims = [0 125];
    end 
    
    PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey/'; 
    load(fullfile(PROJECT_ROOT, strcat('/example_logs/', protocol,'_log.mat')), 'Log');
    
    % If protocol = v1
    if protocol == "protocol_v1"
        off_range = 1: Log.stop_f(1);
        on_range = Log.start_f(2) : Log.stop_f(2);
        opto_range = Log.start_f(15):Log.stop_f(16);  % , Log.start_f(18):Log.stop_f(31)
        flicker_range = Log.start_f(17):Log.stop_f(17);
    elseif protocol == "protocol_v7" || protocol == "protocol_v9"
        off_range = 1: Log.stop_f(1);
        on_range = Log.start_f(2) : Log.stop_f(2);
        opto_range = [Log.start_f(3):Log.stop_f(10), Log.start_f(12):Log.stop_f(19)];  % , Log.start_f(18):Log.stop_f(31)
        flicker_range = [Log.start_f(11):Log.stop_f(11), Log.start_f(20):Log.stop_f(20)];
    end 

    
    data_off = data(:, off_range);
    doff_mean = nanmean(data_off, 2);
    
    n_flies = numel(doff_mean);
    
    data_on = data(:, on_range);
    don_mean = nanmean(data_on, 2);
    
    % protocol v1 
    data_opto = data(:, opto_range);
    dopto_mean = nanmean(data_opto, 2);
    
    data_flicker = data(:, flicker_range);
    dflicker_mean = nanmean(data_flicker, 2);
    
    % data
    xvals = [ones(1,n_flies), ones(1,n_flies)*2, ones(1,n_flies)*3, ones(1,n_flies)*4];
    yvals = [doff_mean', don_mean', dopto_mean', dflicker_mean'];
    
    figure;
    scatter(xvals...
        , yvals ...
        , 50 ...
        , [0.6 0.6 0.6] ...
        , 'o' ...
        , 'XJitter', 'density' ...
        , 'XJitterWidth', 0.5 ...
        )
    hold on
    boxplot(yvals ...
        , xvals ...
        , 'Color', 'k' ...
        , 'Symbol', '' ...
        )
    h = findobj(gca,'tag','Median');
    set(h,'LineWidth',2.2)
    box off
    set(gca ...
        , 'TickDir', 'out' ...
        , 'TickLength', [0.02 0.02] ...
        , 'LineWidth', 1 ...
        , 'FontSize', 14 ...
        , 'FontName', 'Arial' ...
        , 'YLim', ylims ...
        )
    set(gcf, 'Position', [37   590   258   438])
    xticks([1,2,3,4])
    xticklabels({'Off', 'On', 'Opto', 'Flicker'})
    xtickangle(45)
    if feature == "vel"
        ylabel('Velocity (mm s-1)')
        str_tit = "velocity";
        txt_n = 28;
    elseif feature == "angvel"
        ylabel('Angular velocity (deg s-1)')
        str_tit = "ang-vel";
        txt_n = 19;
    elseif feature == "dist"
        ylabel('Distance from centre (mm)')
        str_tit = "dist2centre";
        txt_n = 123;
    end 
    
    % Add median values on top
    text(1, txt_n, num2str(nanmedian(doff_mean), 3), "Color", 'k', 'HorizontalAlignment','center', "FontSize", 12)
    text(2, txt_n, num2str(nanmedian(don_mean), 3), "Color", 'k', 'HorizontalAlignment','center', "FontSize", 12)
    text(3, txt_n, num2str(nanmedian(dopto_mean), 3), "Color", 'r', 'HorizontalAlignment','center', "FontSize", 12)
    text(4, txt_n, num2str(nanmedian(dflicker_mean), 3), "Color", 'b', 'HorizontalAlignment','center', "FontSize", 12)
    

    title(strcat(strrep(strain, '_', '-'), '-', str_tit, '-',string(cond_val), 'pix-n=', num2str(n_flies)), 'FontWeight', 'bold', "FontSize", 12)

    f = gcf;


    %% Repeated measures ANOVA 
    % Table with every fly as a row and the different conditions as a column. 

    % d_acclim = mean(horzcat(don_mean, doff_mean),2);
    % d_array = [d_acclim, dopto_mean, dflicker_mean];
    % flyID = (1:size(d_array,1))';
    % % stimuli = {'off', 'on', 'opto', 'flicker'};
    % stimuli = {'Stimulus1', 'Stimulus2', 'Stimulus3'};
    % tbl = array2table(d_array, 'VariableNames', stimuli);
    % tbl.FlyID = flyID;
    % 
    % WithinDesign = table(stimuli', 'VariableNames', 'Stimuli');
    % rm = fitrm(tbl, 'Stimulus1-Stimulus3 ~ 1', 'WithinDesign', WithinDesign);
    % ranovatbl = ranova(rm);
    % 
    % % Perform pairwise comparisons (post-hoc test)
    % multcompare(rm, 'Stimuli')



end 
