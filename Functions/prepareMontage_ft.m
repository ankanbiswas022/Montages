function elec = prepareMontage_ft(captype, displayFlag, rotationFlag, angles)
% prepareMontage_ft Convert and prepare EEG cap montage to FieldTrip format
%
% Usage:
%   elec = prepareMontage_ft(captype)
%   elec = prepareMontage_ft(captype, displayFlag)
%   elec = prepareMontage_ft(captype, displayFlag, rotationFlag)
%   elec = prepareMontage_ft(captype, displayFlag, rotationFlag, angles)
%
% Description:
%   This function converts EEG electrode positions to FieldTrip format and
%   prepares them for source analysis. It handles coordinate transformations,
%   unit conversions, and optional 3D rotations. The function first checks
%   for existing formatted files before creating new ones.
%
% Input Arguments:
%   captype     - String, specifies cap type (default: 'actiCap64')
%   displayFlag - Boolean, enable visualization (default: true)
%   rotationFlag- Boolean, apply rotation (default: false)
%   angles      - [rx ry rz] rotation angles in degrees (default: [0 0 0])
%
% Output:
%   elec        - FieldTrip electrode structure containing:
%                 .label    - Channel labels
%                 .chanpos  - Channel positions [Nx3]
%                 .elecpos  - Electrode positions [Nx3]
%                 .unit     - Units of positions (converted to 'mm')
%
% File Requirements:
%   - [captype]Labels.mat  - Channel label information
%   - [captype].mat        - Channel location information
%   Both files must be in: Montages/Layouts/[captype]/
%
% Created Files:
%   - [captype]_ft.mat     - FieldTrip formatted electrode positions
%   Saved in: Montages/Layouts/[captype]/
%
% Example:
%   % Basic usage with default settings
%   elec = prepareMontage_ft('actiCap64');
%
%   % With rotation
%   elec = prepareMontage_ft('actiCap64', true, true, [0 0 90]);
%
% Notes:
%   - Converts coordinates to millimeters (mm)
%   - Supports 3D rotation via rotation matrices
%   - Includes visualization options
%   - Caches formatted montages for reuse
%
% Dependencies:
%   - FieldTrip toolbox (for visualization)
%   - Montages folder structure
%
% See also: ft_convert_units, ft_plot_sens
%
% Author: Ankan Biswas
% Version: 1.0 (2024-01-23)

% Handle input arguments
if nargin < 1 || isempty(captype)
    captype = 'actiCap64_UOL';
end
if nargin < 2 || isempty(displayFlag)
    displayFlag = true;
end
if nargin < 3 || isempty(rotationFlag)
    rotationFlag = false;
end
if nargin < 4
    angles = [0 0 0];
end

if ~exist('Montages', 'dir')
    disp('Please add the Montages folder to the Matlab path');
else
    folderMontage = fullfile(pwd,'Montages','Layouts',captype);
end

% Check if FieldTrip formatted file already exists
ftFile = fullfile(folderMontage, sprintf('%s_ft.mat', captype));
if exist(ftFile, 'file')
    fprintf('Loading existing FieldTrip formatted file: %s\n', ftFile);
    % Load existing file
    tmp = load(ftFile);
    elec = tmp.elec;
    
    % Apply rotation if requested
    if rotationFlag
        elec = rotateElectrodes(elec, angles);
    end
    
    % Display if requested
    if displayFlag
        plotElectrodes(elec, captype, rotationFlag, angles);
    end
    
    return;
end

% If file doesn't exist, continue with file creation
fprintf('Creating new FieldTrip formatted file for %s...\n', captype);

% Validate angles if rotation is requested
if rotationFlag
    % Convert angles to numeric array if needed
    if ischar(angles) || isstring(angles)
        angles = str2double(angles); 
    end

    % Ensure angles is a 1x3 numeric array
    if ~isnumeric(angles) || numel(angles) ~= 3
        error('Angles must be a numeric array with 3 elements [rx ry rz]');
    end

    % Ensure angles is a row vector
    angles = angles(:)';
end

