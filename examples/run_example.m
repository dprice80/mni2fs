clear all
close all
clc

% Replace the following path with the path to the mni2fs toolbox folder
toolboxpath = 'path/to/this/script/';
addpath(genpath(toolboxpath)) % will add all subfolders and dependencies

%% Simple Auto Wrapper - All Settings are at Default and Scaling is Automatic
close all
mni2fs_auto(fullfile(toolboxpath, 'examples/AudMean.nii'),'lh')

%% Plot both hemespheres
close all
mni2fs_auto(fullfile(toolboxpath, 'examples/AudMean.nii'),'lh')
mni2fs_auto(fullfile(toolboxpath, 'examples/AudMean.nii'),'rh')
view([40 30])

%% Plot ROI and Overlay
close all
figure('Color','k','position',[20 72 800 600])

% Load and Render the FreeSurfer surface
S = [];
S.hem = 'lh'; % choose the hemesphere 'lh' or 'rh'
S.inflationstep = 6; % 1 no inflation, 6 fully inflated
S = mni2fs_brain(S);

% Plot an ROI, and make it semi transparent
S.mnivol = fullfile(toolboxpath, 'examples/HOA_heschlsL.nii');
S.roicolorspec = 'm'; % color. Can also be a three-element vector
S.roialpha = 0.5; % transparency 0-1
S = mni2fs_roi(S); 

% Add overlay, theshold to 98th percentile
NIFTI = load_nii(fullfile(toolboxpath, 'examples/AudMean.nii')); % mnivol can be a NIFTI structure
S.mnivol = NIFTI;
S.clims_perc = 0.98; % overlay masking below 98th percentile
S = mni2fs_overlay(S); 
view([-90 0]) % change camera angle
mni2fs_lights % Dont forget to turn on the lights!
% Optional - lighting can be altered after rendering


%% Animate
close all
NII = load_nii('/imaging/dp01/results/Notts/GroupData/ThetaAllHealthyRel.nii');

% Load and Render the FreeSurfer surface
S = [];
S.hem = 'lh'; % choose the hemesphere 'lh' or 'rh'
S.inflationstep = 6; % 1 no inflation, 6 fully inflated
S = mni2fs_brain(S);
NIIframe1 = NII;
NIIframe1.img = NII.img(:,:,:,1);
    S.mnivol = NIIframe1;
    S.clims = 'auto'; % overlay masking below 98th percentile
    S.climstype = 'pos';
    S.interpmethod = 'cubic';
    S.colormap = 'jet';
    S = mni2fs_overlay(S);
    view([90 0]) % change camera angle
    mni2fs_lights
    pause(0.01)
    
    
    S.mnivol = NII;
    S.clims = 'auto'; % overlay masking below 98th percentile
    S.climstype = 'pos';
    S.interpmethod = 'cubic';
    S.colormap = 'jet';
    S.fps = 1000;
    S = mni2fs_update(S);
    view([90 0]) % change camera angle
    mni2fs_lights
    pause(0.01)
    % Optional - lighting can be altered after rendering





%% For high quality output 
% Try export_fig package included in this release
% When using export fig use the bitmap option 
export_fig('filename.bmp','-bmp')

%% OR TRY MYAA for improved anti-aliasing without saving
myaa

