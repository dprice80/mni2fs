%% Script to draw data onto any arbitrary surface.
% some FS functions in
% http://eeg.sourceforge.net/doc_m2html/bioelectromagnetism/index.html
% which might come in handy

clear

addpath /imaging/dp01/toolboxes/mni2fs_devel/mni2fs_singlesub_dp/
% addpath /imaging/dp01/toolboxes/freesurfer_tools/github_fs_matlab/
% addpath /imaging/dp01/toolboxes/freesurfer_tools/darren_sourceforge/
mni2fs_checkpaths

hems = {'lh' 'rh'};

for hemi = 1:2
    hem = hems{hemi};
    fs_subject_dir = '/imaging/dp01/toolboxes/mni2fs_devel/CC110033';
    % fn_mrirawnii = '/imaging/camcan/cc700/mri/pipeline/release004/data/aamod_convert_structural_00001/CC110045/structurals/sMR10033_CC110045-0003-00001-000192-01.nii';
    fn_mrirawnii = '/imaging/camcan/cc700/mri/pipeline/release004/data/aamod_convert_structural_00001/CC110033/structurals/sMR10033_CC110033-0003-00001-000192-01.nii';
    fn_mriT1 = [fs_subject_dir '/mri/T1.mgz'];
    fn_mriT1nii = [fs_subject_dir '/mri/T1.nii'];
    fn_mriregT1nii = [fs_subject_dir '/mri/regT1.nii'];
    fn_mriregT1mat = [fs_subject_dir '/mri/regT1.mat'];
    fn_surf_smoothwm = sprintf('%s/surf/%s.smoothwm', fs_subject_dir, hem);
    fn_surf_smoothwm_dec = sprintf('%s/surf/%s.smoothwm.dec', fs_subject_dir, hem);
    fn_surf_smoothwm_dec_curv = sprintf('%s/surf/%s.smoothwm.dec.curv', fs_subject_dir, hem);
    fn_surf_inflated = [fn_surf_smoothwm '.inflated'];
    fn_surf_inflated_dec = [fn_surf_smoothwm '.inflated.dec'];
    fn_surf_mid = sprintf('%s/surf/%s.mid', fs_subject_dir, hem);
    fn_surf_pial = sprintf('%s/surf/%s.pial', fs_subject_dir, hem);
    
    nvertices = 20000; % won't be perfectly accurate, but close
    inflate_niterations = 55;
    inflate_nwrite = 10;
    
    % Inflate surfaces
    disp('Inflating surfaces')
    delete([fn_surf_inflated '*'])
    unix(sprintf('mris_inflate -n %d -w %d %s %s', inflate_niterations, inflate_nwrite, fn_surf_smoothwm, fn_surf_inflated));
    
    % Decimate
    % Clear all decimated surfaces
    delete(sprintf('%s/surf/%s*.dec', fs_subject_dir, hem))
    
    [c1.vertices, c1.faces] = read_surf(fn_surf_smoothwm);
    surf_downsample_factor = nvertices / length(c1.vertices);
    
    unix(sprintf('mris_decimate -d %f %s %s', surf_downsample_factor, fn_surf_smoothwm, fn_surf_smoothwm_dec));
    
    % Find indexes of downsampled data (for equivalence between inflation steps)
    [c2.vertices, c2.faces] = read_surf(fn_surf_smoothwm_dec);
    disp('Finding downsample indices');
    curv_dec = zeros(length(c2.vertices),1);
    decind = zeros(length(c2.vertices),1);
    for ii = 1:length(c2.vertices)
        % Find nearest neighbour
        d = sqrt(sum((c1.vertices-repmat(c2.vertices(ii,:),length(c1.vertices),1)).^2, 2));
        decind(ii) = find(d == min(d));
    end
    
    % Create mid
    [pail.vertices, pial.faces] = read_surf(fn_surf_pial);
    
    mid.vertices = (pail.vertices + c1.vertices) / 2;
    write_surf(fn_surf_mid, mid.vertices, c1.faces+1);
    
    d = dir([fn_surf_inflated, '*']);
    d(end+1).name = sprintf('%s.mid', hem);
    d(end+1).name = sprintf('%s.pial', hem);
    
    disp('Converting surfaces')
    
    clear s sdec
    for ii = 1:length(d)
        s.vertices = read_surf(sprintf('%s/surf/%s', fs_subject_dir, d(ii).name));
        fn = sprintf('%s/surf/%s.dec', fs_subject_dir, d(ii).name);
        disp(['Saving decimated inflated mesh: ', fn])
        write_surf(fn, s.vertices(decind,:), c2.faces+1)
    end
    
    
    c1 = [];
    [c1.vertices, c1.faces] = read_surf(fn_surf_smoothwm);
    [c2.vertices, c2.faces] = read_surf(fn_surf_smoothwm_dec);
    curv = read_curv(sprintf('%s/surf/%s.curv', fs_subject_dir, hem));
    
    write_curv(fn_surf_smoothwm_dec_curv, curv(decind), length(decind));
    
