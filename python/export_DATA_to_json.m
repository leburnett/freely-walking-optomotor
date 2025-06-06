function export_DATA_to_json(DATA)

    % Convert struct to cell array of structs and save to JSON
    jsonStr = jsonencode(DATA);
    fid = fopen('DATA.json', 'w');
    fwrite(fid, jsonStr, 'char');
    fclose(fid);

end 