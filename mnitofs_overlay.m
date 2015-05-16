function [S] = mnitofs_overlay(S)
% mnitofs_overlay
% Required fields
% .mnivol - NIFTI file in MNI space containing data to be plotted or a
% NIFTI structure obtained using load_nii(filename) or load_untouch_nii(filename)
% Optional Fields
% .clims - one or two element vector, or 'auto' for automatic scaling
% .smoothdata - 0 = no smoothing | positive scalar = smooth the volume before extracting values
% .hem - 'lh' or 'rh'
% .surfacetype 'inflated' 'pial' or 'smoothwm' (default = 'inflated')
% selecting 'pial' alters the lookup coordinates for extracting values, not
% the rendered image. Therefore, you should still choose an inflationstep
% .inflationstep = integer value from 1-6. 1 = no inflation, 6 = full inflation, 
% default = 5
% .separateHem = positive scalar. Amount in mm by which to separate
% hemespheres. Default = 10mm for each inflation step
% .interpmethod - 'spline' (slowest) 'cubic' 'linear' 'nearest' (fastest)
% Written by Darren Price, CSLB, University of Cambridge, 2015

if ~isfield(S,{'mnivol'})
    help mnitofs_overlay
    error('.mnivol is a required field of the input structure')
end

if ~isfield(S,'clims'); S.clims = 'auto'; end
if ~isfield(S,'climstype'); S.climstype = 'abs'; end
if ~isfield(S,'smoothdata'); S.smoothdata = 0; end
if ~isfield(S,'clims_perc'); S.clims_perc = 0.8; end
if ~isfield(S,'surfacetype'); S.surfacetype = 'inflated'; end
if ~isfield(S,'inflationstep'); S.inflationstep = 5; end
if ~isfield(S,'colormap'); S.colormap = 'jet'; end
if ~isfield(S,'interpmethod'); S.interpmethod = 'cubic'; end

thisfolder = fileparts(mfilename('fullpath'));

surf_fn = fullfile(thisfolder,['/surf/' S.hem '.surf.gii']);
switch S.surfacetype
    case 'inflated'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
    case 'inflated-pial'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
        surf_fn = fullfile(thisfolder,['/surf/' S.hem '.pial.surf.gii']);
end
curv_fn = fullfile(thisfolder,['/surf/' S.hem 'curv.mat']);

if ~isfield(S,'separateHem');
    S.separateHem = S.inflationstep*10;
end

curvecontrast = [-0.2 0.2]; % 0.9 = black / white

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

if S.smoothdata > 0
    disp('Smoothing Volume')
    NII.img = smooth3(NII.img,'gaussian',S.smoothdata);
end

% Get the average from the three vertex values for each face
V = S.gfs.vertices(S.gfs.faces(:,1),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,2),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,3),:)/3;
Vsurf(:,1) = mnitofs_extract(NII,V,S.interpmethod);

switch S.hem
    case 'lh'
        S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)-S.separateHem;
    case 'rh'
        S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)+S.separateHem;
end

if ischar(S.clims)
    if strcmp(S.clims,'auto')
        if strcmp(S.climstype,'abs')
            S.clims = [quantile(abs(Vsurf),S.clims_perc) max(abs(Vsurf))];
        else
            S.clims = [quantile(Vsurf,S.clims_perc) max(Vsurf)];
        end
    else
        error('unrecognised value for S.clims')
    end
end

if numel(S.clims) == 1
    S.clims(2) = max(abs(Vsurf));
end

if strcmp(S.climstype,'abs')
    ind = abs(Vsurf) >= S.clims(1) & abs(Vsurf) <= S.clims(2);
else
    ind = Vsurf >= S.clims(1) & Vsurf <= S.clims(2);
end
S.p = patch('Vertices',S.gfsinf.vertices,'Faces',S.gfsinf.faces(ind,:));

set(S.p,'FaceVertexCData',Vsurf(ind))

colormap(S.colormap)
set(gca,'CLim',S.clims)
colorbar
axis vis3d
shading flat
freezeColors
rotate3d