
% For csw1118 - F 

strain = 'csw1118';
sex = 'F';

% Get only data that I want. 
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


%  1 - Is there a significant difference in the clustering of flies to
%  different conditions?


% Compare distance from centre during the grating stimulus for each of the
% conditions versus acclim off and acclim patt. 

% - acclim_off
% - acclim_patt
% - cond1
% - cond2 
% - ...

% Find out the total number of flies that were used.
n_exp = length(data);
total_flies = 0;

% Calculate the total number of flies in this experimental group:
for idx = 1:n_exp
    n_flies = size(data(idx).acclim_off1.(data_type), 1);
    total_flies = total_flies + n_flies;
end

fly_data = NaN(total_flies, 14);
data_type = 'dist_data';
curr_n = 0;

for exp = 1:n_exp
    disp(strcat('Exp - ', string(exp)))

    n_flies = size(data(exp).acclim_off1.(data_type), 1);
    for i = 1:n_flies
        disp(strcat('Fly - ', string(i)))

        % acclim_off
        d_fly = data(exp).acclim_off1.(data_type);
        fly_data(i+curr_n, 1) = nanmean(d_fly(i, :));
    
        % acclim_patt
        d_fly = data(exp).acclim_patt.(data_type);
        fly_data(i+curr_n, 2) = nanmean(d_fly(i, :));
    
        for cond = 1:12
            disp(strcat('Cond - ', string(cond)))

            % clear data arrays
            f1_data = [];
            f2_data = [];
            f_data = [];

            rep1_str = strcat('R1_condition_', string(cond));   
            rep2_str = strcat('R2_condition_', string(cond)); 
            % Check for the existence of data from this condition for this
            % fly.
            rep1_data = data(exp).(rep1_str);
            if ~isempty(rep1_data)
                rep1_data = rep1_data.(data_type);
                rep2_data = data(exp).(rep2_str).(data_type);
                
                % if data_type == "dist_data"
                    f1_data = rep1_data(i, 450:900);
                    f2_data = rep2_data(i, 450:900);
                % else
                %     f1_data = rep1_data(i, :);
                %     f2_data = rep2_data(i, :);
                % end 

                f_data = vertcat(f1_data, f2_data);
                fly_data(i+curr_n, cond+2) = nanmean(nanmean(f_data));
            end 
        end
    end 
    curr_n = curr_n+n_flies;

end 


T = array2table(fly_data, 'VariableNames', {'Acclim_off', 'Acclim_patt', 'Cond1', 'Cond2', 'Cond3', 'Cond4', 'Cond5', 'Cond6', 'Cond7', 'Cond8', 'Cond9', 'Cond10', 'Cond11', 'Cond12'});

% Meas = table([1 2 3 4 5 6 7 8 9 10]', 'VariableNames', {'Condition'});
% Define within-subject factor with categorical condition labels
Meas = table(categorical({'Acclim_off', 'Acclim_patt','Cond5', 'Cond6', 'Cond7', 'Cond8', 'Cond9','Cond10', 'Cond11', 'Cond12'}'), 'VariableNames', {'Condition'});

rm = fitrm(T, 'Acclim_off-Cond12 ~ 1', 'WithinDesign', Meas);
ranovaResults = ranova(rm);



data = [1,5,6,9,6; 22, 4, 16, 1, 8; 22, 4, 3, 9, 10];
T = array2table(data, 'VariableNames', {'Cond1', 'Cond2', 'Cond3', 'Cond4', 'Cond5'});
Meas = table([1 2 3 4 5]', 'VariableNames', {'Condition'});
rm = fitrm(T, 'Cond1-Cond5 ~ 1', 'WithinDesign', [1,2,3,4,5]);
ranovaResults = ranova(rm);


% % Set random seed for reproducibility
% rng(0);
% 
% % Generate random behavioral data for 60 flies across 12 conditions
% numFlies = 60;
% numConditions = 12;
% data = randn(numFlies, numConditions) + (1:numConditions); % Random data with slight trend
% 
% % Convert to a table and name the columns as conditions
% T = array2table(data, 'VariableNames', {'Cond1', 'Cond2', 'Cond3', 'Cond4', 'Cond5','Cond6', 'Cond7', 'Cond8', 'Cond9', 'Cond10', 'Cond11', 'Cond12'});
% 
% % Define the within-subject factor as categorical conditions
% Meas = table(categorical({'Cond1', 'Cond2', 'Cond3', 'Cond4','Cond5', 'Cond6', 'Cond7', 'Cond8', 'Cond9', 'Cond10', 'Cond11', 'Cond12'}'),'VariableNames', {'Condition'});
% 
% % Fit the repeated measures model
% rm = fitrm(T, 'Cond1-Cond12 ~ 1', 'WithinDesign', Meas);
% 
% % Run repeated measures ANOVA
% ranovaResults = ranova(rm);
% disp(ranovaResults);


















