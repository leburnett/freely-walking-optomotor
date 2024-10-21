function plot_all_logs_prot10(LOG, feat, trx, title_str)



% create figure and subplot formatting
figure;

cd('C:\Users\deva\Documents\projects\oakey_cokey\results\Protocol_v10_all_tests\CS_w1118')
LOG = load("2024_10_03_11_19_53_data.mat")






% % Loop to create 8 subplots
% for j = 1:19
%     subplot(8, 1, j);
% 
%     if j == 1
%         plot(ang_vel_data_per_cond_mean);
%         title('ang_vel_data_per_cond_med for log 1')
%     end
% 
% end