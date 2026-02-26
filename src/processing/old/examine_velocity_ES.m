% Inspect VELOCITY of empty split flies compared to CS w1118 flies during
% oaky-cokey experiments. 

% 25/09/24

%% 

% files_to_open = dir();
data = [];

for i = 1:numel(files_to_open)
    fname = files_to_open(i).name;
    load(fname)
    if i == 1
        data = data_to_use;
    elseif i > 1 && i<numel(files_to_open)
        data = horzcat(data, data_to_use(:, 2:end-1));
    elseif i == numel(files_to_open)
        data = horzcat(data, data_to_use(:, 2:end));
    end 

end 

%% OR 

fname = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/data/vel/ES_CS_velocity.mat';
load(fname)

%%
% data_es = data;
mean_es = nanmean(data_es(:, 2:end-1), 2);
median_es = nanmedian(data_es(:, 2:end-1), 2);
n_es = numel(data_es(1,:))-2;
sem_es = (nanstd(data_es(:, 2:end-1)')/sqrt(n_es))';
std_es = nanstd(data_es(:, 2:end-1)')';


%%
% data_cs = data;
mean_cs = nanmean(data_cs(:, 2:end-1), 2);
median_cs = nanmedian(data_cs(:, 2:end-1), 2);
n_cs = numel(data_cs(1,:))-2;
sem_cs = (nanstd(data_cs(:, 2:end-1)')/sqrt(n_cs))';
std_cs = nanstd(data_cs(:, 2:end-1)')';



%%
figure; 
plot(mean_cs, 'k')
hold on 
plot(mean_ES, 'r')

%% 

figure; 
for i = 2:105
plot(data_es(:, i));
hold on
end 
title('Empty split JFRC49')
xlabel('condition')
ylabel('velocity (mm s-1)')


figure; 
for i = 2:219
plot(data_cs(:, i));
hold on
end 
title('cs-w1118')
xlabel('condition')
ylabel('velocity (mm s-1)')

%% Mean + SEM

figure; 

y1 = [mean_cs-sem_cs]';
y2 = [mean_cs+sem_cs]';

y3 = [mean_es-sem_es]';
y4 = [mean_es+sem_es]';

x = [1:1:33]; 

% plot SEM for CS W1118
plot(x, y1, 'w', 'LineWidth', 1)
hold on
plot(x, y2, 'w', 'LineWidth', 1)
patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.125, 'EdgeColor', 'none')

% plot SEM for ES
plot(x, y3, 'w', 'LineWidth', 1)
hold on
plot(x, y4, 'w', 'LineWidth', 1)
patch([x fliplr(x)], [y3 fliplr(y4)], 'm', 'FaceAlpha', 0.125, 'EdgeColor', 'none')

plot(mean_cs, 'Color', 'k', 'LineWidth', 2);
hold on 
plot(mean_es, 'Color', 'm', 'LineWidth', 2);

xticks([1,2,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,32,33])
xticklabels({'OFF', 'ON', '0.11', '0.20', '0.33', '0.40', '0.56', '0.75', '1', 'FLICKER', '1', '0.75', '0.56', '0.40', '0.33', '0.20', '0.11', 'FLICKER', 'OFF'})
xtickangle(45)    

ylabel('Mean velocity (mm s-1)')
box off
ax = gca;
ax.TickDir = 'out';

%% Median + STD

figure; 

y1 = [median_cs-std_cs]';
y2 = [median_cs+std_cs]';

y3 = [median_es-std_es]';
y4 = [median_es+std_es]';

x = [1:1:33]; 

% plot CS W1118
plot(x, y1, 'w', 'LineWidth', 1)
hold on
plot(x, y2, 'w', 'LineWidth', 1)
patch([x fliplr(x)], [y1 fliplr(y2)], 'k', 'FaceAlpha', 0.125, 'EdgeColor', 'none')

% plot ES
plot(x, y3, 'w', 'LineWidth', 1)
hold on
plot(x, y4, 'w', 'LineWidth', 1)
patch([x fliplr(x)], [y3 fliplr(y4)], 'm', 'FaceAlpha', 0.125, 'EdgeColor', 'none')

plot(median_cs, 'Color', 'k', 'LineWidth', 2);
hold on 
plot(median_es, 'Color', 'm', 'LineWidth', 2);

xticks([1,2,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,32,33])
xticklabels({'OFF', 'ON', '0.11', '0.20', '0.33', '0.40', '0.56', '0.75', '1', 'FLICKER', '1', '0.75', '0.56', '0.40', '0.33', '0.20', '0.11', 'FLICKER', 'OFF'})
xtickangle(45)    

ylabel('Median velocity (mm s-1)')
box off
ax = gca;
ax.TickDir = 'out';
ylim([0 2.5])



%% Proportion of time < 2mm s-1

% path_to_vel_files = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/data/vel/protocol_v1/post-HM/ES_JFRC49';
path_to_vel_files = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/data/vel/protocol_v1/post-HM';
cd(path_to_vel_files)

vel_files = dir('*velocity*');
n_files = length(vel_files);
load(fullfile(vel_files(1).folder, vel_files(1).name), 'Log', 'feat');

data = feat.data(:, :, 1);

    if numel(data(1, :)) < 5200
        min_length = 5150;
    elseif numel(data(1, :)) < 6500
        min_length =6300;
    elseif numel(data(1, :)) < 14700
        min_length = 14500;
    elseif numel(data(1, :)) < 18900
        min_length = 18840;
    else 
        min_length = 5150;
    end 
    
    % Add mean 
    all_data = [];
    for ii = 1:n_files
        % Load the data
        load(fullfile(vel_files(ii).folder, vel_files(ii).name), 'feat');
        if vel_or_ang == "vel" % velocity
            data = feat.data(:, :, 1);
        elseif vel_or_ang == "ang" % ang velocity
            data = feat.data(:, :, 2);
        end 

        n_flies = size(data, 1);

        for jj = 1: n_flies
            dtt = data(jj, :);
            if numel(dtt)<min_length 
                continue
            else
                dtt = dtt(1:min_length);
                all_data = vertcat(all_data, dtt);
            end 
        end 
    end 

%% Empty split data
data_es = all_data;

%% CSw1118 data
data_cs = all_data;

%% Mean velocity per fly:
mean_data_es = mean(data_es, 2);
mean_data_cs = mean(data_cs, 2);

figure; histogram(mean_data_es, "BinEdges", [0:0.5:20], "Normalization", "probability"); 
hold on;  
histogram(mean_data_cs, "BinEdges", [0:0.5:20], "Normalization", "probability");

mean_es = mean(mean_data_es); % 4.3748
mean_cs = mean(mean_data_cs); % 5.0023

[h, p] = kstest2(mean_data_es, mean_data_cs); % NS p=0.1282
[p, h] = ranksum(mean_data_es, mean_data_cs); % sig - p = 0.0443

% - - - - - - CSw1118 have a higher mean velocity than the empty split flies. 

%% Variance in velocity per fly:

% ES
n_flies = size(data_es, 1);
var_data_es = zeros(n_flies, 1);
for i = 1:n_flies
    d = data_es(i, :);
    var_data_es(i, 1)=var(d);
end 

% CS
n_flies = size(data_cs, 1);
var_data_cs = zeros(n_flies, 1);
for i = 1:n_flies
    d = data_cs(i, :);
    var_data_cs(i, 1)=var(d);
end 

figure; histogram(var_data_es,"BinEdges", [0:25:275], "Normalization", "probability"); 
hold on; 
histogram(var_data_cs, "BinEdges", [0:25:275], "Normalization", "probability");

mean_var_es = mean(var_data_es); % 70.8
mean_var_cs = mean(var_data_cs); % 97.4

[h, p] = kstest2(var_data_es, var_data_cs); % Sig - P = 0.0092
[p, h] = ranksum(var_data_es, var_data_cs); % sig - p = 0.0017

% - - - - - - CSw1118 have a higher variance in their velocity than the empty split flies. 

%% Proportion of time spent < 22 mm s-1

% ES
n_flies = size(data_es, 1);
len_exp = size(data_es, 2); 
prop_data_es = zeros(n_flies, 1);
for i = 1:n_flies
    d = data_es(i, :);
    all_less_2 = find(d(d<2));
    prop_data_es(i, 1)=numel(all_less_2)/len_exp;
end 

% CS
n_flies = size(data_cs, 1);
len_exp = size(data_cs, 2); 
prop_data_cs = zeros(n_flies, 1);
for i = 1:n_flies
    d = data_cs(i, :);
    all_less_2 = find(d(d<2));
    prop_data_cs(i, 1)=numel(all_less_2)/len_exp;
end 

figure; histogram(prop_data_es, "BinEdges", [0:0.1:1], "Normalization", "probability"); 
hold on; 
histogram(prop_data_cs, "BinEdges", [0:0.1:1], "Normalization", "probability");

mean_prop_es = mean(prop_data_es); % 0.6085
mean_prop_cs = mean(prop_data_cs); % 0.5716

[h, p] = kstest2(prop_data_es, prop_data_cs); % Sig - P = 0.0033
[p, h] = ranksum(prop_data_es, prop_data_cs); % sig - p = 0.0102

% - - - - - - Empty split flies spend a great proportion of the experiment > 2mm s-1 than CSw1118 flies. 

%%






