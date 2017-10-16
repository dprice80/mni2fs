function mni2fs_checkpaths

thisfolder = fileparts(mfilename('fullpath'));

V = ver('MATLAB');
if str2double(V.Version) < 8.1
    warning('The toolbox has not been tested in this version of Matlab. Please use a later version of matlab (preferably 2013a or later).')
end

if ~exist([thisfolder '/surf'],'dir')
    warning('SURF FOLDER NOT FOUND:')
    disp('Please download the support files (.zip) from')
    disp('<a href = "https://github.com/dprice80/mni2fs/releases/download/1.0.0/mni2fs_supportfiles.zip">https://github.com/dprice80/mni2fs/releases/</a>')
    error(['Surfaces not found'])
end

filecheck = true(3,1);

if ~exist('load_nii','file')
    filecheck(1) = false;
end
if ~exist('gifti','file')
    filecheck(2) = false;
end
if ~exist('freezeColors','file')
    filecheck(3) = false;
end

if any(filecheck == 0)
    addpath(genpath(thisfolder))
end 

if ~exist('load_nii','file')
    disp('Could not find the Nifti/Analyse toolbox containing load_nii.m.')
    disp('Please download and unpack the support files into the mni2fs toolbox folder:')
    disp('<a href="github.com/dprice80/mni2fs/releases">github.com/dprice80/mni2fs/releases</a>')
    error('Could not find nifti/analyse toolbox')
end

if ~exist('gifti','file')
    disp('Could not find the gifti toolbox containing gifti.m.')
    disp('Please download and unpack the support files into the mni2fs toolbox folder:')
    disp('<a href="github.com/dprice80/mni2fs/releases">github.com/dprice80/mni2fs/releases</a>')
    error('Could not find gifti toolbox')
end

if ~exist('freezeColors','file')
    disp('Could not find the freezeColors toolbox containing freezeColors.m.')
    disp('Please download and unpack the support files into the mni2fs toolbox folder:')
    disp('<a href="github.com/dprice80/mni2fs/releases">github.com/dprice80/mni2fs/releases</a>')
    error('Could not find freezeColors toolbox')
end