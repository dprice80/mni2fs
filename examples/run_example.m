clear all
close all
clc

toolboxpath = 'setpath here';
addpath(genpath(toolboxpath)) % will add all subfolders and dependencies

%% Simple Auto Wrapper - All Settings are at Default and Scaling is Automatic
close all
mnitofs_auto(fullfile(toolboxpath, 'examples/AudMean.nii'),'lh')

%% Plot both hemespheres
close all
mnitofs_auto(fullfile(toolboxpath, 'examples/AudMean.nii'),'lh')
mnitofs_auto(fullfile(toolboxpath, 'examples/AudMean.nii'),'rh')
view([40 30])

%% Plot ROI and Overlay
close all
figure('Color','w','position',[20 72 800 600])

% Load and Render the FreeSurfer surface
S = [];
S.hem = 'lh'; % choose the hemesphere 'lh' or 'rh'
S.inflationstep = 6; % 1 no inflation, 6 fully inflated
S = mnitofs_brain(S);

% Plot an ROI, and make it semi transparent
S.mnivol = fullfile(toolboxpath, 'examples/HOA_heschlsL.nii');
S.roicolorspec = 'm'; % color. Can also be a three-element vector
S.roialpha = 0.5; % transparency 0-1
S = mnitofs_roi(S); 

% 
NIFTI = load_nii(fullfile(toolboxpath, 'examples/AudMean.nii')); % mnivol can be a NIFTI structure
S.mnivol = NIFTI;
S.clims_perc = 0.98; % overlay masking below 98th percentile
S = mnitofs_overlay(S); 
view([-90 0]) % change camera angle
mnitofs_lights % Dont forget to turn on the lights!
% Optional - lighting can be altered after rendering

%% For high quality output 
% Try export_fig package included in this release
% When using export fig use the bitmap option 
export_fig('filename.bmp','-bmp')

%% OR TRY MYAA for improved anti-aliasing without saving
myaa

