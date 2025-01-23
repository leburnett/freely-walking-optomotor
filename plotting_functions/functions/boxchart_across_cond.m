% Statistics during conditions

% Generate a single figure composed of different subplots for the different
% conditions. The responses of different experimental groups are overlaid
% in different colours. 


    figure;
    n_cond = length(params);

    group_id = 1;
%% For each experimental group (strain-sex):
for gp = gps2plot

    % % Eventually have this as the input to the function 
    strain = gp_data{gp, 1};
    landing = gp_data{gp, 2};
    sex = gp_data{gp, 3};
    col = gp_data{gp, 4};

    data = DATA.(strain).(landing).(sex); 

    n_exp = length(data);

    % Find out which conditions exist:
    [min_val, max_val] = range_of_conditions(data);

    % Run through the different conditions: 
    for idx2 = min_val:1:max_val 

        rep1_str = strcat('R1_condition_', string(idx2));   
        rep2_str = strcat('R2_condition_', string(idx2));  

        if isfield(data, rep1_str)

        cond_data = [];
        nf_comb = size(cond_data, 2);

        fl_start_f = [];
    
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

        fl = int16(mean(fl_start_f));
   
        % Mean +/- SEM

        data_stim = cond_data(:, 300:fl); % Only for the period during the stimulus movement - not pre / post. 

        if data_type == "av_data" || data_type == "curv_data"
            data_stim = abs(data_stim);
        end 

        mean_per_fly = nanmedian(data_stim, 2);
        n_flies_in_cond = size(cond_data, 1);
        xvals = ones(1, n_flies_in_cond)*group_id;

        %% BAR CHART - MEAN 

        subplot(n_cond/2, 2, idx2) % Different subplot for each condition. 
        boxchart(xvals', mean_per_fly, 'BoxFaceColor', col, 'MarkerColor', 'k'); 
        hold on 

        xlim([0.5 3.5])
        box off
        % ylim(rng)
        ylim([0 100])
        ax = gca; 
        ax.TickDir = 'out';
        ax.TickLength = [0.02 0.02]; 
        ax.LineWidth = 1; 
        ax.FontSize = 12;
        % if ~ismember(idx2, [1,3,5,7,9])
        %     ax.YAxis.Visible = 'off';
        % end 
        if idx2 == 5
            ylabel('Turning rate (deg mm-1)')
        end 

        xticks([1,2,3])
        xticklabels({'control', 'mmd', 'ttl'})

        end 

    end 

    group_id = group_id +1;

end 

    f = gcf;
    f.Position = [ 1    73   440   974];
    % sgtitle(ylb, 'FontSize', 16)

end 













