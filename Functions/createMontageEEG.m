%% createMontageEEG(capType)
% Function to create EEG location files for a given montage.
%
% Inputs:
% capType: this is a string containing the name of the montage whose 
%           location file has to be generated. e.g.: actiCap64
% Outputs:
% a channel location file is created that could be accessed by EEGLAB.
% the file is created in two formats: .xyz (accessed by EEGLAB) and 
% .mat format (could be readily given as input to my [MD] programs that use 
% topoplot function).
%
% This program uses readlocs and topoplot functions of EEGLAB toolbox.
%
% Created by Murty V P S Dinavahi (MD) 01-12-2015
%
function createMontageEEG(capType)

folderMontage = fullfile(pwd,'Montages');
load(fullfile(folderMontage,[capType 'Labels.mat']));
load(fullfile(folderMontage,'M1_XYZ.mat'));

for i = 1:size(montageLabels,1)
    elecIndex{i} = find(strcmp(montageLabels(i,2),M1_XYZ(:,1)));
    
    if ~isempty(elecIndex{i})
        chanlocs(i,1) = i;
        chanlocs(i,2) = M1_XYZ{elecIndex{i},2};
        chanlocs(i,3) = M1_XYZ{elecIndex{i},3};
        chanlocs(i,4) = M1_XYZ{elecIndex{i},4};
        chanlocs(i,5) = i;  
    else
        disp(['No coordinates for electrode number ' num2str(i) '. Hence Taking the coordinates of the unknown electrode somewhere outside the sphere!!']);
        % Takes the coordinates of the unknown electrodes somewhere outside the sphere.
        chanlocs(i,1) = i;
        chanlocs(i,2) = max([M1_XYZ{:,2}])*2;
        chanlocs(i,3) = max([M1_XYZ{:,3}])*2;
        chanlocs(i,4) = max([M1_XYZ{:,4}])*2;
        chanlocs(i,5) = i;
    end
end

save(fullfile(folderMontage,[capType '.xyz']),'chanlocs','-ASCII');
filename = fullfile(folderMontage,[capType '.xyz']);
clear chanlocs
chanlocs = readlocs( filename, 'importmode', 'native');
topoplot([],chanlocs,'style','blank','electrodes','numbers');
save(fullfile(folderMontage,[capType '.mat']),'chanlocs');
end

