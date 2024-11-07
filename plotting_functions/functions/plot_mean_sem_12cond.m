% Plotting function - generate 6 x 2 subplot with the mean + / SEM for all
% flies from one experimental group. 

function plot_mean_sem_12cond(data)

% % Eventually have this as the input to the function 
% data = DATA.csw1118.F; 

n_exp = length(data);
total_flies = [];

% Calculate the total number of flies in this experimental group:
for idx = 1:n_exp
    n_flies = data(idx).meta.n_flies;
    total_flies = total_flies + n_flies;
end 

% Run through the different conditions: 
for cond = [1,2,4,3,5,6,8,7,9,10,12,11]

    cond_data = [];
    n_frames = 0;

    rep1_str = strcat('R1_condition_', string(cond));   
    rep2_str = strcat('R2_condition_', string(cond));  

    % JUST DO DISTANCE DATA AT THE MOMENT:
    for idx = 1:n_exp
        rep1_data = data(idx).(rep1_str);

        if ~isempty(rep1_data) % check that the row is not empty.
            % Extract the relevant data
            rep1_data = rep1_data.dist_data;
            rep2_data = data(idx).(rep2_str).dist_data;

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

            if idx == 1
                cond_data = vertcat(cond_data, rep1_data, rep2_data);
            else
                nf_comb = size(cond_data, 2);

                if nf>nf_comb % trim incoming data
                    rep1_data = rep1_data(:, 1:nf_comb);
                    rep2_data = rep2_data(:, 1:nf_comb);
                elseif nf_comb>nf % Add NaNs to end
                    diff_f = nf_comb-nf;
                    n_flies = size(rep1_data, 1);
                    rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                    rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                end 




        end 
    end 

    subplot(6,2,cond)


end 





figure; plot(mean(DATA.csw1118.F(:).R2_condition_10.dist_data))
hold on
plot([900 900], [0 120], 'k')



end 