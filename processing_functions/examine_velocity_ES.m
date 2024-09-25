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

%%
data_es = data;
mean_es = nanmean(data_es(:, 2:end-1), 2);
median_es = nanmedian(data_es(:, 2:end-1), 2);
n_es = numel(data_es(1,:))-2;
sem_es = (nanstd(data_es(:, 2:end-1)')/sqrt(n_es))';
std_es = nanstd(data_es(:, 2:end-1)')';


%%
data_cs = data;
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







