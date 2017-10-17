%% Script to draw data onto any arbitrary surface.
% To do: decimation, inflation step, transmats, mni_extract_individual

clear
% Load files: a draw surface, interpolation surface (lookup) and nifti
% overlay volume (func path) 
% windows paths 
% surfpath = 'C:\Users\trin2636\Documents\tomkirk-data\mni2fs-master\custom surf\lh.inflated.surf.gii';
% lookuppath = 'C:\Users\trin2636\Documents\tomkirk-data\mni2fs-master\custom surf\lh.pial.surf.gii';
% funcpath = 'C:\Users\trin2636\Documents\tomkirk-data\FSonFSLData\singlePLDpcASL\oxasl\native_space\perfusion.nii';
% curv_fn = 'C:\Users\trin2636\Documents\tomkirk-data\mni2fs-master\custom surf\lhcurv.mat';

% relative paths 
surfpath = 'custom surf/lh.inflated.surf.gii';
lookuppath = 'custom surf/lh.pial.surf.gii';
funcpath = 'custom surf/perfusion.nii';
curv_fn = 'custom surf/lhcurv.mat';

% script settings
hem = 'lh';
clims_perc = 0.98; 

% Define the S object to hold settings and refs
S = [];
S.hem = hem;
S.decimation = 0;
S.lookupsurf = 'pial';
S.inflationstep = 0;
customSurface = true; 

% Data paths: surface, lookup and functional
S.nifti_vol = funcpath; 
S.customSurfacePath = surfpath;  
S.lookupsurf = lookuppath;

% whats this doing??
S.plotsurf = 'pial'; % do we need this - just for loading from /surf folder probably?

% auto clims stuff?
if length(clims_perc) == 2
    S.clims = clims_perc;
else
    S.clims_= clims_perc;
end

%% Draw the display surface. Lifted from mni2fs_brain

% all the existing settings from the function, most disabled. 
if ~isfield(S,'surfacecolorspec'); S.surfacecolorspec = false; end
if ~isfield(S,'surfacealpha'); S.surfacealpha = 1; end
% if ~isfield(S,'hem'); error('hem input is required'); end
% if isfield(S,'surfacetype'); S.plotsurf = S.surfacetype; warning('You may now also specify a look up surface that is different to the plotting surface. Use .lookupsurf (see help mni2fs_brain)'); end
% if ~isfield(S,'inflationstep'); S.inflationstep = 5; end
% if ~isfield(S,'lookupsurf'); S.lookupsurf = 'smoothwm'; end
% if ~isfield(S,'decimation'); S.decimation = 20000; end
% if ~isfield(S,'decimated'); S.decimated = false; end

% new settings from TK, currently not required. 
% if ~isfield(S, 'customSurfacePath') 
%     S.customSurfacePath = '';
%     if ~isfield(S, 'plotsurf')
%         S.plotsurf = 'inflated';
%     end 
% else 
    % temporarily disable all other references to surfaces 
%     S.plotsurf = ''; 
% end 
% customSurface = ( ~strcmp(S.customSurfacePath, '') ); 

if ~isfield(S,'priv')
    % Set default values for private settings
    S.priv.lh.sep = false;
    S.priv.rh.sep = false;
end

% thisfolder = fileparts(mfilename('fullpath'));
% 
% if ~ customSurface
%     % new file prefix to condense the code below this point. 
% else
%     
% end

mni2fs_checkpaths
surfrender_fn = surfpath; 

if ~isfield(S,'separateHem')
    S.separateHem = (S.inflationstep-1)*10;
end
    
curvecontrast = [-0.15 0.15];
UseAlphaData = false;

if ~isfield(S,'gfsinf')
    % Load the mesh in 
    S.gfsinf = export(gifti(surfrender_fn));
    curv = importdata(curv_fn);       % Edit: explicitly name the variable curv, do not use load() as this can return a struct wrapper as well
    
    % decimation disabled. 
    if false 
        if S.decimation ~= 0
            dec = load(fullfile(thisfolder, ['/surf/vlocs_20000_' S.hem '.mat']));
            warning('Decimation is hardcoded to 20000, needs updating for custom surfaces')

            S.gfsinf.vertices = S.gfsinf.vertices(dec.vlocs,:);
            S.gfsinf.faces = dec.faces;
            S.decimated = true;
            curv = curv(dec.vlocs);
        end
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

set(gca,'Tag','overlay');
rotate3d;

%% Custom overlay. Direct copy from MNI2FS_overlay
% All decimation removed (for reasons of simplicity) 

if ~isfield(S,'clims'); S.clims = 'auto'; end
if ~isfield(S,'climstype'); S.climstype = 'abs'; end
if ~isfield(S,'smoothdata'); S.smoothdata = 0; end
if ~isfield(S,'clims_perc'); S.clims_perc = 0.8; end
if ~isfield(S,'colormap'); S.colormap = 'jet'; end
if ~isfield(S,'interpmethod'); S.interpmethod = 'cubic'; end
if ~isfield(S,'overlayalpha'); S.overlayalpha = 1; end

