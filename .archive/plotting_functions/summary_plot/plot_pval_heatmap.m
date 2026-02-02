function plot_pval_heatmap(pvals_all, target_mean_all, control_mean_all, strain_names, condition_n)

  
    % fig = figure; 
    % imagesc(pvals_all);

    % Determine whether to use a red or blue colormap. 
    diff_array = (target_mean_all+30) - (control_mean_all+30);
    diff_array2 = diff_array;
    diff_array2(diff_array2>0) = 1;
    diff_array2(diff_array2<=0) = -1;

    % Flip for distance to centre.
    diff_array2(:,[5:end]) = diff_array2(:, [5:end])*-1; 

    % Initialize RGB image
    [m, n] = size(pvals_all);
    heatmap_rgb = ones(m, n, 3); % Start with white background
    
    % % Mask for significant values (<0.05)
    % sig_mask = pvals_all <0.05;
    % 
    % % Normalize p-values to range [0, 1], where 0 -> full color, 0.05 -> white
    % normalized_p = pvals_all / 0.05; % 0 to 1 for p <= 0.05
    % normalized_p(normalized_p > 1) = 1; % Cap at 1
    % 
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
    
    % subplot(1, 40, 1:39)

    % Display the heatmap
    image(heatmap_rgb);
    
    n_strains = height(strain_names);
    yticks(1:n_strains)
    yticklabels(strrep(strain_names, '_', '-'))

    % Boundaries between metric categories.
    hold on; 
    plot([2.5 2.5], [0 n_strains+1], 'k-', 'LineWidth', 1);
    plot([4.5 4.5], [0 n_strains+1], 'k-', 'LineWidth', 1.2);
    plot([6.5 6.5], [0 n_strains+1], 'k-', 'LineWidth', 1.2);
    % plot([7.5 7.5], [0 n_strains+1], 'k-', 'LineWidth', 1.2);

    % if condition_n == 12
        % Xlabels for metric names
        xticks(1:6)
        % xticklabels({...
        %     'fv-stim', ...
        %     'fv-change-3s-start', ...
        %     'turning-stim', ...
        %     'turning-5s-CW', ...
        %     'dist-rel-10'...
        %     'dist-rel-end', ...
        %     })
        xticklabels({})
    % else
    %     xticks(1:38)
    %     xticklabels({''})
    % end

    ax = gca;
    ax.FontSize = 5;
    ax.LineWidth = 0.5;

    %  % Add colour bar
    % subplot(1, 40, 40)
    % c_array(:, 1 , :) = [...
    %     1 0 0; ...
    %     1 0.2 0.2; ...
    %     1 0.4 0.4; ...
    %     1 0.6 0.6; ...
    %     1 0.8 0.8; ...
    %     1 1 1; ...
    %     0.8 0.8 1; ...
    %     0.6 0.6 1; ...
    %     0.4 0.4 1; ...
    %     0.2 0.2 1; ...
    %     0 0 1;...
    %     ];
    % 
    % imagesc(c_array);
    % axis off

end 