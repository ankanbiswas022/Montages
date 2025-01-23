function M1_XYZ = prepareM1XYZfromBvef(captype, configOptions)
% prepareM1XYZfromBvef Prepare electrode positions from .Bvef file 
% Usage:
%   M1_XYZ = prepareM1XYZfromBvef(captype)
%   M1_XYZ = prepareM1XYZfromBvef(captype, configOptions)
%
% Description:
%   This function reads electrode positions from a .bvef file and prepares a master Table
%   By default, Y coordinates are saved first after negation.
%
% Inputs:
%   captype       - String specifying the cap type (default: 'actiCap64_UOL')
%   configOptions - Optional struct with configuration parameters:
%                  .capSerialNumCode - Cap serial number code (default: 'CMA')
%                  .numChanCap      - Number of channels (default: '64')
%                  .refFlag         - Reference flag (default: 'REF')
%                  .fileType        - File extension (default: '.bvef')
%                  .yFirst          - Save Y coordinate first (default: 1)
%                  .negateY         - Negate Y coordinate (default: 1)
%
% Output:
%   M1_XYZ - Cell array containing electrode labels and their XYZ coordinates
%
% File Output:
%   Saves 'M1_XYZ_[captype].mat' in the Montages folder
%
% Dependencies:
%   - 'loadbvef' function from the bva-io plugin in EEGLAB
%   - Montages folder must be in MATLAB path (with Subdirectories)
%
% Example:
%   % Use default settings
%   M1_XYZ = prepareM1XYZfromBvef('actiCap64');
%
%   % Custom configuration
%   config.yFirst = 0;
%   config.negateY = 0;
%   M1_XYZ = prepareM1XYZfromBvef('actiCap64', config);
%
% See also: loadbvef
%
% Author: Ankan Biswas
% Version: 1.0 (2024-01-23)

% Handle default captype
if ~exist('captype', 'var')
    captype = 'actiCap64_UOL';
end

% Handle configuration
if ~exist('configFile', 'var') || isempty(configOptions)
    % Use default configuration
    config = defaultBvefConfig();
elseif isstruct(configOptions)
    % Use provided struct with defaults for missing fields
    defaultConfig = defaultBvefConfig();
    config = mergeConfigs(configOptions, defaultConfig);
else
    error('Invalid configuration input');
end

% Check if Montages folder exists
if ~exist('Montages', 'dir')
    disp('Please add the Montages folder to the Matlab path');
else
    folderMontage = fullfile(pwd,'Montages');
end

% Construct filename using configuration
fileName = sprintf('%s-%s_%s%s', ...
    config.capSerialNumCode, ...
    config.numChanCap, ...
    config.refFlag, ...
    config.fileType);

% Verify file exists
assert(exist(fileName, 'file') > 0, 'BVEF file not found within the Layout folder');

% Check if output file already exists
baseSaveFileName = 'M1_XYZ';
saveFileName = fullfile(folderMontage, [baseSaveFileName '_' captype '.mat']);

if exist(saveFileName, 'file')
    fprintf('Loading existing M1_XYZ file for %s...\n', captype);
    data = load(saveFileName);
    M1_XYZ = data.M1_XYZ;
    return;
end

% If file doesn't exist, continue with file creation
fprintf('Creating new M1_XYZ file for %s...\n', captype);

% Load and validate data
tmp = loadbvef(fileName);
assert(~isempty(tmp), 'Failed to load BVEF file or file is empty');

% Remove REF and GND channels
validChannels = ~strcmp({tmp.labels}, 'GND') & ~strcmp({tmp.labels}, 'REF');
tmp = tmp(validChannels);

% Create coordinate matrix based on configuration
coords = [tmp.X ;tmp.Y; tmp.Z]';
if config.negateY
    coords(:,2) = -coords(:,2);
end

% Arrange coordinates based on yFirst option
if config.yFirst
    coordOrder = [2 1 3];  % Y, X, Z
else
    coordOrder = [1 2 3];  % X, Y, Z
end
coords = coords(:,coordOrder);

% Create output structure
M1_XYZ = [{tmp.labels}' num2cell(coords)];

% Save results with original naming convention
save(saveFileName, 'M1_XYZ');
end

%%%%%%%%%%%%%%%%%%%% Helper functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function config = mergeConfigs(userConfig, defaultConfig)
% Helper function to merge configurations
config = defaultConfig;
fields = fieldnames(userConfig);
for i = 1:length(fields)
    if isfield(defaultConfig, fields{i})
        config.(fields{i}) = userConfig.(fields{i});
    end
end
end

function config = defaultBvefConfig()
    % Default configuration for BVEF file parameters
    config = struct();
    config.capSerialNumCode = 'CMA';
    config.numChanCap = '64';
    config.refFlag = 'REF';
    config.fileType = '.bvef';
    config.yFirst = 1;        % 1 = Y coordinate first, 0 = X coordinate first
    config.negateY = 1;       % 1 = negate Y coordinate, 0 = keep original
end