% disabled settings here. 
% if ~isfield(S,'inflationstep'); S.inflationstep = 5; end %% do we need this?
% if ~isfield(S,'plotsurf'); S.plotsurf = 'inflated'; end %% and again?
% if ~isfield(S,'decimation'); S.decimation = true; end
% if ~isfield(S,'decimated'); S.decimated = false; end

S.lastcolormapused = S.colormap;
mni2fs_checkpaths;
thisfolder = fileparts(mfilename('fullpath'));

% Load the surfaces that will be plotted on. 
renderSurf = surfpath;
interpSurf = lookuppath; 

if ~isfield(S,'separateHem')
    S.separateHem = (S.inflationstep-1)*10;
end

% GFS refers to the interpolation surface
if ~isfield(S,'gfs')
    S.gfs = export(gifti(interpSurf));
    
    % Decimation. Disabled. 
    if false 
        if S.decimation
            dec = load(fullfile(thisfolder, ['/surf/vlocs_20000_' S.hem '.mat']));
            S.gfs.vertices = S.gfs.vertices(dec.vlocs,:);
            S.gfs.faces = dec.faces;
            S.decimated = true;
        end
    end
end

% GFSINF refers to the render surface 
if ~isfield(S,'gfsinf');
    S.gfsinf = export(gifti(surfpath));
   
    if S.decimation
        % Load / create the reduced path set indexes
        dec = load(['/imaging/dp01/toolboxes/mni2fs/surf/vlocs_20000_' S.hem '.mat']);
        S.gfsinf.vertices = S.gfsinf.vertices(dec.vlocs,:);
        S.gfsinf.faces = dec.faces;
    end
else
    S.separateHem = 0;
end

% Read the NIFTI overlay vol into the S object (overwrite path field)
if ischar(S.nifti_vol)
    NII = load_untouch_nii(S.nifti_vol);
    testT = [NII.hdr.hist.srow_x(1:3); NII.hdr.hist.srow_y(1:3); NII.hdr.hist.srow_z(1:3)];
    if any(testT(:) < 0)
        warning(sprintf('Transformation matrix contains a negative diagonal element. \n Automatically reslicing image. \n. To save time in future, reslice the image using the following command: reslice(old.nii, resliced.nii')) %#ok<SPWRN>
        NII = reslice_return_nii(S.nifti_vol);
        S.nifti_vol = NII;
    end
    
elseif isstruct(S.nifti_vol)
    NII = S.nifti_vol;
    testT = [NII.hdr.hist.srow_x(1:3); NII.hdr.hist.srow_y(1:3); NII.hdr.hist.srow_z(1:3)];
    if any(testT(:) < 0)
        disp(testT)
        warning(sprintf('Negative value in NII header transformation matrix. \nAutomatically reslicing image. \nTo save time reslice the image using reslice_nii(old.nii, new.nii)')) %#ok<SPWRN>
        NII = reslice_return_nii([NII.fileprefix, '.m']);
        S.nifti_vol = NII;
    end
end

if isinteger(NII.img) % Convert NII image to single
    NII.img = single(NII.img);
end

if S.smoothdata > 0
    disp('Smoothing Volume')
    NII.img = smooth3(NII.img,'gaussian',15,S.smoothdata);
end

% Get the average from the three vertex values for each face, representing
% mid-face point. The NIFTI data will be interpolated onto these. 
% Vsurf is a column vector of values, indexed according to mid-face point
% (hence the order corresponds with all other mesh variables)
V = S.gfs.vertices(S.gfs.faces(:,1),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,2),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,3),:)/3;
Vsurf(:,1) = mni2fs_extract_individual(NII,V,S.interpmethod);

% Coordinate shift if separate hemispheres enabled. 
switch S.hem
    case 'lh'
        S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)-S.separateHem;
    case 'rh'
        S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)+S.separateHem;
end

% Set colour scale automatically. 
if ischar(S.clims)
    if strcmp(S.clims,'auto')
        if strcmp(S.climstype,'abs')
            S.clims = [quantile2(abs(Vsurf), S.clims_perc, [], 'R-5') max(abs(Vsurf))];
        else
            S.clims = [quantile2(Vsurf,S.clims_perc, [], 'R-5') max(Vsurf)];
        end
    else
        error('Unrecognised value for S.clims')
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

% Form patches from the vertices and faces. 
S.p = patch('Vertices',S.gfsinf.vertices,'Faces', S.gfsinf.faces(ind,:));

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

    set(gca,'Tag','overlay')
    mni2fs_lights
    
end 

