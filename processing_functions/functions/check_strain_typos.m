function strain = check_strain_typos(strain)

    % 1 - Check for if the strain begins with a number:
    startsnum = isstrprop(strain(1), 'digit');
    if startsnum
        strain = strcat('ss', strain);
    end 

    if strain == "empty_split_kir"
        strain = "jfrc49_es_kir";
    end 

    if strain == "jfrc49_l1l4"
        strain = "jfrc49_l1l4_kir";
    end 

    if strain == "ss324_t4t5" || strain == "ss3234_t4t5_kir"
        strain = "ss324_t4t5_kir";
    end 

    if strain == "es_shibire"
        strain = "jfrc100_es_shibire";
    end 
end 



