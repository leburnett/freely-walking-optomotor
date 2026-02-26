function [LOG, vidobj, exp_folder, date_str, t_str, params] = initialize_video_and_folders(project_data_folder, func_name)

% These parameters will be saved in the log file. 
params = get_input_parameters();

% BIAS settings:
ip = '127.0.0.1';
port = 5010;
config_path = 'C:\MatlabRoot\FreeWalkOptomotor\bias_config_ufmf.json';

vidobj = SimpleBiasCameraInterface(ip, port);
vidobj.connect();
vidobj.getStatus();

% Get date and time
date_str = datetime('now','TimeZone','local','Format','yyyy_MM_dd');
time_str = datetime('now','TimeZone','local','Format','HH:mm:ss');

%% Save the data in date-folder -- protocol_folder -- strain_folder -- time_folder

date_folder = fullfile(project_data_folder, string(date_str));
if ~isfolder(date_folder)
    mkdir(date_folder)
end 

protocol_folder = fullfile(date_folder, func_name);
if ~isfolder(protocol_folder)
    mkdir(protocol_folder)
end

strain_folder = fullfile(protocol_folder, params.Strain);
if ~isfolder(strain_folder)
    mkdir(strain_folder)
end

sex_folder = fullfile(strain_folder, params.Sex);
if ~isfolder(sex_folder)
    mkdir(sex_folder)
end

t_str = strrep(string(time_str), ':', '_');
exp_folder = fullfile(sex_folder, t_str);
if ~isfolder(exp_folder)
    mkdir(exp_folder)
end 

exp_name = 'REC_';
v_fname =  fullfile(exp_folder, exp_name);

vidobj.enableLogging();
vidobj.loadConfiguration(config_path);
vidobj.setVideoFile(v_fname);

%% Add parameters to LOG_meta file. 
if func_name == "protocol_v5"
    LOG.date = date_str;
    LOG.time = time_str;
    LOG.func_name = func_name;
    LOG.fly_strain = params.Strain;
    LOG.fly_age = params.Age;
    LOG.fly_sex = params.Sex;
    LOG.light_cycle = params.LightCycle;
    LOG.experimenter = params.Experimenter;
    LOG.n_flies = params.nFlies;
else
    LOG.meta.date = date_str;
    LOG.meta.time = time_str;
    LOG.meta.func_name = func_name;
    LOG.meta.fly_strain = params.Strain;
    LOG.meta.fly_age = params.Age;
    LOG.meta.fly_sex = params.Sex;
    LOG.meta.light_cycle = params.LightCycle;
    LOG.meta.experimenter = params.Experimenter;
    LOG.meta.n_flies = params.nFlies;
end 

%  Add date and time str to params:
params.Date = string(date_str);
params.Time = strrep(string(time_str), ':', '-');
params.Protocol = func_name;

prompt = "Notes at start: ";
notes_str_start = input(prompt, 's');
params.NotesStart = notes_str_start;

end 