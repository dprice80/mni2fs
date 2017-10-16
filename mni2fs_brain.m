function [S] = mni2fs_brain(S)
% S = mni2fs_brain(S)
% Render the inflated surface, prior to the ROI or Overlay
% Required Fields of S 
%    .hem = 'lh' or 'rh'
% Optional Fields
%    .plotsurf      'inflated' 'pial' 'mid' or 'smoothwm' | default = 'inflated'
%                    Selects the plotted surface type.
%
%    .lookupsurf     'pial' 'mid' or 'smoothwm' | default = 'inflated'
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

% Edits made by Tom Kirk, IBME, University of Oxford, 2017
% Modified so that the data can be drawn on any supplied surface, not just
% the MNI atlas. Note that this functionality is set by providing a
% directory to the custom surfaces by S.customSurfacePath, this dir must
% contain surfaces (.gii), transformation matrices (.vloc?) and curves
% (.mat) to the same naming convention as that in the /surf directory

if ~isfield(S,'hem'); error('hem input is required'); end
if isfield(S,'surfacetype'); S.plotsurf = S.surfacetype; warning('You may now also specify a look up surface that is different to the plotting surface. Use .lookupsurf (see help mni2fs_brain)'); end
if ~isfield(S,'inflationstep'); S.inflationstep = 5; end
if ~isfield(S,'surfacecolorspec'); S.surfacecolorspec = false; end
if ~isfield(S,'surfacealpha'); S.surfacealpha = 1; end
if ~isfield(S,'lookupsurf'); S.lookupsurf = 'smoothwm'; end
if ~isfield(S,'decimation'); S.decimation = 20000; end
if ~isfield(S,'decimated'); S.decimated = false; end
if ~isfield(S, 'customSurfacePath') 
    S.customSurfacePath = '';
    if ~isfield(S, 'plotsurf')
        S.plotsurf = 'inflated';
    end 
else 
    % temporarily disable all other references to surfaces 
    S.plotsurf = ''; 
end 
customSurface = ( ~strcmp(S.customSurfacePath, '') ); 


if ~isfield(S,'priv')
    % Set default values for private settings
    S.priv.lh.sep = false;
    S.priv.rh.sep = false;
end

thisfolder = fileparts(mfilename('fullpath'));
% 
% if ~ customSurface
%     % new file prefix to condense the code below this point. 
% else
%     
% end


mni2fs_checkpaths

% Use MNI surface (provided) or custom surface (user-supplied)?
if ~ customSurface
    switch S.plotsurf
        case 'pial'
            surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.pial.surf.gii']);
        otherwise
            surfrender_fn = fullfile(thisfolder,['/surf/' S.hem '.inflated' num2str(S.inflationstep) '.surf.gii']);
    end
    % Test that one of the standard surfaces has been requested. 
    if all(strcmp({'inflated' 'smoothwm' 'pial' 'mid'},S.plotsurf) == 0)
        error('Options for .surfacetype = inflated, smoothwm, pial or mid. For custom surfaces, provide the path via S.customSurfacePath.');
    end
    
else
    switch S.plotsurf
        case 'pial'
            surfrender_fn = fullfile(S.customSurfacePath, ['/' S.hem '.pial.surf.gii']); 
        otherwise 
            surfrender_fn = fullfile(S.customSurfacePath, ['/' S.hem '.inflated.surf.gii']);
    end 
    
end

if ~isfield(S,'separateHem')
    S.separateHem = (S.inflationstep-1)*10;
end
    
curvecontrast = [-0.15 0.15];
UseAlphaData = false;

if ~isfield(S,'gfsinf')
    S.gfsinf = export(gifti(surfrender_fn));
    
    if customSurface
        curv_fn = fullfile(S.customSurfacePath, ['/' S.hem 'curv.mat']);
    else 
        curv_fn = fullfile(thisfolder,['/surf/' S.hem 'curv.mat']);
    end   
    curv = importdata(curv_fn);       % Edit: explicitly name the variable curv, do not use load as this can return a struct wrapper as well
    
    if S.decimation ~= 0
        if true % 
            dec = load(fullfile(thisfolder, ['/surf/vlocs_20000_' S.hem '.mat']));
            warning('Decimation is hardcoded to 20000, needs updating for custom surfaces')
        else
            % custom decimation goes here. 
        end 
        
        S.gfsinf.vertices = S.gfsinf.vertices(dec.vlocs,:);
        S.gfsinf.faces = dec.faces;
        S.decimated = true;
        curv = curv(dec.vlocs);
    end
end

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

if any(strcmp(S.plotsurf,{'smoothwm' 'pial'}))
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