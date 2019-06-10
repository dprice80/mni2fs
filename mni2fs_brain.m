function [S] = mni2fs_brain(S)
% S = mni2fs_brain(S)
% Render the inflated surface, prior to the ROI or Overlay
% Required Fields of S 
%    .hem = 'lh' or 'rh'
% Optional Fields
%    .plotsurf      'inflated' 'pial' 'mid' or 'smoothwm' | default = 'inflated'
%                    Selects the plotted surface type.
%
%    .lookupsurf     'pial' 'mid' or 'smoothwm' | default = 'smoothwm'
%                    Alter the lookup surface. 
%                        smoothwm = white / grey boundary (default)
%                        pial     = grey / csf boundary
%                        mid      = midpoint between pial and smoothwm
%                    
%                    Note this setting alters the lookup coordinates for extracting values, not
%                    the rendered image. For example, if you want to plot the pial
%                    surface, then set .plotsurface = 'pial';
%
%    .inflationstep  integer value from 1-6. 1 = no inflation, 6 = full inflation, 
%                    default = 5
%
%    .separateHem    positive scalar. Amount in mm by which to separate
%                    hemespheres. Default = 10 * .inflationstep
%
%    .surfacecolorspec overrides the curvature texture with a specified
%                    color, can be a text color value, or a 3 element array
%                    i.e. 'b' or [0 0 1] for blue. If using indexed colours
%                    , you must divide by 255. e.g. [0 0 255]./255
%
%    .surfacealpha   0-1 makes the surface transparent (works with or without
%                    surfacecolorspec set)
%
%    .decimation     true | false : decimate the surface. Useful for fast
%                    plotting low res images. 
%                    true = low res, false = high res
%
% Example:
%    figure('color','k')
%    S = [];
%    S.hem = 'lh'; % choose the hemesphere 'lh' or 'rh'
%    S.inflationstep = 6; (fully inflated)
%    S.decimation = false;
%    S = mni2fs_brain(S);
%    mni2fs_lights
%    view([-50 30])
% 
% Darren Price, CSLB, University of Cambridge, 2015

if ~isfield(S,'hem'); error('hem input is required'); end
if isfield(S,'surfacetype'); S.plotsurf = S.surfacetype; warning('You may now also specify a look up surface that is different to the plotting surface. Use .lookupsurf (see help mni2fs_brain)'); end
if ~isfield(S,'plotsurf'); S.plotsurf = 'inflated'; end
if ~isfield(S,'inflationstep'); S.inflationstep = 5; end
if ~isfield(S,'surfacecolorspec'); S.surfacecolorspec = [.7 .7 .7]; end
if ~isfield(S,'surfacealpha'); S.surfacealpha = 1; end
if ~isfield(S,'S.curvcontrast'); S.curvcontrast = 0.15; end
% if ~isfield(S,'lookupsurf'); S.lookupsurf = 'smoothwm'; end
if ~isfield(S,'decimation'); S.decimation = 20000; end
if ~isfield(S,'decimated'); S.decimated = false; end

if any(strcmp(S.plotsurf, {'mid', 'pial'}))
    S.surfacecolorspec = [0.5 0.5 0.5];
end

if length(S.curvcontrast) == 1
    S.curvcontrast = [-S.curvcontrast S.curvcontrast];
end

V = ver('MATLAB');
if S.decimation == false
    if str2double(V.Version) == 8.5
        warning('There is a known issue with high resolution plotting in Matlab 2015a. Use decimated surface, or try another version.')
    end
end

if ~isfield(S,'priv')
    % Set default values for private settings
    S.priv.lh.sep = false;
    S.priv.rh.sep = false;
end

thisfolder = fileparts(mfilename('fullpath'));

mni2fs_checkpaths


switch S.plotsurf
    case 'pial'
        surf_fn = fullfile(thisfolder,['/surf/' S.hem '.pial.surf.gii']);
    case 'mid'
        surf_fn{1} = fullfile(thisfolder,['/surf/' S.hem '.pial.surf.gii']);
        surf_fn{2} = fullfile(thisfolder,['/surf/' S.hem '.surf.gii']);
    otherwise
        surf_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
end

