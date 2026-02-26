function plot_pval_heatmap_strains(pvals_all, target_mean_all, control_mean_all, plot_x, multi)

    % Determine whether to use a red or blue colormap. 
    diff_array = (target_mean_all+30) - (control_mean_all+30);
    diff_array2 = diff_array;
    diff_array2(diff_array2>0) = 1;
    diff_array2(diff_array2<=0) = -1;

    % Add here if changing the sign for reverse phi and centring:
    % Rows 7&8 = reverse phi, cols 8:17
    % Cols 18-23 = centring. 
    diff_array2(:,[7:end]) = diff_array2(:, [7:end])*-1; % % % % % % %% potentially to 17 - check last one.
    % diff_array2(7:8,8:17) = diff_array2(7:8, 8:17)*-1;    

    % Initialize RGB image
    [m, n] = size(pvals_all);
    heatmap_rgb = ones(m, n, 3); % Start with white background
    
    % % Mask for significant values (<0.05)
    % sig_mask = pvals_all <0.05;
    % 
    % % Normalize p-values to range [0, 1], where 0 -> full color, 0.05 -> white
    % normalized_p = pvals_all / 0.05; % 0 to 1 for p <= 0.05
    % normalized_p(normalized_p > 1) = 1; % Cap at 1

    normalized_p = mapValues(pvals_all);
    
    % Loop through each element
    for i = 1:m
        for j = 1:n
            p_val = normalized_p(i,j);
            if diff_array2(i,j) > 0
                % Red: full red at low p, fade to white
                heatmap_rgb(i,j,:) = [1, p_val, p_val]; % Red fades with p
            else
                % Blue: full blue at low p, fade to white
                heatmap_rgb(i,j,:) = [p_val, p_val, 1]; % Blue fades with p
            end
        end
    end
    
    if ~multi
        figure
        subplot(1, 40, 1:39)
    end 

    % Display the heatmap
    image(heatmap_rgb);
    
    % cond_titles = {"60deg-gratings-4Hz"...
    %     , "60deg-gratings-8Hz"...
    %     , "narrow-ON-bars-4Hz"...
    %     , "narrow-OFF-bars-4Hz"...
    %     , "ON-curtains-8Hz"...
    %     , "OFF-curtains-8Hz"...
    %     , "reverse-phi-2Hz"...
    %     , "reverse-phi-4Hz"...
    %     , "60deg-flicker-4Hz"...
    %     , "60deg-gratings-static"...
    %     , "60deg-gratings-0-8-offset"...
    %     , "32px-ON-single-bar"...
    %     };

        % cond_titles = {"60deg-gratings-4Hz"...
        % , "60deg-gratings-8Hz"...
        % , "60deg-flicker-4Hz"...
        % , "60deg-gratings-static"...
        % };

         cond_titles = {"60deg-gratings-4Hz"};

    n_conditions = numel(cond_titles);
    yticks(1:n_conditions)
    yticklabels(cond_titles)

    % Boundaries between metric categories.
    hold on; 
    plot([1.5 1.5], [0 n_conditions+1], 'k-', 'LineWidth', 1);
    plot([3.5 3.5], [0 n_conditions+1], 'k-', 'LineWidth', 1.2);
    plot([6.5 6.5], [0 n_conditions+1], 'k-', 'LineWidth', 1.2);
    % plot([16.5 16.5], [0 n_conditions+1], 'k-', 'LineWidth', 1.2);
    % plot([19.5 19.5], [0 n_conditions+1], 'k-', 'LineWidth', 1.2);

    if plot_x
        % Xlabels for metric names
        xticks(1:11)
        xticklabels({...
            'fv-10s-b4', ...
            'fv-stim', ...
            'fv-change-3s-start', ...
            'turning-stim', ...
            'turning-5s-CW', ...
            'dist-abs-start'...
            'dist-abs-end', ...
            'dist-rel-10'...
            'dist-rel-end', ...
            'dist-rel-10-int'
            })
        % xtickangle(90)
    else
        xticks(1:11)
        xticklabels({''})
    end

    ax = gca;
    ax.FontSize = 5;
    ax.LineWidth = 0.5;

    if ~multi
        % Add colour bar
        subplot(1, 40, 40)
       
        c_array(:, 1 , :) = [...
            1 0 0; ...
            1 0.2 0.2; ...
            1 0.4 0.4; ...
            1 0.6 0.6; ...
            1 0.8 0.8; ...
            1 1 1; ...
            0.8 0.8 1; ...
            0.6 0.6 1; ...
            0.4 0.4 1; ...
            0.2 0.2 1; ...
            0 0 1;...
            ];
    
        imagesc(c_array);
        axis off
    end 



end 