% Load channel labels and locations
try
    % Construct paths for captype-specific files
    labelsFile = fullfile(folderMontage, [captype 'Labels.mat']);
    chanlocsFile = fullfile(folderMontage, [captype '.mat']);
    
    % Check if files exist
    if ~exist(labelsFile, 'file')    % Changed ! to ~
        error('Labels file not found: %s', labelsFile);
    end
    if ~exist(chanlocsFile, 'file')  % Changed ! to ~
        error('Channel locations file not found: %s', chanlocsFile);
    end
    
    % Load files
    labels = load(labelsFile);
    chanlocs = load(chanlocsFile);
catch ME
    error('Failed to load channel files for %s: %s', captype, ME.message);
end

% Extract XYZ coordinates
numChannels = length(chanlocs.chanlocs);
clocs = zeros(numChannels, 3);
dimLabels = 'XYZ';

for dim = 1:3
    for e = 1:numChannels
        clocs(e,dim) = chanlocs.chanlocs(e).(dimLabels(dim));
    end
end

% Create electrode structure
elec = [];
elec.label = labels.montageLabels(:,2);
elec.chanpos = clocs;
elec.elecpos = clocs;
elec.chantype = repmat({'eeg'}, numChannels, 1);
elec.type = 'eeg1010';
elec.unit = 'cm';

% Convert to millimeters
elec = ft_convert_units(elec, 'mm');

% Apply rotation if requested
if rotationFlag
    elec = rotateElectrodes(elec, angles);
end

% Save the FieldTrip montage
saveName = fullfile(folderMontage, sprintf('%s_ft.mat', captype));
save(saveName, 'elec');
fprintf('FieldTrip montage saved as: %s\n', saveName);

if displayFlag
    plotElectrodes(elec, captype, rotationFlag, angles);
end
end

% Create helper function at end of file for plotting
function plotElectrodes(elec, captype, rotationFlag, angles)
    if ~exist('ft_defaults', 'file')    % Changed ! to ~
        error('FieldTrip not found. Please add to MATLAB path');
    end
    
    % Create figure with enhanced properties
    figure('Color', 'w', ...
                'Name', sprintf('Electrode Positions - %s', strrep(captype, '_', ' ')), ...
                'Position', [100 100 800 600]);
            
    % Plot electrodes with enhanced appearance
    ft_plot_sens(elec, ...
        'elecshape', 'sphere', ...
        'label', 'on', ...
        'facecolor', [0.2 0.7 0.3], ...  % Green color
        'fontsize', 10, ...
        'elecsize', 4);                   % Larger electrode markers
    
    % Set visualization properties
    material dull;
    lighting gouraud;
    camlight('headlight');
    
    % Add title with proper formatting
    if rotationFlag
        title({sprintf('Electrode positions for %s', strrep(captype, '_', ' ')), ...
               sprintf('Rotation: [%.1f° %.1f° %.1f°]', rad2deg(angles))}, ...
              'FontWeight', 'bold', ...
              'FontSize', 12);
    else
        title(sprintf('Electrode positions for %s', strrep(captype, '_', ' ')), ...
              'FontWeight', 'bold', ...
              'FontSize', 12);
    end
    
    % Enhanced axis properties
    rotate3d on;
    grid on;
    axis equal;
    set(gca, 'GridAlpha', 0.2, ...
            'LineWidth', 1.2, ...
            'Box', 'on');
end

function elec = rotateElectrodes(elec, angles)
    % Convert angles to radians
    angles = double(deg2rad(angles(:)'));
    
    try
        % Create rotation matrices with proper formatting
        Rx = [1, 0, 0; 
             0, cos(angles(1)), -sin(angles(1)); 
             0, sin(angles(1)), cos(angles(1))];
        
        Ry = [cos(angles(2)), 0, sin(angles(2)); 
             0, 1, 0; 
             -sin(angles(2)), 0, cos(angles(2))];
        
        Rz = [cos(angles(3)), -sin(angles(3)), 0; 
             sin(angles(3)), cos(angles(3)), 0; 
             0, 0, 1];
        
        % Combined rotation matrix
        R = Rz * Ry * Rx;
        
        % Apply rotation with proper matrix operations
        elec.chanpos = (R * elec.chanpos.').';
        elec.elecpos = (R * elec.elecpos.').';
    catch ME
        error('Rotation calculation error: %s', ME.message);
    end
end