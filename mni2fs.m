function [S] = mni2fs(mnivol,varargin)
% Main wrapper for mni2fs
% Usage: S = mni2fs_auto(mnivol,hem)
% mnivol = path/filename.nii - a 3D NIFTI image in MNI space
% hem = 'lr' or 'rh' - left or right hemesphere
% try examples/run_example.m for customisations
% or type
% help mni2fs_brain
% help mni2fs_roi
% help mni2fs_overlay
% help mni2fs_light
% for more info.
% Written by Darren Price, CSLB, University of Cambridge, 2015
% https://github.com/dprice80/mni2fs for latest releases

% p = inputParser();
% 
% addRequired(p,'mnivol',@ischar);
% 
% validVals1 = {'def1', 'def2', 'var1in'};
% valvar1 = @(x) any(validatestring(x,validVals1));
% addOptional(p,'var1', 'def1', valvar1)
% 
% validVals2 = {'def1', 'def2', 'var2in'};
% valvar2 = @(x) any(validatestring(x,validVals2));
% addOptional(p,'var2', 'def2' ,valvar2)
% 
% parse(p,mnivol,varargin{:})

if nargin == 2
    clims_perc = 0.98;
    if strcmp(hem,'lh')
        viewangle = [-90 0];
    else
        viewangle = [90 0];
    end
end

if nargin == 3
    if strcmp(hem,'lh')
        viewangle = [-90 0];
    else
        viewangle = [90 0];
    end
end 

set(gcf,'color','k');

S = [];
S.hem = hem;
S.inflationstep = 6;
S.surfacetype = 'inflated';
S = mni2fs_brain(S);

S.mnivol = mnivol;

if length(clims_perc) == 2
    S.clims = clims_perc;
else
    S.clims_= clims_perc;
end

S = mni2fs_overlay(S);
view(viewangle)

mni2fs_lights
