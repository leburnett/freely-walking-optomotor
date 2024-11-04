%Protocol_v10_all_tests.m - testing spatial frequencies, speed, and trial lengths in
%one big protocol
clear 

tic

%% Input parameters:

% [16, 2]; 1 Hz
% [32, 4]; 2 Hz
% [64, 8]; 4 Hz
% [127, 16]; 8 Hz

%% THESE ARE THE ONES THAT CHANGE IN EACH TRIAL
% optomotor_speed = 127; % 64 = baseline % in frames per second
% flicker_speed = 16;
%%%%%%%%%

% initialize temp recording
d = daq("ni");

ch1 = addinput(d,"cDAQ1Mod1","ai0","Thermocouple");
ch1.Name = "outside_probe";
ch1.ThermocoupleType = "K";

ch2 = addinput(d,"cDAQ1Mod1","ai1","Thermocouple");
ch2.Name = "ring_probe";
ch2.ThermocoupleType = "K";

d.Rate = 2;

% These parameters will be saved in the log file. 
fly_strain = 'csw1118';
fly_age = 5; % days
fly_sex = 'F';
n_flies = 15;
lights_ON = datetime('20:00', 'Format', 'HH:mm');
lights_OFF = datetime('12:00', 'Format', 'HH:mm');
arena_temp = 28.0;

% Protocol parameters: 
t_acclim = 20; %% 20
num_conditions = 8; %% 8
t_pause = 0.015;

% All conditions 
all_conditions = [
    4, 5, 64, 8, 2, 1;
    4, 5, 127, 16, 15, 2;
    4, 5, 64, 8, 15, 3;
    4, 5, 127, 16, 2, 4;
    6, 7, 64, 8, 2, 5; 
    6, 7, 127, 16, 15, 6;
    6, 7, 64, 8, 15, 7;
    6, 7, 127, 16, 2, 8
];

% initialize optomotor_pattern and flicker pattern with 1 and 2
% optomotor_pattern = 1; 
% flicker_pattern = 2;

%% Protocol name
func_name = string(mfilename());

%% SD card pattern information
% load('C:\MatlabRoot\Patterns\patterns_oaky\SD_copy.mat', 'SD');
% patterns = SD.pattern.pattNames;
% % cell array with the name of the patterns used.
% pattern_names = patterns(optomotor_pattern: flicker_pattern);

%% block of initializations

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
project_data_folder = 'C:\MatlabRoot\FreeWalkOptomotor\data';

date_folder = fullfile(project_data_folder, string(date_str));
if ~isfolder(date_folder)
    mkdir(date_folder)
end 

protocol_folder = fullfile(date_folder, func_name);
if ~isfolder(protocol_folder)
    mkdir(protocol_folder)
end

strain_folder = fullfile(protocol_folder, fly_strain);
if ~isfolder(strain_folder)
    mkdir(strain_folder)
end

sex_folder = fullfile(strain_folder, fly_sex);
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
LOG.meta.date = date_str;
LOG.meta.time = time_str;
LOG.meta.func_name = func_name;
LOG.meta.fly_strain = fly_strain;
LOG.meta.fly_age = fly_age;
LOG.meta.fly_sex = fly_sex;
LOG.meta.n_flies = n_flies;
LOG.meta.lights_ON = lights_ON;
LOG.meta.lights_OFF = lights_OFF;
LOG.meta.arena_temp= arena_temp;

% Pattern settings
controller_mode = [0 0]; % double open loop
% idx_value = 1;
% sz = [((num_trials_per_block*num_directions)*num_reps)+num_flickers+num_acclim, 7];
% 
% varTypes = {'double', 'double','double','double','double','double','double'};
% varNames = {'trial', 'contrast', 'dir', 'start_t', 'start_f', 'stop_t', 'stop_f'};
% Log = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

%% get start temperature
cDAQ1Mod1_1 = read(d,seconds(1));

start_temp_outside = cDAQ1Mod1_1.outside_probe(1); 
start_temp_ring = cDAQ1Mod1_1.ring_probe(1); 

