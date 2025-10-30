function fig = plot_polar_hist_subplot_one_cohort(DATA, entryIdx)

    %% --- Parameters ---
    % entryIdx = 1;   
    
    % which DATA row to use
    condTop  = 'R1_condition_12';
    condBot  = 'R2_condition_12';
    framesA  = 1:300;
    framesB  = 300:600;
    numBins  = 24;                           % 15° bins (adjust if desired)
    
    S_top = DATA(entryIdx).(condTop);
    S_bot = DATA(entryIdx).(condBot);
    nFlies = size(S_top.x_data, 1);          % assumes both have same # of flies
    
    %% Generate figure comprised of subplots of polar histograms.
    % The rows are the two repetitions of the phototaxis stimulus.
    % The columns are the different flies.
    
    % Figure + tiled layout
    fig = figure('Name','Heading rel. to Ref — Polar Histograms','Color','w');
    t = tiledlayout(2, nFlies, 'TileSpacing','compact','Padding','compact');
    
    % Optional overall title from meta
    try
        dtStr = string(DATA(entryIdx).meta.date);
        tmStr = string(DATA(entryIdx).meta.time);
        sgtitle(t, sprintf('Heading relative to reference (0°=N, CW) — %s %s', strrep(dtStr, '_', '-'), tmStr));
    catch
        sgtitle(t, 'Heading relative to reference (0°=N, CW)');
    end
    
    % Plot each column = fly
    for f = 1:nFlies
        % --- Top row: R1_condition_12 ---
        axTop = polaraxes(t);              % create polar axes *in the tiled layout*
        axTop.Layout.Tile = f; 
        plot_polarhist_heading_rel_ref(axTop, S_top, f, framesA, framesB, ...
            struct('numBins', numBins, 'titleStr', sprintf('R1 — Fly %d', f), ...
                   'showLegend', (f==1)));  % put legend only on first tile to avoid clutter
    
        % --- Bottom row: R2_condition_12 ---
        axBot = polaraxes(t);              % create another polar axes in the layout
        axBot.Layout.Tile = nFlies + f;
        plot_polarhist_heading_rel_ref(axBot, S_bot, f, framesA, framesB, ...
            struct('numBins', numBins, 'titleStr', sprintf('R2 — Fly %d', f), ...
                   'showLegend', false));
    end
    
    fig.Position = [1819 157 2983 547];

end 
