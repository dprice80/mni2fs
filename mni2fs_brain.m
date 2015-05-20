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

if ~isfield(S,'priv')
    % Set default values for private settings
    S.priv.lh.sep = false;
    S.priv.rh.sep = false;
end

thisfolder = fileparts(mfilename('fullpath'));

mni2fs_checkpaths

switch S.surfacetype
    case 'inflated'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
    case 'smoothwm'
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.surf.gii']);
    case 'pial'
        surf_fn = fullfile(thisfolder,['/surf/' S.hem '.pial.surf.gii']);
        surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
end
curv_fn = fullfile(thisfolder,['/surf/' S.hem 'curv.mat']);

if ~isfield(S,'separateHem');
    S.separateHem = S.inflationstep*10;
end
    
curvecontrast = [-0.2 0.2]; % 0.9 = black / white
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

switch S.surfacetype
    case 'inflated'
        curv(curv > 0) = curvecontrast(2); %#ok<*NODEF>
        curv(curv < 0) = curvecontrast(1);
    case 'smoothwm'
        curv = curv./max(abs(curv));
        curv = curv*max(curvecontrast);
end

curv = -curv;
set(gca,'CLim',[-1 1])
set(S.p,'FaceVertexCData',curv)
shading flat
axis equal
axis vis3d
colormap('gray');
freezeColors
hold on
axis off
rotate3d