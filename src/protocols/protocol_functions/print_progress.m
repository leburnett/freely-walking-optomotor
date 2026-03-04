function print_progress(protocol_name, phase, rep, n_reps, cond, n_conds, ...
                        exp_start, t_total_est, condition_label)
% PRINT_PROGRESS  Display a compact experiment progress summary.
%
%   Clears the command window and prints a non-scrolling progress display.
%   Call this at the start of each new experimental phase to update the
%   user on progress, elapsed time, and estimated time remaining.
%
%   Inputs:
%     protocol_name    - string, protocol name (e.g., from mfilename())
%     phase            - string, one of:
%                          'setup'             - hardware initialisation
%                          'acclimation_start' - pre-stimulus dark period
%                          'flash'             - calibration flash
%                          'stimulus'          - main stimulus presentation
%                          'acclimation_end'   - post-stimulus dark period
%                          'complete'          - experiment finished
%     rep              - current repetition number (0 if not applicable)
%     n_reps           - total number of repetitions
%     cond             - current condition number (0 if not applicable)
%     n_conds          - total number of conditions
%     exp_start        - tic value from experiment start
%     t_total_est      - estimated total experiment duration (seconds)
%     condition_label  - string describing current condition, or ''
%
%   Example:
%     exp_start = tic;
%     print_progress('protocol_27', 'stimulus', 1, 2, 3, 12, ...
%                    exp_start, 2700, 'Pattern 9 — 60 deg grating (~4 Hz)');
%
%   See also: protocol_template

    % Clear the command window for a non-scrolling display
    clc

    % --- Calculate elapsed time ---
    elapsed = toc(exp_start);
    elapsed_str = format_time(elapsed);

    % --- Calculate progress percentage ---
    switch phase
        case 'setup'
            pct = 0;
        case 'acclimation_start'
            pct = 0;
        case 'flash'
            % Flash happens early; estimate a small percentage
            pct = round(100 * elapsed / t_total_est);
        case 'stimulus'
            % Progress based on conditions completed
            completed = (rep - 1) * n_conds + (cond - 1);
            total = n_reps * n_conds;
            % Scale stimulus progress to the stimulus portion of the experiment
            stim_frac = completed / total;
            pct = round(100 * elapsed / t_total_est);
            % Use the more informative of elapsed-based or condition-based
            pct_cond = round(100 * (elapsed / t_total_est));
            pct = max(pct, round(100 * stim_frac * 0.9)); % stimulus is ~90% of time
            pct = min(pct, 99); % never show 100% until complete
        case 'acclimation_end'
            pct = min(round(100 * elapsed / t_total_est), 99);
        case 'complete'
            pct = 100;
        otherwise
            pct = 0;
    end

    % --- Build progress bar ---
    bar_width = 30;
    filled = round(bar_width * pct / 100);
    bar_str = [repmat('#', 1, filled), repmat('.', 1, bar_width - filled)];

    % --- Estimate remaining time ---
    if pct > 0 && pct < 100
        remaining = t_total_est - elapsed;
        if remaining < 0, remaining = 0; end
        total_str = format_time(t_total_est);
    elseif pct == 100
        remaining = 0;
        total_str = elapsed_str;
    else
        remaining = t_total_est;
        total_str = format_time(t_total_est);
    end
    remaining_str = format_time(remaining);

    % --- Print the progress display ---
    separator = '==============================================================';
    fprintf('%s\n', separator);

    switch phase
        case 'setup'
            fprintf(' %s | Initialising hardware\n', upper(protocol_name));
            fprintf(' Connecting camera and temperature sensor\n');

        case 'acclimation_start'
            fprintf(' %s | Pre-stimulus acclimation\n', upper(protocol_name));
            fprintf(' Panels off — flies settling in darkness\n');

        case 'flash'
            fprintf(' %s | Calibration flash\n', upper(protocol_name));
            fprintf(' Full-field flash for video synchronisation\n');

        case 'stimulus'
            fprintf(' %s | Rep %d/%d | Condition %d of %d\n', ...
                    upper(protocol_name), rep, n_reps, cond, n_conds);
            if ~isempty(condition_label)
                fprintf(' %s\n', condition_label);
            end

        case 'acclimation_end'
            fprintf(' %s | Post-stimulus acclimation\n', upper(protocol_name));
            fprintf(' Panels off — final dark period\n');

        case 'complete'
            fprintf(' %s | Experiment complete\n', upper(protocol_name));
    end

    fprintf(' [%s] %d%% | %s elapsed | ~%s remaining\n', ...
            bar_str, pct, elapsed_str, remaining_str);
    fprintf('%s\n\n', separator);

end


function s = format_time(seconds)
% FORMAT_TIME  Convert seconds to MM:SS string.
    seconds = max(0, round(seconds));
    if seconds >= 3600
        h = floor(seconds / 3600);
        m = floor(mod(seconds, 3600) / 60);
        sec = mod(seconds, 60);
        s = sprintf('%d:%02d:%02d', h, m, sec);
    else
        m = floor(seconds / 60);
        sec = mod(seconds, 60);
        s = sprintf('%02d:%02d', m, sec);
    end
end
