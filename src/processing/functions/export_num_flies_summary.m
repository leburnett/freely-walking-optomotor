function export_num_flies_summary(exp_data, save_folder)

    % Define the output file name
    output_filename = fullfile(save_folder, 'exp_strain_num_flies_summary.txt');
    
    % Open the file for writing (will overwrite if it already exists)
    fid = fopen(output_filename, 'w');
    
    % Write a header row
    fprintf(fid, 'Strain\tN_Vials\tN_Flies_Total\n');
    
    % Get all the strain names (fields of the struct)
    strain_names = fieldnames(exp_data);
    
    % Loop through each strain and write the data
    for i = 1:length(strain_names)
        strain = strain_names{i};
        n_vials = exp_data.(strain).n_vials;
        n_flies = exp_data.(strain).n_flies_total;
        
        % Write to file: strain name, n_vials, n_flies_total
        fprintf(fid, '%s\t%d\t%d\n', strain, n_vials, n_flies);
        % Print the numbers to the command window
        fprintf('%s\t%d\t%d\n', strain, n_vials, n_flies)
    end
    
    % Close the file
    fclose(fid);

end 