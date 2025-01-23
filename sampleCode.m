% Example code to create montage files for unipolar and bipolar reference
% montages for actiCap64
% Note: Run the script from the 'D:\Programs\ProgramsMAP' folder
% Added codes to generate montage structure for fieldtrip

% Initialise
clear; clc;
capType = 'actiCap64_UOL'; % actiCap64_UOL
maxChanKnown = 64; % 64 channels for actiCap64

% Add EEGLAB and Montages directory to path (optional)
% addpath(genpath(fullfile(pwd,'toolboxes','eeglab12_0_2_5b')),'-begin'); rmpath(genpath(fullfile(pwd,'toolboxes','eeglab12_0_2_5b','functions','octavefunc')));
% addpath(genpath(fullfile(pwd,'Montages')),'-begin');

% Unipolar montage
createMontageEEG(capType);

% Bipolar montage
createBipolarMontageEEG(capType,maxChanKnown);

% example code to prepare montage for fieldtrip for actiCap64
captype = 'actiCap64';
displayFlag = 1;
rotationFlag = 1;
angles = [0 0 0];
elec = prepareMontage_ft(captype, displayFlag, rotationFlag, angles);
