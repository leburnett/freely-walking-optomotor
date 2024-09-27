%Protocol_v10_all_tests.m - testing spatial frequencies, speed, and trial lengths in
%one big protocol
clear 

%% Input parameters:

% [16, 2]; 1 Hz
% [32, 4]; 2 Hz
% [64, 8]; 4 Hz
% [127, 16]; 8 Hz

%% THESE ARE THE ONES THAT CHANGE IN EACH TRIAL
% optomotor_speed = 127; % 64 = baseline % in frames per second
% flicker_speed = 16;
%%%%%%%%%

% These parameters will be saved in the log file. 
fly_strain = 'CS_w1118';
fly_age = 3; % days
fly_sex = 'F';
n_flies = 15;
lights_ON = datetime('20:00', 'Format', 'HH:mm');
lights_OFF = datetime('12:00', 'Format', 'HH:mm');
arena_temp = 24.3;

% Protocol parameters:
t_acclim = 5;
num_conditions = 8;

% All conditions 
all_conditions = [
    4, 5, 64, 8, 2;
    4, 5, 127, 16, 20;
    4, 5, 64, 8, 20;
    4, 5, 127, 16, 2;
    6, 7, 64, 8, 2; 
    6, 7, 127, 16, 20;
    6, 7, 64, 8, 20;
    6, 7, 127, 16, 2
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

t_str = strrep(string(time_str), ':', '_');
exp_folder = fullfile(strain_folder, t_str);
if ~isfolder(exp_folder)
    mkdir(exp_folder)
end 

exp_name = 'REC_';
v_fname =  fullfile(exp_folder, exp_name);

vidobj.enableLogging();
vidobj.loadConfiguration(config_path);
vidobj.setVideoFile(v_fname);

%% Add parameters to LOG_meta file. 
meta.date = date_str;
meta.time = time_str;
meta.func_name = func_name;
meta.fly_strain = fly_strain;
meta.fly_age = fly_age;
meta.fly_sex = fly_sex;
meta.n_flies = n_flies;
meta.lights_ON = lights_ON;
meta.lights_OFF = lights_OFF;
meta.arena_temp= arena_temp;

LOG.meta = meta;

% Pattern settings
controller_mode = [0 0]; % double open loop
% idx_value = 1;
% sz = [((num_trials_per_block*num_directions)*num_reps)+num_flickers+num_acclim, 7];
% 
% varTypes = {'double', 'double','double','double','double','double','double'};
% varNames = {'trial', 'contrast', 'dir', 'start_t', 'start_f', 'stop_t', 'stop_f'};
% Log = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

%% start camera
vidobj.startCapture();
disp('camera ON')
% Record the behaviour of the flies without any lights on in the arena
% before running the stimulus. 

%%%% BEGINNING NEW LOOP METHOD HERE
% want to choose a random experiment from a list of experiments

% create random number order of the conditions
random_order = randperm(num_conditions);
display (random_order);

%% % ACCLIM OFF
% initialize empty LOG_acclim_off
ao_idx_value = 1; % acclim off index value
sz = [1, 6];

varTypes = {'double','double','double','double','double','double'};
varNames = {'condition', 'dir', 'start_t', 'start_f', 'stop_t', 'stop_f'};
acclim_off = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

acclim_off.condition(1) = 0;



% Log.dir(idx_value) = 0;
% % get frame and log it
acclim_off.start_t(1) = vidobj.getTimeStamp().value;
acclim_off.start_f(1) = vidobj.getFrameCount().value;

Panel_com('all_off'); 
disp('Acclim OFF')
pause(t_acclim); 

% get frame and log it 
acclim_off.stop_t(1) = vidobj.getTimeStamp().value;
acclim_off.stop_f(1) = vidobj.getFrameCount().value;

LOG.acclim_off = acclim_off;


% initialize empty LOG_acclim_patt
sz = [1, 6];

varTypes = {'double','double','double','double','double','double'};
varNames = {'condition', 'dir', 'start_t', 'start_f', 'stop_t', 'stop_f'};
acclim_patt = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

acclim_patt.condition(1) = random_order(1);
%% Present stimuli

% Run through all 8 conditions twice
for j = [1,2] 

    %start LOOP
     for i = 1:num_conditions
         % get the current condition
         current_condition = random_order(i);
         disp (current_condition);

         if j == 1 && i == 1

            optomotor_pattern = all_conditions(current_condition, 1);
             % % ACCLIM ON
            % idx_value = idx_value+1; 
            % Log.trial(idx_value) = idx_value;
            % Log.dir(idx_value) = 0;
            disp('Pattern ON')

            % log LOG_acclim_patt
            acclim_patt.start_t(1) = vidobj.getTimeStamp().value;
            acclim_patt.start_f(1) = vidobj.getFrameCount().value;
            
            Panel_com('set_mode',controller_mode); pause(0.01)
            Panel_com('set_pattern_id', optomotor_pattern); pause(0.01)
            Panel_com('set_position', [1 1]); pause(0.01)
            pause(t_acclim); 

            acclim_patt.stop_t(1) = vidobj.getTimeStamp().value;
            acclim_patt.stop_f(1) = vidobj.getFrameCount().value;

            LOG.acclim_patt = acclim_patt;

            disp('Acclim ended')

         end 
    
        present_optomotor_stimulus(current_condition, all_conditions)
       
     end
end 




% first, build and define all experiments in an array where each experiment
% is a row and each parameter is a column



%% Acclim at the end 
% Record the behaviour of the flies without any lights on in the arena
% after running the stimulus. 
% ao_idx_value = ao_idx_value+1;

% % Log - for acclim
% Log.trial(idx_value) = idx_value;
% Log.dir(idx_value) = 0;
% % get frame and log it
% Log.start_t(idx_value) = vidobj.getTimeStamp().value;
% Log.start_f(idx_value) = vidobj.getFrameCount().value;
Panel_com('all_off'); 
disp('Acclim OFF')

pause(t_acclim); 

% % get frame and log it 
% Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
% Log.stop_f(idx_value) = vidobj.getFrameCount().value;


%% stop camera
vidobj.stopCapture();
disp('Camera OFF')


% Protocol name
% LOG.func_name = func_name;

% % Protocol parameters: %% log indivudually
% LOG.trial_len=trial_len;
% LOG.t_acclim=t_acclim;
% LOG.t_flicker=t_flicker;
% LOG.num_trials_per_block=num_trials_per_block;
% LOG.num_directions=num_directions; 
% LOG.num_reps=num_reps;
% LOG.num_flickers=num_flickers; 
% LOG.num_acclim=num_acclim; 
% 
% % Pattern settings
% LOG.optomotor_pattern=optomotor_pattern;
% LOG.flicker_pattern=flicker_pattern;
% LOG.optomotor_speed=optomotor_speed; % in frames per second
% LOG.flicker_speed = flicker_speed;
% LOG.pattern_names=pattern_names;
% 
% % Add log file of timings per condition
% LOG.Log = Log;
% 
% %% save LOG file
% log_fname =  fullfile(exp_folder, strcat('LOG_', string(date_str), '_', t_str, '.mat'));
% save(log_fname, 'LOG');
% disp('Log saved')
