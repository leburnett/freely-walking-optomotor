% Extra code for freely walking experiments


% unique_contrasts = unique(data_to_use(:, 1));
% n_unique_contrasts = numel(unique_contrasts);
% 
% data = zeros(n_unique_contrasts, 1);
% 
% for j = 1:n_unique_contrasts
%     contr = unique_contrasts(j);
%     all_contrast = find(data_to_use(:, 1)==contr);
%     % Find the mean & abs.
%     data(j, 1) = mean(mean(abs(data_to_use(all_contrast, :))));
% end 
% 
% % Plot the figure
% figure;
% plot(unique_contrasts, data, 'k', 'LineWidth', 1.2)
% box off
% ax = gca;
% ax.TickDir = 'out';
% xlim([-0.05 1.25])
% ylim([-0.05, 1.5])
% ax.LineWidth = 1.5;
% ax.FontSize = 12;
% xlabel('Contrast')
% ylabel('Average abs ang vel')
% f = gcf;
% f.Position = [422   637   809   390];

%% Generate a scatter plot of the mean angular velocity for ONE fly for each contrast value.
% Each conditions (i.e. clockwise and anticlockwise) are plotted as separate points. 

% ALL CONDITIONS
% figure; scatter(Log.contrast, (datapoints), 300, 'k.')
% 
% % ONLY THE FIRST HALF 
% % figure; scatter(Log.contrast(1:17), abs(datapoints(1:17)), 300, 'k.')
% ax = gca;
% ax.TickDir = 'out';
% xlim([-0.05 1.05])
% ylim([-0.05, 2.5])
% ax.LineWidth = 1.5;
% ax.FontSize = 12;
% xlabel('Contrast')
% ylabel('Average abs ang vel')
% f = gcf;
% f.Position = [422   637   809   390];





