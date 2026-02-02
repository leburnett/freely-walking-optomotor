
%% Histograms and statistics - turning and centring. 

bw = 10;
alp = 0.4;

%% Turning data 

% % %  PLOT

% Group data
datapts = abs(cond_data_grp(:, 300:1200));
dp = mean(datapts');

figure
histogram(dp, 'BinWidth', bw, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', alp, 'Normalization','pdf', 'Orientation','horizontal');
hold on 

% Solo data
datapts_solo = abs(cond_data_solo(:, 300:1200));
dp_solo = mean(datapts_solo');

histogram(dp_solo, 'BinWidth', bw, 'FaceColor', [0.46 0.15 0.30], 'FaceAlpha', alp, 'Normalization','pdf', 'Orientation','horizontal');

ylim([-10 225])

box off
ax = gca;
ax.TickDir = "out";
ax.LineWidth = 1.2;
ax.FontSize = 18;

f=gcf;
f.Position=[620   438   207   450];

% % %  STATS

% from the same continuous distribution? 
[h, p] = kstest2(dp, dp_solo); % p = 0.1599

% Means of the two distributions?
disp(mean(dp))
disp(mean(dp_solo))

 % 140.1255
 %  145.6626

 % Difference in the means? 
 [p,h] = ranksum(dp, dp_solo); % 0.1611



%% Distance data - distance moved at the end. 

% Group data
datapts = cond_data_grp(:, 1170:1200);
dp = mean(datapts');

figure
histogram(dp, 'BinWidth', bw, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', alp, 'Normalization','pdf', 'Orientation','horizontal');
hold on 

% Solo data
datapts_solo = cond_data_solo(:, 1170:1200);
dp_solo = mean(datapts_solo');

histogram(dp_solo, 'BinWidth', bw, 'FaceColor', [0.46 0.15 0.30], 'FaceAlpha', alp, 'Normalization','pdf', 'Orientation','horizontal');


ylim([-120 100])

box off
ax = gca;
ax.TickDir = "out";
ax.LineWidth = 1.2;
ax.FontSize = 18;

f=gcf;
f.Position=[620   438   207   450];


% % %  STATS

% from the same continuous distribution? 
[h, p] = kstest2(dp, dp_solo); % p = 0.0326

% Means of the two distributions?
disp(mean(dp))
disp(mean(dp_solo))

  % -32.5989
  % -25.4898

% Difference in the means? 
[p,h] = ranksum(dp, dp_solo); % 0.2933






%% 
strain = "jfrc100_es_shibire_kir";
sex = 'F';
data = DATA.(strain).(sex);

%% Distance - - - - 
data_type = "dist_data";
rng = 1170:1200;

% 4 Hz 60 deg gratings
condition_n = 1;
cond_data = combine_timeseries_across_exp_check(data, condition_n, data_type);
cond_data = cond_data - cond_data(:, 300); % relative            
cond_data = cond_data(:, rng);
mean_data = nanmean(cond_data, 2);

% Static gratings:
condition_n  = 10;
cond_data_static = combine_timeseries_across_exp_check(data, condition_n, data_type);
cond_data_static = cond_data_static - cond_data_static(:, 300); % relative            
cond_data_static = cond_data_static(:, rng);
mean_data_static = nanmean(cond_data_static, 2);

alp = 0.4;
bw = 10;

% Histogram 
figure
histogram(mean_data_static, 'BinWidth', bw, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.8, 'Normalization','pdf', 'Orientation','horizontal');
hold on 
histogram(mean_data, 'BinWidth', bw, 'FaceColor', [31 120 180]/255, 'FaceAlpha', 0.4, 'Normalization','pdf', 'Orientation','horizontal');

ylim([-110 100])
xlim([0 0.015])

box off
ax = gca;
ax.TickDir = "out";
ax.LineWidth = 1.4;
ax.FontSize = 20;
ax.TickLength = [0.02 0.02];

f=gcf;
f.Position=[620   438   207   450];


% % %  STATS

% from the same continuous distribution? 
[h, p] = kstest2(mean_data, mean_data_static); % p = 1.3638e-34

% Means of the two distributions?
disp(nanmean(mean_data))
disp(nanmean(mean_data_static))

  % -35.4806
  %  -3.0208

% Difference in the means? 
[p,h] = ranksum(mean_data, mean_data_static); % 2.2708e-42




%% Distance - - - - 
data_type = "curv_data";
rng = 300:1200;

% 4 Hz 60 deg gratings
condition_n = 1;
cond_data = combine_timeseries_across_exp_check(data, condition_n, data_type);
cond_data(:, 750:1200) = cond_data(:, 750:1200)*-1;          
cond_data = cond_data(:, rng);
mean_data = nanmean(cond_data, 2);

% Static gratings:
condition_n  = 10;
cond_data_static = combine_timeseries_across_exp_check(data, condition_n, data_type);
cond_data_static(:, 750:1200) = cond_data_static(:, 750:1200)*-1;          
cond_data_static = cond_data_static(:, rng);
mean_data_static = nanmean(cond_data_static, 2);

alp = 0.4;
bw = 10;

% Histogram 
figure
histogram(mean_data_static, 'BinWidth', bw, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.8, 'Normalization','pdf', 'Orientation','horizontal');
hold on 
histogram(mean_data, 'BinWidth', bw, 'FaceColor', [31 120 180]/255, 'FaceAlpha', 0.4, 'Normalization','pdf', 'Orientation','horizontal');

ylim([-40 210])
xlim([0 0.042])

box off
ax = gca;
ax.TickDir = "out";
ax.LineWidth = 1.4;
ax.FontSize = 20;
ax.TickLength = [0.02 0.02];

f=gcf;
f.Position=[620   438   207   450];


% % %  STATS

% from the same continuous distribution? 
[h, p] = kstest2(mean_data, mean_data_static); % p = 1.3638e-34

% Means of the two distributions?
disp(nanmean(mean_data))
disp(nanmean(mean_data_static))

  % -35.4806
  %  -3.0208

% Difference in the means? 
[p,h] = ranksum(mean_data, mean_data_static); % 2.2708e-42





