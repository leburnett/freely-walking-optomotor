

% Statistical test:

%% 1 - Is there a difference WITHIN strains to the different stimulus
% parameters?

% Repeated measures ANOVA

% Example data structure with rows for each fly and columns for each speed
data = [
    response_fly1_speed1, response_fly1_speed2, response_fly1_speed3, response_fly1_speed4, response_fly1_speed5;
    response_fly2_speed1, response_fly2_speed2, response_fly2_speed3, response_fly2_speed4, response_fly2_speed5;
    % ...
];

% Convert the data into a table for repeated measures ANOVA
T = array2table(data, 'VariableNames', {'Speed1', 'Speed2', 'Speed3', 'Speed4', 'Speed5'});

% Define the repeated measures design
Meas = table([1 2 3 4 5]', 'VariableNames', {'Speed'});

% Perform repeated measures ANOVA
rm = fitrm(T, 'Speed1-Speed5 ~ 1', 'WithinDesign', Meas);
ranovaResults = ranova(rm);



%% 2 - Difference ACROSS fly strains to the same stimulus.

% One measurement per fly - One-way ANOVA

% Example data: responses and strains
responses = [...]; % vector of behavioral responses for all flies
strains = [...]; % corresponding vector of strain labels (categorical)

% Perform one-way ANOVA
[p, tbl, stats] = anova1(responses, strains);

% View results
disp(tbl);
% If significant, you can perform a post-hoc test to see which strains differ:
multcompare(stats);


% More than one measurement per fly - two-way mixed -design ANOVA

% Convert data to table format
T = array2table(data, 'VariableNames', {'Condition1', 'Condition2', 'Condition3'}); % Add columns as needed

% Add a column for the strain label
T.Strain = categorical(strains);

% Define the repeated measures design
Meas = table([1 2 3]', 'VariableNames', {'Condition'}); % Adjust as per your conditions

% Fit repeated measures model with strain as a between-subjects factor
rm = fitrm(T, 'Condition1-Condition3 ~ Strain', 'WithinDesign', Meas);
ranovaResults = ranova(rm, 'WithinModel', 'Condition*Strain');

% View results
disp(ranovaResults);


























