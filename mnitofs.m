function [S] = mnitofs_auto(fname)
% mnitofs
% Inputs
% fname = path to nii file in mni space
% clims = either 1 or two element array [min] or [min max]
% smoothdata = nii will be smoothed before with a gaussian filter of fwhm
% of this value
% hem = hemesphere 'lh' or 'rh'
% surfacetype = 'inflated' 'smoothwm'
% inflationstep = 1-6. minimum - maximum inflation
% Output p = handle to graphics object.
% Example p = mnitofs('/imaging/dp01/results/proj2/MSPinversion/VisMean_maggrad_All.nii',0.001,0,'lh','inflated')
%
% Written by Darren Price, CSLB,  2015

close all
S.hem = 'lh';
S = mnitofs_brain(S);


