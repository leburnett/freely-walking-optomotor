function [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control)
% Vertically concatenate values
pvals = [pvals, p];
target_mean = [target_mean, mean_per_strain];
control_mean = [control_mean, mean_per_strain_control];
end 