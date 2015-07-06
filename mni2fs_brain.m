function [S] = mni2fs_brain(S)
% S = mni2fs_brain(S)
% Render the inflated surface, prior to the ROI or Overlay
% Required Fields of S 
% .hem = 'lh' or 'rh'
% Optional Fields
% .surfacetype 'inflated' 'pial' or 'smoothwm' (default = 'inflated')
% selecting 'pial' alters the lookup coordinates for extracting values, not
% the rendered image. Therefore, you should still choose an inflationstep
% .inflationstep = integer value from 1-6. 1 = no inflation, 6 = full inflation, 
% default = 5
% .separateHem = positive scalar. Amount in mm by which to separate
% hemespheres. Default = 10mm for each inflation step
% .surfacecolorspec = overrides the curvature texture with a specified
% color
% .surfacealpha = 0-1 makes the surface transparent (works with or without
% surfacecolorspec set
%
% Example:
% figure('color','k')
% S = [];
% S.hem = 'lh'; % choose the hemesphere 'lh' or 'rh'
% S.inflationstep = 6; % 1 no inflation, 6 fully inflated
% S = mni2fs_brain(S);
% mni2fs_lights
% view([-50 30])
% 
% Written by Darren Price, CSLB, University of Cambridge, 2015

if ~isfield(S,'hem'); error('hem input is required'); end
if ~isfield(S,'surfacetype'); S.surfacetype = 'inflated'; end
if ~isfield(S,'inflationstep'); S.inflationstep = 5; end
if ~isfield(S,{'surfacecolorspec'}); S.surfacecolorspec = false; end
if ~isfield(S,{'surfacealpha'}); S.surfacealpha = 1; end

if ~isfield(S,'priv')
    % Set default values for private settings
    S.priv.lh.sep = false;
    S.priv.rh.sep = false;
end

thisfolder = fileparts(mfilename('fullpath'));

mni2fs_checkpaths

switch S.surfacetype
    case 'pial'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.pial.surf.gii']);
    otherwise
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
end

if all(strcmp({'inflated' 'smoothwm' 'pial' 'mid'},S.surfacetype) == 0)
    error('Options for .surfacetype = inflated, smoothwm, pial or mid')
end

curv_fn = fullfile(thisfolder,['/surf/' S.hem 'curv.mat']);

if ~isfield(S,'separateHem');
    S.separateHem = (S.inflationstep-1)*10;
end
    
curvecontrast = [-0.2 0.2];
UseAlphaData = false;

S.gfsinf = gifti(surfrender_fn);

switch S.hem
    case 'lh'
        if ~S.priv.lh.sep
            S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)-S.separateHem;
            S.priv.lh.sep = true;
        end
        S.priv.loaded = 'lh'; % remember which is the currently loaded hem
    case 'rh'
        if ~S.priv.rh.sep
            S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)+S.separateHem;
            S.priv.rh.sep = true;
        end
        S.priv.loaded = 'rh';
end

S.p = patch('Vertices',S.gfsinf.vertices,'Faces',S.gfsinf.faces);

load(curv_fn);

if any(strcmp(S.surfacetype,{'smoothwm' 'pial'}))
    curv = curv./max(abs(curv));
    curv = curv*max(curvecontrast);
else
    curv(curv > 0) = curvecontrast(2); %#ok<*NODEF>
    curv(curv < 0) = curvecontrast(1);
end

if S.surfacecolorspec == false
    curv = -curv;
    Va = ones(size(curv,1),1).*S.surfacealpha;
    set(S.p,'FaceVertexCData',curv,'FaceVertexAlphaData',Va,'FaceAlpha',S.surfacealpha)
    set(gca,'CLim',[-1 1])
else
    if ischar(S.surfacecolorspec)
        colortable = [1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; 0 0 0];
        colorlabels = {'y' 'm' 'c' 'r' 'g' 'b' 'w' 'k'};
        cdata = colortable(strcmp(colorlabels,S.surfacecolorspec),:);
        cdata = repmat(cdata,length(curv),1);
    else
        cdata = repmat(S.surfacecolorspec,length(curv),1);
    end
    Va = ones(size(cdata,1),1).*S.surfacealpha; % can put alpha in here.
    set(S.p,'FaceVertexCData',cdata,'FaceVertexAlphaData',Va,'FaceAlpha',S.surfacealpha)
end

shading flat
axis equal
axis vis3d
colormap('gray');
freezeColors
hold on
axis off
rotate3d
