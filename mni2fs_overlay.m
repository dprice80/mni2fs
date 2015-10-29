function [S] = mni2fs_overlay(S)
% mni2fs_overlay
%
% Required fields
%     .mnivol - NIFTI file in MNI space containing data to be plotted or a
%               NIFTI structure obtained using load_nii(filename) or load_untouch_nii(filename)
%
% Optional Fields
%     .clims       one or two element vector, or 'auto' for automatic scaling
%     .climstype   'abs', 'pos' or 'neg'. This determines the method of
%                  scaling the color map. Abs is used when both positive and negative
%                  values are present and the same absolute threshold is used for both
%                  signs. pos and neg are used for one-sided scaling (either positive or
%                  negative thresholds). For example for a one sided negative threshold
%                  use clims = [0 0.2] and climstype = 'neg'.
%     .alpha       Sets the alpha of the overlay (transparency).
%                  1 = opaque, 0 = transparent
%     .smoothdata  0 = no smoothing | positive scalar = smooth the volume before extracting values
%     .hem         'lh' or 'rh'
%     .surfacetype 'inflated' 'pial' or 'smoothwm' (default = 'inflated')
%                  selecting 'pial' alters the lookup coordinates for extracting values, not
%                  the rendered image. Therefore, you should still choose an inflationstep
%     .inflationstep integer value from 1-6. 1 = no inflation, 6 = full inflation,
%                    default = 5
%     .separateHem positive scalar. Amount in mm by which to separate
%                  hemespheres. Default = 10mm for each inflation step
%     .interpmethod 'spline' (slowest) 'cubic' 'linear' 'nearest' (fastest)
%
% Darren Price, CSLB, University of Cambridge, 2015

if ~isfield(S,{'mnivol'})
    help mni2fs_overlay
    error('.mnivol is a required field of the input structure')
end

if ~isfield(S,'clims'); S.clims = 'auto'; end
if ~isfield(S,'climstype'); S.climstype = 'abs'; end
if ~isfield(S,'smoothdata'); S.smoothdata = 0; end
if ~isfield(S,'clims_perc'); S.clims_perc = 0.8; end
if ~isfield(S,'inflationstep'); S.inflationstep = 5; end
if ~isfield(S,'colormap'); S.colormap = 'jet'; end
if ~isfield(S,'interpmethod'); S.interpmethod = 'cubic'; end
if ~isfield(S,'overlayalpha'); S.overlayalpha = 1; end
if ~isfield(S,'lookupsurf'); S.lookupsurf = 'smoothwm'; end
if ~isfield(S,'plotsurf'); S.plotsurf = 'inflated'; end
if ~isfield(S,'decimation'); S.decimation = 20000; end
if ~isfield(S,'decimated'); S.decimated = false; end

S.lastcolormapused = S.colormap;

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
    S.separateHem = (S.inflationstep-1)*10;
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
    if S.decimation ~= 0
        dec = load(fullfile(thisfolder, ['/surf/vlocs_20000_' S.hem '.mat']));
        S.gfs.vertices = S.gfs.vertices(dec.vlocs,:);
        S.gfs.faces = dec.faces;
        S.decimated = true;
    end
end

if ~isfield(S,'gfsinf');
    S.gfsinf = export(gifti(surfrender_fn));
    if S.decimation ~= 0
        % Load / create the reduced path set indexes
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

if isinteger(NII.img) % Convert NII image to single
    NII.img = single(NII.img);
end

if S.smoothdata > 0
    disp('Smoothing Volume')
    NII.img = smooth3(NII.img,'gaussian',15,S.smoothdata);
end

% Get the average from the three vertex values for each face
V = S.gfs.vertices(S.gfs.faces(:,1),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,2),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,3),:)/3;
Vsurf(:,1) = mni2fs_extract(NII,V,S.interpmethod);

switch S.hem
    case 'lh'
        S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)-S.separateHem;
    case 'rh'
        S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)+S.separateHem;
end

if ischar(S.clims)
    if strcmp(S.clims,'auto')
        if strcmp(S.climstype,'abs')
            S.clims = [quantile2(abs(Vsurf), S.clims_perc, [], 'R-5') max(abs(Vsurf))];
        else
            S.clims = [quantile2(Vsurf,S.clims_perc, [], 'R-5') max(Vsurf)];
        end
    else
        error('unrecognised value for S.clims')
    end
end

if numel(S.clims) == 1
    S.clims(2) = max(abs(Vsurf));
end

switch S.climstype
    case 'abs'
        ind = abs(Vsurf) >= S.clims(1);
    case 'pos'
        ind = Vsurf >= S.clims(1);
    otherwise
        error('Correct values for .climstype are ''abs'' or ''pos''')
end

S.p = patch('Vertices',S.gfsinf.vertices,'Faces',S.gfsinf.faces(ind,:));

if sum(ind) ~= 0
    
    Va = ones(sum(ind),1).* S.overlayalpha; % can put alpha in here.
    set(S.p,'FaceVertexCData',Vsurf(ind),'FaceVertexAlphaData',Va,'FaceAlpha',S.overlayalpha)
    
    switch S.climstype
        case 'abs'
            if ischar(S.lastcolormapused)
                col = colormap(S.lastcolormapused);
            else
                col = S.lastcolormapused;
            end
            coli = mni2fs_rescale_colormap(col,S.clims);
            S.lastcolormapused = coli;
            set(gca,'CLim',[-S.clims(2) S.clims(2)])
        case 'pos'
            set(gca,'CLim',S.clims)
    end
    
    colormap(S.lastcolormapused)
    
    shading flat
    axis equal
    axis vis3d
    hold on
    axis off
    freezeColors
    
% Add toolbar if one does not exist.

mni2fs_addtoolbar();

set(gca,'Tag','overlay')

if S.decimated == false
    rot = rotate3d;
    set(rot,'RotateStyle','box')
else
    rotate3d
end
    
end