if all(strcmp({'inflated' 'smoothwm' 'pial' 'mid'}, S.plotsurf) == 0)
    error('Options for .surfacetype = inflated, smoothwm, pial or mid')
end

if ~isfield(S,'separateHem')
    S.separateHem = (S.inflationstep-1)*10;
end

if ~isfield(S,'gfsinf') || ~isfield(S, 'curv')
    if iscell(surf_fn)
        S.gfsinf = export(gifti(surf_fn{1}));
        surfav = export(gifti(surf_fn{2}));
        S.gfsinf.vertices = (S.gfsinf.vertices + surfav.vertices)/2;
    else
        S.gfsinf = export(gifti(surf_fn));
    end
    
    curv_fn = fullfile(thisfolder,['/surf/' S.hem 'curv.mat']);
    load(curv_fn);
    if S.decimation ~= 0
        dec = load(fullfile(thisfolder, ['/surf/vlocs_20000_' S.hem '.mat']));
        S.gfsinf.vertices = S.gfsinf.vertices(dec.vlocs,:);
        S.gfsinf.faces = dec.faces;
        S.decimated = true;
        curv = curv(dec.vlocs);
    end
    S.curv = curv;
else
    curv = S.curv;
end

V = gifti('/imaging/dp01/toolboxes/mni2fs_devel/convert/surf/rh.surf.gii');
mmxdir = [min(V.vertices(:,1)) max(V.vertices(:,1))];
mmydir = [min(V.vertices(:,2)) max(V.vertices(:,2))];
mmzdir = [min(V.vertices(:,3)) max(V.vertices(:,3))];


% Scale inflated surfaces to fit smoothwm surfaces (so they roughly take
% the same space on the plot).
switch S.hem
    case 'lh'
        mmxdir = [-69 3.5];
        mmydir = [-87 86]; % min and max in y direction for rescaling inflated brains
        mmzdir = [-60 64];
    case 'rh'
        mmxdir = [3 70];
        mmydir = [-86 88]; % min and max in y direction for rescaling inflated brains
        mmzdir = [-65 65];
end

dx = diff([min(S.gfsinf.vertices(:,1)) max(S.gfsinf.vertices(:,1))])/diff(mmxdir);
dy = diff([min(S.gfsinf.vertices(:,2)) max(S.gfsinf.vertices(:,2))])/diff(mmydir);
dz = diff([min(S.gfsinf.vertices(:,3)) max(S.gfsinf.vertices(:,3))])/diff(mmzdir);
S.gfsinf.vertices(:,1) = (S.gfsinf.vertices(:,1)-min(S.gfsinf.vertices(:,1)))/dx + mmxdir(1);
S.gfsinf.vertices(:,2) = (S.gfsinf.vertices(:,2)-min(S.gfsinf.vertices(:,2)))/dy + mmydir(1);
S.gfsinf.vertices(:,3) = (S.gfsinf.vertices(:,3)-min(S.gfsinf.vertices(:,3)))/dz + mmzdir(1);


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

S.brain.p = patch('Vertices',S.gfsinf.vertices,'Faces',S.gfsinf.faces);

if any(strcmp(S.plotsurf,{'pial'}))
    curv = curv./max(abs(curv)) * max(S.curvcontrast);
else
    curv(curv > 0) = S.curvcontrast(2); %#ok<*NODEF>
    curv(curv < 0) = S.curvcontrast(1);
end

if S.surfacecolorspec == false
    curv = -curv;
    Va = ones(size(curv,1),1).*S.surfacealpha;
    set(S.brain.p,'FaceVertexCData',curv,'FaceVertexAlphaData',Va,'FaceAlpha',S.surfacealpha)
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
    set(S.brain.p,'FaceVertexCData',cdata,'FaceVertexAlphaData',Va,'FaceAlpha',S.surfacealpha)
end

shading flat

axis equal
axis vis3d
colormap('gray');
freezeColors;
hold on
axis off

% Add toolbar if one does not exist.
mni2fs_addtoolbar();

set(gca,'Tag','overlay');
rotate3d;

if S.decimated == 1
    disp('NOTE: Using Decimated Surface. For full print quality resolution set .decimation = 0')
end