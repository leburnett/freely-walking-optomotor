function plot_summary_fig_one_cond_one_fly(v_fly, Va, r_curvature, dist_d, a_c, a_c_arena, gain, flyId)
% Generate summary plot for one fly across one condition
% 10s interval before.
% 20s interval after. 
% Data not binned, but every frame.

figure; 
subplot(7,1,1)
plot(v_fly); 
xlim([0 1800])
title('Vf')
hold on 
plot([300 300], [min(v_fly) max(v_fly)], 'k', 'LineWidth', 0.5)
plot([1200 1200], [min(v_fly) max(v_fly)], 'k', 'LineWidth', 0.5)

subplot(7,1,2)
plot(Va(flyId, :)); 
xlim([0 1800])
title('Va')
hold on
plot([300 300], [min(Va(flyId, :)) max(Va(flyId, :))], 'k', 'LineWidth', 0.5)
plot([1200 1200], [min(Va(flyId, :)) max(Va(flyId, :))], 'k', 'LineWidth', 0.5)

subplot(7,1,3)
plot(r_curvature); 
xlim([0 1800])
title('r')
hold on 
plot([300 300], [min(r_curvature) max(r_curvature)], 'k', 'LineWidth', 0.5)
plot([1200 1200], [min(r_curvature) max(r_curvature)], 'k', 'LineWidth', 0.5)

subplot(7,1,4)
plot(dist_d(flyId, :)); 
xlim([0 1800])
title('Dist2C')
hold on 
plot([300 300], [min(dist_d(flyId, :)) max(dist_d(flyId, :))], 'k', 'LineWidth', 0.5)
plot([1200 1200], [min(dist_d(flyId, :)) max(dist_d(flyId, :))], 'k', 'LineWidth', 0.5)

subplot(7,1,5)
plot(a_c); 
xlim([0 1800])
title('Ac')
hold on 
plot([300 300], [min(a_c) max(a_c)], 'k', 'LineWidth', 0.5)
plot([1200 1200], [min(a_c) max(a_c)], 'k', 'LineWidth', 0.5)

subplot(7,1,6)
plot(a_c_arena); 
xlim([0 1800])
title('Ac-arena')
hold on 
plot([300 300], [min(a_c_arena) max(a_c_arena)], 'k', 'LineWidth', 0.5)
plot([1200 1200], [min(a_c_arena) max(a_c_arena)], 'k', 'LineWidth', 0.5)

subplot(7,1,7)
plot(gain); 
xlim([0 1800])
title('gain')
hold on 
plot([300 300], [min(gain) max(gain)], 'k', 'LineWidth', 0.5)
plot([1200 1200], [min(gain) max(gain)], 'k', 'LineWidth', 0.5)

f = gcf;
f.Position =[471    67   618   980];

end 

