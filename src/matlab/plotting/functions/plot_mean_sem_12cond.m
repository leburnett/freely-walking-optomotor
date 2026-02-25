% Plotting function - generate 6 x 2 subplot with the mean + / SEM for all
% flies from one experimental group. 

function f = plot_mean_sem_12cond(DATA, strain, sex, data_type)

    % % Eventually have this as the input to the function 
    data = DATA.(strain).(sex); 

    params =[60, 4, 2;
            60, 8, 15;
            60, 4, 15;
            60, 8, 2;
            30, 4, 2;
            30, 8, 15;
            30, 4, 15;
            30, 8, 2;
            15, 4, 2;
            15, 8, 15;
            15, 4, 15;
            15, 8, 2;
            ];
    
    n_exp = length(data);
    total_flies = 0;
    
    % Calculate the total number of flies in this experimental group:
    for idx = 1:n_exp
        n_flies = size(data(idx).acclim_off1.(data_type), 1);
        total_flies = total_flies + n_flies;
    end 

    % Generate new figure
    figure;
    t = tiledlayout(6,2);
    t.TileSpacing = 'compact';

    cond_order = [1,3,4,2,5,7,8,6,9,11,12,10];

    % Run through the different conditions: 
    for idx2 = 1:1:12 
        cond = cond_order(idx2);

        p = params(cond, :);

        cond_data = [];
        nf_comb = size(cond_data, 2);

        fl_start_f = [];
    
        rep1_str = strcat('R1_condition_', string(cond));   
        rep2_str = strcat('R2_condition_', string(cond));  
    
        % JUST DO DISTANCE DATA AT THE MOMENT:
        for idx = 1:n_exp
            rep1_data = data(idx).(rep1_str);
    
            if ~isempty(rep1_data) % check that the row is not empty.
                % Extract the relevant data
                rep1_data = rep1_data.(data_type);
                rep2_data = data(idx).(rep2_str).(data_type);
    
                % Number of frames in each rep
                nf1 = size(rep1_data, 2);
                nf2 = size(rep2_data, 2);
    
                if nf1>nf2
                    nf = nf2;
                elseif nf2>nf1
                    nf = nf1;
                else 
                    nf = nf1;
                end 

                % Trim data to same length
                rep1_data = rep1_data(:, 1:nf);
                rep2_data = rep2_data(:, 1:nf);
                nf_comb = size(cond_data, 2);
    
                if idx == 1 || nf_comb == 0
                    cond_data = vertcat(cond_data, rep1_data, rep2_data);
                else
                    if nf>nf_comb % trim incoming data
                        rep1_data = rep1_data(:, 1:nf_comb);
                        rep2_data = rep2_data(:, 1:nf_comb);
                    elseif nf_comb>nf % Add NaNs to end
                        diff_f = nf_comb-nf+1;
                        n_flies = size(rep1_data, 1);
                        rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                    end 
                    cond_data = vertcat(cond_data, rep1_data, rep2_data);
                end

                fl_start = data(idx).(rep1_str).start_flicker_f;
                fl_start_f = [fl_start_f, fl_start];
  
            end 
        end 
   
        % Mean +/- SEM
        mean_data = nanmean(cond_data);
        sem_data = nanstd(cond_data)/sqrt(size(cond_data,1));
        y1 = mean_data+sem_data;
        y2 = mean_data-sem_data;
        nf_comb = size(cond_data, 2);
        x = 1:1:nf_comb;
    
        % Plot subplot for condition
        nexttile
        % subplot(6,2,idx2)

        if ismember(idx2, [1,2])
            col = 'k';
        elseif ismember(idx2, [3,4])
            col = [0.7 0.7 0.7];
        elseif ismember(idx2, [5,6])
            col = [0 0.6 0];
        elseif ismember(idx2, [7,8])
            col = [0.6 0.8 0.6];
        elseif ismember(idx2, [9, 10])
            col = [0 0 0.5];
        elseif ismember(idx2, [11, 12])
            col = [0.6 0.8 0.9];
        end 

        if data_type == "dist_data"
            rng = [0 85];
            ylb = 'Distance from centre (mm)';
            lw = 2;
        elseif data_type == "dist_trav"
            rng = [0 1];
            ylb = 'Distance travelled (mm)';
            lw = 1; 
        elseif data_type == "av_data"
            rng = [-15 15];
            ylb = "Angular velocity (deg s-1)";
            lw = 2;
        elseif data_type == "heading_data"
            rng = [-6000 6000];
            ylb = "Heading (deg)";
            lw = 2;
        end

        plot(x, y1, 'w', 'LineWidth', 1)
        hold on
        plot(x, y2, 'w', 'LineWidth', 1)
        patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.125, 'EdgeColor', 'none')
        plot(mean_data, 'Color', col, 'LineWidth', lw);
    
        % When flicker stimulus started:
        fl = mean(fl_start_f);
        plot([fl fl], rng, 'k', 'LineWidth', 0.5)
        plot([0 nf_comb], [60 60], 'k:', 'LineWidth', 0.5)
        xlim([0 nf_comb])
        ylim(rng)
        box off
        ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; ax.TickLength = [0.015 0.015]; ax.LineWidth = 1; ax.FontSize = 12;

        title(strcat(string(p(1)), 'deg-', string(p(2)), 'Hz-', string(p(3)), 's'), 'FontSize', 11)
        
    end 

    f = gcf;
    f.Position = [11    78   474   969];
    strain = strrep(strain, '_', '-');
    title(t, strcat(strain, '--', sex, '--N=', string(total_flies)), 'FontSize', 16)
    ylabel(t, ylb, 'FontSize', 16)

end 