%% start camera
vidobj.startCapture();
disp('camera ON')
pause(t_pause)
% Record the behaviour of the flies without any lights on in the arena
% before running the stimulus. 

%% get start temperature
cDAQ1Mod1_1 = read(d,seconds(1));

start_temp_outside = cDAQ1Mod1_1.outside_probe(1); 
start_temp_ring = cDAQ1Mod1_1.ring_probe(1); 

%% create random number order of the conditions
random_order = randperm(num_conditions);
display (random_order);

%% % ACCLIM OFF

acclim_off1.condition = 0;
acclim_off1.dir = 0;

Panel_com('all_off'); pause(t_pause)

% % get frame and log it
acclim_off1.start_t = vidobj.getTimeStamp().value;
acclim_off1.start_f = vidobj.getFrameCount().value;

disp('Acclim OFF')
pause(t_acclim); 

% get frame and log it 
acclim_off1.stop_t = vidobj.getTimeStamp().value;
acclim_off1.stop_f = vidobj.getFrameCount().value;

LOG.acclim_off1 = acclim_off1;


%% Present stimuli
log_n = 1;

% Run through all 8 conditions twice
for j = [1,2] 

    %start LOOP
     for i = 1:num_conditions
         % get the current condition
         current_condition = random_order(i);
         disp (current_condition);

         if j == 1 && i == 1

            optomotor_pattern = all_conditions(current_condition, 1);
             
            % % ACCLIM PATT
            disp('Pattern ON')
            pause(t_pause)
            acclim_patt.condition = random_order(1);
            acclim_patt.optomotor_pattern = optomotor_pattern;
            acclim_patt.dir = 0;
            acclim_patt.start_t = vidobj.getTimeStamp().value;
            acclim_patt.start_f = vidobj.getFrameCount().value;
            
            Panel_com('set_mode',controller_mode); pause(t_pause)
            Panel_com('set_pattern_id', optomotor_pattern); pause(t_pause)
            Panel_com('set_position', [1 1]); pause(t_pause)
            pause(t_acclim); 
            acclim_patt.stop_t = vidobj.getTimeStamp().value;
            acclim_patt.stop_f = vidobj.getFrameCount().value;

            LOG.acclim_patt = acclim_patt;
            disp('Acclim ended')

         end 
    
        Log = present_optomotor_stimulus(current_condition, all_conditions, vidobj);
        % Add the 'Log' from each condition to the overall log 'LOG'.
        fieldName = sprintf('log_%d', log_n);
        LOG.(fieldName) = Log;

        log_n = log_n+1;
     end
end 


%% Acclim at the end 
% Record the behaviour of the flies without any lights on in the arena
% after running the stimulus. 

acclim_off2.condition = 0;
acclim_off2.dir = 0;

Panel_com('all_off'); pause(t_pause)

% % get frame and log it
acclim_off2.start_t = vidobj.getTimeStamp().value;
acclim_off2.start_f = vidobj.getFrameCount().value;

disp('Acclim OFF')
pause(t_acclim); 

% get frame and log it 
acclim_off2.stop_t = vidobj.getTimeStamp().value;
acclim_off2.stop_f = vidobj.getFrameCount().value;

LOG.acclim_off2 = acclim_off2;

% get end temp
cDAQ1Mod1_2 = read(d,seconds(1));

end_temp_outside = cDAQ1Mod1_2.outside_probe(1); 
end_temp_ring = cDAQ1Mod1_2.ring_probe(1); 


%% stop camera
vidobj.stopCapture();
disp('Camera OFF')

%% add parameters to LOG.meta
LOG.meta.start_temp_outside = start_temp_outside;
LOG.meta.start_temp_ring = start_temp_ring;
LOG.meta.end_temp_outside = end_temp_outside;
LOG.meta.end_temp_ring = end_temp_ring;

% LOG.meta = meta;


%% save LOG file
log_fname =  fullfile(exp_folder, strcat('LOG_', string(date_str), '_', t_str, '.mat'));
save(log_fname, 'LOG');
disp('Log saved')

% clear temp
clear d ch1

toc

