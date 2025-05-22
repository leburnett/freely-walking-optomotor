function [pvals_all, target_mean_all, control_mean_all, strain_names] = make_pvalue_heatmap_across_strains(DATA, condition_n)

    % List all of the strains
    strain_names = fieldnames(DATA);
    
    % Remove the control strain from the list
    control_strain = "jfrc100_es_shibire_kir";
    strain_names(strcmp(strain_names, control_strain)) = [];
    
    n_strains = height(strain_names);
    
    % Initialise empty arrays:
    pvals_all = zeros(n_strains, 38);
    target_mean_all = zeros(n_strains, 38);
    control_mean_all = zeros(n_strains, 38);
    
    for strain_id = 1:n_strains

        strain = strain_names{strain_id};
        disp(strain)

        [pvals, target_mean, control_mean] = make_pvalue_array_per_condition(DATA, strain, condition_n);

        pvals_all(strain_id, :) = pvals;
        target_mean_all(strain_id, :) = target_mean;
        control_mean_all(strain_id, :) = control_mean;
    end 

end 