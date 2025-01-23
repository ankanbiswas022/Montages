function alignElectrodes_ft(captype)
% alignElectrodes_ft Align EEG electrodes to a head surface using two-step process
%
% Usage:
%   alignElectrodes_ft(captype)
%
% Description:
%   This function performs electrode alignment in two steps:
%   1. Manual Interactive Alignment: User-guided positioning of electrodes
%   2. Surface Projection: Automatic projection onto the head surface
%   
%   The function first checks for existing aligned electrodes for the specific
%   headmodel type (local 'bnd' or FieldTrip's 'standard_bem'). If found, it
%   displays the existing alignment. If not, it performs the alignment process.
%
% Input:
%   captype - String, specifies the cap type (default: 'actiCap64')
%
% File Dependencies:
%   - bnd.mat: Local headmodel (if available)
%   - standard_bem.mat: FieldTrip default headmodel (fallback)
%   - [captype]_ft.mat: Input electrode positions
%
% Output Files:
%   - [captype]_ft_aligned_[headmodel].mat: Aligned electrode positions
%     where [headmodel] is either 'bnd' or 'standard_bem'
%
% Example:
%   alignElectrodes_ft()           % Uses default 'actiCap64'
%   alignElectrodes_ft('actiCap64')
%
% Notes:
%   - Uses local BEM mesh (bnd.mat) if available, otherwise uses FieldTrip template
%   - Maintains consistent units between electrodes and head surface
%   - Supports both manual positioning and automatic surface projection
%
% See also: ft_electroderealign, ft_prepare_mesh, ft_plot_sens
%
% Author: Ankan Biswas
% Version: 1.0 (2024-01-23)

% Handle input
if nargin < 1 || isempty(captype)
    captype = 'actiCap64';
end

% Load electrode file
elecFile = fullfile(pwd, 'Montages', 'Layouts', captype, [captype '_ft.mat']);
try
    elec_data = load(elecFile);
    elec = elec_data.elec;
catch 
    if strcmp(captype, 'actiCap64')
        warning('Default captype file not found, loading FieldTrip template...');
        [~, ftdir] = ft_version;
        template_file = fullfile(ftdir, 'template', 'electrode', 'standard_1020.elc');
        elec = ft_read_sens(template_file);
    else
        error('Could not load electrode file: %s', elecFile);
    end
end

% Create montage directory if it doesn't exist
montageDir = fullfile(pwd, 'Montages', 'Layouts', captype);
if ~exist(montageDir, 'dir')
    mkdir(montageDir);
end

% Check for existing aligned electrode file for the specific headmodel
if exist('bnd.mat', 'file')
    headmodelType = 'bnd';
else
    headmodelType = 'standard_bem';
end

% Try to load existing aligned electrodes
alignedFile = fullfile(montageDir, sprintf('%s_ft_aligned_%s.mat', captype, headmodelType));
if exist(alignedFile, 'file')
    % Load existing aligned electrodes
    fprintf('Loading existing aligned electrodes for %s with %s headmodel...\n', captype, headmodelType);
    alignedData = load(alignedFile);
    elec_aligned = alignedData.elec_aligned;

    % Load appropriate headmodel for visualization
    if strcmp(headmodelType, 'bnd')
        bndData = load('bnd.mat');
        scalp = bndData.bnd(3);
    else
        [~, ftdir] = ft_version;
        headmodel_file = fullfile(ftdir, 'template', 'headmodel', 'standard_bem.mat');
        headmodel = ft_read_headmodel(headmodel_file);
        scalp = headmodel.bnd(1);
    end

    % Display aligned electrodes in multiple views
    figure('Color', 'k', 'Position', [50 50 1500 800]);
    sgtitle('Previously Aligned Electrodes', 'Color', 'w', 'FontWeight', 'bold');

    % Setup views
    views = {[0 90], [-90 0], [180 0], [90 0], [-90 30], [0 0]};
    titles = {'Top View', 'Left View', 'Front View', 'Right View', 'Left-Tilted View', 'Back View'};

    for i = 1:6
        subplot(2,3,i);
        ft_plot_mesh(scalp, 'edgecolor', 'none', 'facecolor', [0.8 0.8 0.8], 'facealpha', 0.6);
        hold on;
        ft_plot_sens(elec_aligned, 'elecshape', 'sphere', 'label', 'on','facecolor', [0.2 0.7 0.3], 'elecsize', 4);
        material dull;
        lighting gouraud;
        camlight;
        view(views{i});
        title(titles{i}, 'Color', 'w');
    end

    % Print information
    fprintf('Displaying aligned electrodes from: %s\n', alignedFile);
    fprintf('Number of electrodes: %d\n', length(elec_aligned.label));
    return;
end

% If no aligned file exists, continue with regular alignment procedure
fprintf('No existing aligned electrodes found. Starting alignment procedure...\n');

% Try to load local headmodel first, fallback to default if not available
try
    if exist('bnd.mat', 'file')
        bndData = load('bnd.mat');
        scalp = bndData.bnd(3);  % Use scalp surface from local headmodel
        fprintf('Using local headmodel from bnd.mat\n');
    else
        % Load default headmodel from FieldTrip if local not found
        [~, ftdir] = ft_version;
        headmodel_file = fullfile(ftdir, 'template', 'headmodel', 'standard_bem.mat');
        headmodel = ft_read_headmodel(headmodel_file);
        scalp = headmodel.bnd(1);  % Use outer surface from standard headmodel
        fprintf('Using default FieldTrip headmodel\n');
    end
catch ME
    error('Failed to load any headmodel: %s', ME.message);
end

% Convert units if needed
if ~strcmp(elec.unit, scalp.unit)
    elec = ft_convert_units(elec, scalp.unit);
end

% Create main figure for all visualizations
figure('Color', 'k', 'Position', [50 50 1500 800]);
sgtitle('Electrode Alignment Process', 'Color', 'w', 'FontWeight', 'bold');

% Function to set common visualization properties
function setupPlot(scalp, electrodes, viewAngle, titleStr)
    % Plot scalp with enhanced appearance
    ft_plot_mesh(scalp, ...
        'edgecolor', 'none', ...
        'facecolor', [0.8 0.8 0.8], ...
        'facealpha', 0.6);
    hold on;
    
    % Plot electrodes with enhanced appearance
    ft_plot_sens(electrodes, ...
        'elecshape', 'sphere', ...
        'label', 'on', ...
        'facecolor', [0.2 0.7 0.3], ... % Green color
        'fontsize', 10, ...
        'fontweight', 'bold', ...
        'elecsize', 8);               % Larger electrode markers
    
    % Set visualization properties
    material dull;
    lighting gouraud;
    camlight('headlight');
    light('Position', [1 0.5 1], 'Style', 'local', 'Color', [1 0.9 0.8]);
    light('Position', [-1 0.5 1], 'Style', 'local', 'Color', [1 0.9 0.8]);
    
    % Set view and title
    view(viewAngle);
    title(titleStr, 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Enhance axes appearance
    set(gca, ...
        'Color', 'none', ...
        'GridColor', [1 1 1], ...
        'GridAlpha', 0.1, ...
        'LineWidth', 1.5);
    grid on;
end

% Initial state (top-left)
subplot(2,3,1);
setupPlot(scalp, elec, [0 90], 'Initial Position'); % top view

% Step 1: Manual Interactive Alignment
fprintf('\nStep 1: Manual Interactive Alignment\n');
fprintf('Please manually align the electrodes to approximate positions.\n');
fprintf('Use the interface to rotate, translate, and scale the electrode positions.\n');

cfg = [];
cfg.method = 'interactive';
cfg.headshape = scalp;
cfg.feedback = 'yes';

% Perform manual alignment
elec_manual = ft_electroderealign(cfg, elec);

% Show manual alignment result (top-middle and top-right)
% Side view
subplot(2,3,2);
setupPlot(scalp, elec_manual, [-90 0], 'After Manual Alignment (Side)'); % side view

% Top view
subplot(2,3,3);
setupPlot(scalp, elec_manual, [0 90], 'After Manual Alignment (Top)'); % top view

% Step 2: Project to Surface
fprintf('\nStep 2: Projecting electrodes to surface\n');

cfg = [];
cfg.method = 'project';
cfg.headshape = scalp;
cfg.feedback = 'yes';

% Perform projection alignment
elec_aligned = ft_electroderealign(cfg, elec_manual);

% Show final alignment result (bottom row)
% Front view
subplot(2,3,4);
setupPlot(scalp, elec_aligned, [180 0], 'Final Alignment (Front)'); % front view

% Side view
subplot(2,3,5);
setupPlot(scalp, elec_aligned, [-90 0], 'Final Alignment (Side)'); % side view

% Top view
subplot(2,3,6);
setupPlot(scalp, elec_aligned, [0 90], 'Final Alignment (Top)'); % top view

% Determine headmodel type for filename
if exist('bnd.mat', 'file')
    headmodelType = 'bnd';
else
    headmodelType = 'standard_bem';
end

% Save only final aligned electrodes with headmodel type in filename
saveName = fullfile(montageDir, sprintf('%s_ft_aligned_%s.mat', captype, headmodelType));
save(saveName, 'elec_aligned');

% Print information
fprintf('\nAlignment complete:\n');
fprintf('Aligned electrodes saved as: %s\n', saveName);
fprintf('Headmodel used: %s\n', headmodelType);
fprintf('Number of aligned electrodes: %d\n', length(elec_aligned.label));

end