function plot_pink_blue_rects_AD(current_log, min_val, max_val, is_full)

% for testing
% current_log = LOG.log_1;
% min_val = 0; 
% max_val = 120;

h = max_val - min_val;
n_conditions = size(current_log.start_t, 2);
% check if we are plotting the full protocol10
if is_full == 0
    start_full_cond = current_log.start_f(1);
elseif is_full == 1
    start_full_cond = 0;
end

    for ii = 1:n_conditions
        % Get the timing of each condition
        st_fr = current_log.start_f(ii) - start_full_cond;
        stop_fr = current_log.stop_f(ii)-1;
        w = stop_fr - st_fr;
        % Use the Log.dir value to get the stimulus direction.
        dir_id = current_log.dir(ii);
        con_val = 1;
        if con_val > 1.2
            con_val = 1;
        end
        if dir_id == 0
        col = [1 1 1];
        elseif dir_id == 1
            col = [0.2 0.2 1 con_val*0.75];
        elseif dir_id == -1
            col = [1 0.2 1 con_val*0.75];
        end
        % Plot rectangles in the background of when the stimulus changes.
        rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
        ylim([min_val, max_val])
        hold on
        box off
        ax = gca;
        ax.XAxis.Visible = 'off';
    end

end
