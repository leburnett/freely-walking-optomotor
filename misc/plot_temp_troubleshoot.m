% Plot the temperature of the probes - troubleshooting

figure;
% temperatureFolder = 'C:\Users\deva\Documents\projects\oakey_cokey\temp-data';
% cd(temperatureFolder);
% load("DATAFRAME_protocol24_withpre-10min.mat");
% plot readings from each probe on the same chart
plot(cDAQ1Mod1_6.Time, cDAQ1Mod1_6.outside_arena);
% Error using  .  (line 229)
% Unrecognized table variable name 'outside_arena'.
hold on;
plot(cDAQ1Mod1_6.Time, cDAQ1Mod1_6.on_temp_ring);
plot(cDAQ1Mod1_6.Time, cDAQ1Mod1_6.under_glass_middle);
% add lines for where v10 starts
% v10_start = [seconds(550)];
% xline(v10_start, '-k', 'LineWidth', 1.5);
%
% v10_end = [seconds(2760)];
% xline(v10_end, '-k', 'LineWidth', 1.5);
hold off;
xlabel('Time (s)');
ylabel('Temp (degC)');
title('protocol18-no-heatring');
legend({'outside-arena', 'on-temp-ring', 'under-glass-middle'});
grid on