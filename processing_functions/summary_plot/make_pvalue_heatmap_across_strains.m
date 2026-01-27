function [pvals_all, target_mean_all, control_mean_all, strain_names] = make_pvalue_heatmap_across_strains(DATA, condition_n)
% The returned arrays are all of the size [n_strains, n_metrics]

    % List all of the strains
    % strain_names = fieldnames(DATA);
    % 
    % % Remove the control strain from the list
    % control_strain = "jfrc100_es_shibire_kir";
    % strain_names(strcmp(strain_names, control_strain)) = [];

    strain_names = load('/Users/burnettl/Documents/Projects/oaky_cokey/results/strain_names2.mat');
    strain_names = strain_names.strain_names;
    % n_strains = height(strain_names);

    % Add ES
    % strain_names{n_strains+1} = 'jfrc100_es_shibire_kir';
    % Add Norp - negative control
    % strain_names{n_strains+2} = 'NorpA_UAS_Norp_plus';

    n_strains = height(strain_names);
    n_metrics = 6; % This might change and need to be updated.
    
    % Initialise empty arrays:
    pvals_all = zeros(n_strains, n_metrics);
    target_mean_all = zeros(n_strains, n_metrics);
    control_mean_all = zeros(n_strains, n_metrics);
    
    for strain_id = 1:n_strains

        strain = strain_names{strain_id};
        disp(strain)

        % Return a [1 x n_metrics] array per condition
        [pvals, target_mean, control_mean] = make_pvalue_array_per_condition(DATA, strain, condition_n);

        % Combine these 1D arrays vertically.
        pvals_all(strain_id, :) = pvals;
        target_mean_all(strain_id, :) = target_mean;
        control_mean_all(strain_id, :) = control_mean;
    end 

end 