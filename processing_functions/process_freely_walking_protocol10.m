function process_freely_walking_protocol10(date_to_analyze)

% process_freely_walking_protocol_10

% This script will make mean datapoints, process data_features, and
% process_freely walking data for each condition of the long protocol

close all
clear
clc

%% process_freely_walking_data_v10

%% enter correct date folder based on parameter
PROJECT_ROOT = 'C:\Users\deva\Documents\projects\oakey_cokey\';
data_path = fullfile(PROJECT_ROOT, 'data');
results_path = fullfile(PROJECT_ROOT, 'results');

date_folder = fullfile(data_path, date_to_analyze);

cd(date_folder);

protocol_folders = dir('*rotocol_*'); % gets all the protocol folders in this date
n_protocols = height(protocol_folders);

% if block to analyze just the protocol_10 differently

% display(protocol_folders);

% for loop for all of the protocols within one date folder
for proto_idx = 1:n_protocols
    protocol_to_analyze = protocol_folders(proto_idx).name;
    cd (fullfile(protocol_folders(proto_idx).folder, protocol_folders(proto.idx).name))
end
if (protocol_folders.name == 'Protocol_v10_all_tests')
    display('entered if');
    % conduct analysis on each condition separately
    protocol_to_a

end

display ('outside if');
