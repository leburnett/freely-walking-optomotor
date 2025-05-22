function make_summary_heat_maps_p27()

    ROOT_DIR = '/Users/burnettl/Documents/Projects/oaky_cokey';
    
    % Move to the directory to where the results per experiment are saved:
    protocol_dir = fullfile(ROOT_DIR, 'results', 'protocol_27');
    cd(protocol_dir);

    DATA = comb_data_across_cohorts_cond(protocol_dir);

    for condition_n = 1:12

        %% Make summary heat map
        [pvals_all, target_mean_all, control_mean_all, strain_names] = make_pvalue_heatmap_across_strains(DATA, condition_n);
    
        plot_pval_heatmap(pvals_all, target_mean_all, control_mean_all, strain_names, condition_n);

    end 
end 