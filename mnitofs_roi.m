function S = mnitofs_roi(S)
% Usage: S = mnitofs_roi(S)
% Required Fields of S
% .mnivol - NIFTI file in MNI space containing data to be plotted or a
% NIFTI structure obtained using load_nii(filename) or load_untouch_nii(filename)
% .hem = 'lh' or 'rh'
% Optional Fields
% .roicolorspec - single char color value e.g. 'r' or three element vector
% e.g. [0.3 0.5 1];
% .roialpha = positive scalar [0-1]. Controls the transparency of the ROI.
% Written by Darren Price, CSLB, University of Cambridge, 2015

if ~isfield(S,{'mnivol'})
    help mnitofs_roi
    error('.mnivol is a required field of the input structure')
end

if ~isfield(S,{'roicolorspec'}); S.roicolorspec = 'r'; end
if ~isfield(S,{'roialpha'}); S.roialpha = 1; end

thisfolder = fileparts(mfilename('fullpath'));
if ~exist([thisfolder '/surf'],'dir')
    warning('SURF FOLDER NOT FOUND:')
    disp('Please download the support files (.zip) from')
    disp('<a href = "https://github.com/dprice80/mnitofs/releases/download/1.0.0/mnitofs_supportfiles.zip">https://github.com/dprice80/mnitofs/releases/</a>')
    error(['Surfaces not found'])
end

surf_fn = fullfile(thisfolder,['/surf/' S.hem '.surf.gii']);
switch S.surfacetype
    case 'inflated'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
    case 'smoothwm'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.surf.gii']);
    case 'inflated-pial'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
        surf_fn = fullfile(thisfolder,['/surf/' S.hem '.pial.surf.gii']);
end
curv_fn = fullfile(thisfolder,['/surf/' S.hem 'curv.mat']);

if ~isfield(S,'separateHem');
    S.separateHem = S.inflationstep*10;
end

curvecontrast = [-0.2 0.2]; % 0.9 = black / white

colortable = [1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; 0 0 0];
colorlabels = {'y' 'm' 'c' 'r' 'g' 'b' 'w' 'k'};

if ~isfield(S,'gfs'); S.gfs = gifti(surf_fn); end
if ~isfield(S,'gfsinf'); 
    S.gfsinf = gifti(surfrender_fn); 
else
    S.separateHem = 0;
end

if ischar(S.mnivol)
    NII = load_untouch_nii(S.mnivol);
elseif isstruct(S.mnivol)
    NII = S.mnivol;
end

if S.roismoothdata > 0
    disp('Smoothing Volume')
    NII.img = smooth3(NII.img,'gaussian',S.roismoothdata);
end

% Get the average from the three vertex values for each face
V = S.gfs.vertices(S.gfs.faces(:,1),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,2),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,3),:)/3;
Vsurf(:,1) = mnitofs_extract(NII,V,'nearest');

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

if ischar('S.roicolorspec') == 1
    cdata = colortable(strcmp(colorlabels,S.roicolorspec),:);
    cdata = repmat(cdata,sum(ind),1);
else 
    cdata = repmat(S.roicolorspec,sum(ind),1);
end

Va = ones(size(cdata,1),1).* S.roialpha; % can put alpha in here.

set(p,'FaceVertexCData',cdata,'FaceVertexAlphaData',Va,'FaceAlpha',S.roialpha);
shading flat
axis vis3d
rotate3d