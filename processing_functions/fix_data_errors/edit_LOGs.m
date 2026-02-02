%% edit_LOGs

%% edit LOGs if you forget to update fly_strain/fly_age/fly_sex/n-flies

% disclaimer: if you change fly_strain or fly_sex, make sure you manually
% edit the folders it exists in

% specify time folder
time_folder = 'C:\MatlabRoot\FreeWalkOptomotor\data\2024_10_22\protocol_10\csw1118\F\11_06_44';
cd(time_folder);

% load log_file

load("LOG_2024_10_22_11_06_44.mat"); % change this based on the file

% pick which one to use
% LOG.meta.fly_strain = 'new_strain';
% LOG.meta.fly_sex = 'new_sex';
% LOG.meta.fly_age = new_age_num;
% LOG.meta.n_flies = new_n_num;

% resave as LOG
save("LOG_2024_10_22_11_06_44.mat");
