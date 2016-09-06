% Example code to create montage files for unipolar and bipolar reference
% montages for actiCap64

% Initialise
clear; clc;
capType = 'actiCap64'; % 
maxChanKnown = 64; % 64 channels for actiCap64

% Add EEGLAB and Montages directory to path (optional)
addpath(genpath(fullfile(pwd,'toolboxes','eeglab12_0_2_5b')),'-begin'); rmpath(genpath(fullfile(pwd,'toolboxes','eeglab12_0_2_5b','functions','octavefunc')));
addpath(genpath(fullfile(pwd,'Montages')),'-begin');

% Unipolar montage
createMontageEEG(capType);

% Bipolar montage
createBipolarMontageEEG(capType,maxChanKnown);