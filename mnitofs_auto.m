function [S] = mnitofs_auto(mnivol,hem)
% Simple wrapper for mnitofs
% Usage: S = mnitofs_auto(mnivol,hem)
% mnivol = path/filename.nii - a 3D NIFTI image in MNI space
% hem = 'lr' or 'rh' - left or right hemesphere
% try examples/run_example.m for customisations
% or type
% help mnitofs_brain
% help mnitofs_roi
% help mnitofs_overlay
% help mnitofs_light
% for more info.
% Written by Darren Price, CSLB, University of Cambridge, 2015
% https://github.com/dprice80/mnitofs for latest releases

set(gcf,'color','w');

S = [];
S.hem = hem;
S.inflationstep = 6;
S = mnitofs_brain(S);

S.mnivol = mnivol;
S.clims_perc = 0.98;
S = mnitofs_overlay(S);

if strcmp(S.hem, 'lh')
    view([-90 0])
else 
    view([90 0])
end

mnitofs_lights
