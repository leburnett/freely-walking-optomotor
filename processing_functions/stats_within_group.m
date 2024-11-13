
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

data_type = 'dist_data';

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

T1 = T(45:87, :);
T2 = T([1:44, 88:end], :);

T1 = rmmissing(T1, 2);
T2 = rmmissing(T2, 2);

Meas1 = table(categorical({'Acclim_off', 'Acclim_patt','Cond1', 'Cond2', 'Cond3', 'Cond4', 'Cond5', 'Cond6', 'Cond7', 'Cond8'}'), 'VariableNames', {'Condition'});

rm1 = fitrm(T1, 'Acclim_off-Cond8~ 1', 'WithinDesign', Meas1);
ranovaResults = ranova(rm1);

if ranovaResults.pValue < 0.05
    pairwiseResults = multcompare(rm1, 'Condition', 'ComparisonType', 'bonferroni'); % or 'tukey-kramer', 'sidak', etc.
end


Meas2 = table(categorical({'Acclim_off', 'Acclim_patt', 'Cond5', 'Cond6', 'Cond7', 'Cond8', 'Cond9', 'Cond10', 'Cond11', 'Cond12'}'), 'VariableNames', {'Condition'});

rm2 = fitrm(T2, 'Acclim_off-Cond12~ 1', 'WithinDesign', Meas2);
ranovaResults = ranova(rm2);

if ranovaResults.pValue < 0.05
    pairwiseResults = multcompare(rm2, 'Condition', 'ComparisonType', 'bonferroni'); % or 'tukey-kramer', 'sidak', etc.
end


















