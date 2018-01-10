function S = mni2fs_roi(S)
% Usage: S = mni2fs_roi(S)
% Most of the fields of S will be inhereted from previous function calls
% if S was specified as the output.  i.e. S = mni2fs_brain(S)
%
% Required Fields of S
%      .mnivol        NIFTI file in MNI space containing data to be plotted or a
%                     NIFTI structure obtained using load_nii(filename) or load_untouch_nii(filename)
%      .hem           'lh' or 'rh'
%
% Optional Fields
%      .plotsurf      'inflated', 'smoothwm', 'mid', 'pial' (mid is the midpoint
%                     between pial and gm/wm boundary)
%      .lookupsurf    'pial' 'mid' or 'smoothwm' default = 'inflated'
%                     Alter the lookup surface.
%                       smoothwm = white / grey boundary (default)
%                       pial     = grey / csf boundary
%                       mid      = midpoint between pial and smoothwm
%      .roicolorspec  single char color value e.g. 'r' or three element vector
%                     e.g. [0.3 0.5 1];
%      .roialpha      positive scalar [0-1]. Controls the transparency of the ROI.
%      .roismoothdata scalar value by which to smooth the ROI volume. This has
%                     the effect of expanding the ROI boundary
% Darren Price, CSLB, University of Cambridge, 2015

if ~isfield(S,{'mnivol'})
    help mni2fs_roi
    error('.mnivol is a required field of the input structure')
end

if ~isfield(S,'roicolorspec'); S.roicolorspec = 'r'; end
if ~isfield(S,'roialpha'); S.roialpha = 1; end
if ~isfield(S,'roismoothdata'); S.roismoothdata = 0; end
if ~isfield(S,'lookupsurf'); S.lookupsurf = 'smoothwm'; end
if ~isfield(S,'decimation'); S.decimation = true; end
if ~isfield(S,'decimated'); S.decimated = false; end

thisfolder = fileparts(mfilename('fullpath'));

mni2fs_checkpaths

switch S.plotsurf
    case 'inflated'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
    case 'smoothwm'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.surf.gii']);
    case 'mid'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
    case 'pial'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
    otherwise
        error('Options for .surfacetype = inflated, smoothwm, or pial')
end

switch S.lookupsurf
    case 'inflated'
        error('.lookupsurf should be either ''smoothwm'' ''pial'' or ''mid''')
    case 'smoothwm'
        surf_fn = fullfile(thisfolder,['/surf/' S.hem '.surf.gii']);
    case 'mid'
        surf_fn = cell(0);
        surf_fn{1} = fullfile(thisfolder,['/surf/' S.hem '.surf.gii']);
        surf_fn{2} = fullfile(thisfolder,['/surf/' S.hem '.pial.surf.gii']);
    case 'pial'
        surf_fn = fullfile(thisfolder,['/surf/' S.hem '.pial.surf.gii']);
    otherwise
        error('Options for .surfacetype = inflated, smoothwm, or pial')
end

curv_fn = fullfile(thisfolder,['/surf/' S.hem 'curv.mat']);

if ~isfield(S,'separateHem');
    S.separateHem = S.inflationstep*10;
end

curvecontrast = [-0.2 0.2]; % 0.9 = black / white

if ~isfield(S,'gfs');
    if iscell(surf_fn)
        S.gfs = export(gifti(surf_fn{1}));
        surfav = export(gifti(surf_fn{2}));
        S.gfs.vertices = (S.gfs.vertices + surfav.vertices)/2;
    else
        S.gfs = export(gifti(surf_fn));
    end
    
    % Load / create the reduced path set indexes
    if S.decimation ~= 0
        dec = load(fullfile(thisfolder, ['/surf/vlocs_20000_' S.hem '.mat']));
        S.gfs.vertices = S.gfs.vertices(dec.vlocs,:);
        S.gfs.faces = dec.faces;
        S.decimated = true;
    end
end

if ~isfield(S,'gfsinf');
    S.gfsinf = export(gifti(surfrender_fn));
    disp('The only available decimated surface currently contains 20000 vertices - will be updated to allow any value soon')
    if S.decimation ~= 0
        dec = load(['/imaging/dp01/toolboxes/mni2fs/surf/vlocs_20000_' S.hem '.mat']);
        S.gfsinf.vertices = S.gfsinf.vertices(dec.vlocs,:);
        S.gfsinf.faces = dec.faces;
    end
else
    S.separateHem = 0;
end

if ischar(S.mnivol)
    NII = load_untouch_nii(S.mnivol);
elseif isstruct(S.mnivol)
    NII = S.mnivol;
end

if isinteger(NII.img) % Convert NII image to double
    NII.img = single(NII.img);
end

if S.roismoothdata > 0
    disp('Smoothing Volume')
    NII.img = smooth3(NII.img,'gaussian',S.roismoothdata);
end

% Get the average from the three vertex values for each face
V = S.gfs.vertices(S.gfs.faces(:,1),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,2),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,3),:)/3;
Vsurf(:,1) = mni2fs_extract(NII,V,'nearest');

switch S.hem
    case 'lh'
        S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)-S.separateHem;
    case 'rh'
        S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)+S.separateHem;
end

ind = Vsurf~=0;

if sum(ind) == 0
    error('No values found on the surface')
end

p = patch('Vertices',S.gfsinf.vertices,'Faces',S.gfsinf.faces(ind,:),'EdgeColor','k','EdgeAlpha',0);

if ischar(S.roicolorspec)
    colortable = [1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; 0 0 0];
    colorlabels = {'y' 'm' 'c' 'r' 'g' 'b' 'w' 'k'};
    cdata = colortable(strcmp(colorlabels,S.roicolorspec),:);
    cdata = repmat(cdata,sum(ind),1);
else
    cdata = repmat(S.roicolorspec,sum(ind),1);
end

Va = ones(size(cdata,1),1).* S.roialpha; % can put alpha in here.

set(p,'FaceVertexCData',cdata,'FaceVertexAlphaData',Va,'FaceAlpha',S.roialpha);

shading flat

axis vis3d

% Add toolbar if one does not exist.
mni2fs_addtoolbar();

set(gca,'Tag','overlay')
rotate3d