end

% Create nifti images (resliced etc)

unix(sprintf('mri_convert %s %s', fn_mriT1, fn_mriT1nii));
reslice_nii(fn_mriT1nii, [fs_subject_dir, '/mri/T1resliced.nii']);
reslice_nii(fn_mrirawnii, [fs_subject_dir, '/mri/T1_raw_resliced.nii']);

%%%%%%%%%%%%%%%%%%% Coregister original with FS mgz
% disp('Checking FSL path')
% [o, fslloc] = unix('which flirt');
%
% if o > 0
%    error('FSL is not on the path: set the path prior to running this script. e.g. using setenv(path)')
% else
%    disp('FSL found')
% end
%
% fslloc = strtrim(fslloc);
% disp('Running: FSL Flirt')
% unix(sprintf('flirt -in %s -ref %s -out %s -omat %s -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -2D -dof 6 -interp trilinear', fn_mriT1nii, [fs_subject_dir, '/mri/T1_raw_resliced.nii'], fn_mriregT1nii, fn_mriregT1mat));
% unix(sprintf('mri_rigid_register %s %s %s', fn_mriT1nii, [fs_subject_dir, '/mri/T1_raw_resliced.nii'], [fs_subject_dir, '/mri/T1_fs_to_raw.xfm']))
%
% gunzip([fn_mriregT1nii '.gz'])
% delete([fn_mriregT1nii '.gz'])
%
% fid = fopen(fn_mriregT1mat, 'r');
% TmriT1_to_mriorig = textscan(fid, '%f');
% TmriT1_to_mriorig = reshape(TmriT1_to_mriorig{1}, 4,4)';
% fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Creating test NII structure')
% Obviously, the RAW data should not be in FS directory
NIItest = load_nii([fs_subject_dir, '/mri/T1_raw_resliced.nii']);
NIItest.img(:) = 0;
x = 20;
NIItest.img(90+(-x:x),28+(-x:x),112+(-x:x)) = 100;


%% PLOT
close all
figure('Color','w','position',[20 72 800 600])

% Should probably make a new option (.subjfolder | default = colin27)
% All other options would then stay the same to avoid confusion.

% Load and Render the FreeSurfer surface
S = [];
S.hem = 'lh'; % Choose the hemesphere 'lh' or 'rh'
% S.inflationstep = 6; % 1 no inflation, 6 fully inflated
S.fsdir = fs_subject_dir; % when this is set, 
S.plotsurf = 'smoothwm.inflated.dec';
S.lookupsurf = 'smoothwm.dec';
S.decimation = false; % Decimate the surface for speed. (Use FALSE for publishable quality figures).
% S.curvdata = 'rh.smoothwm.dec.curv';
S.curvecontrast = [-0.2 0.2];
S = mni2fs_brain(S);
view([-90 0]) % Change camera angle

% Add overlay, theshold to 98th percentile
S.mnivol = NIItest;
S.clims = [0.5 1]; % overlay masking below 98th percentile
S.surfchecks = true;
S = mni2fs_overlay(S);
mni2fs_lights % Dont forget to turn on the lights!

% Optional - lighting can be altered after rendering

