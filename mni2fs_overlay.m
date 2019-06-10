function [S] = mni2fs_overlay(S)
% mni2fs_overlay
%
% Required fields
%     .mnivol - NIFTI file in MNI space containing data to be plotted or a
%               NIFTI structure obtained using mni2fs_load_nii(filename)
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
if ~isfield(S,'interpmethod'); S.interpmethod = 'nearest'; end
if ~isfield(S,'overlayalpha'); S.overlayalpha = 1; end
if ~isfield(S,'lookupsurf'); S.lookupsurf = 'smoothwm'; end
if ~isfield(S,'plotsurf'); S.plotsurf = 'inflated'; end
if ~isfield(S,'decimation'); S.decimation = true; end
if ~isfield(S,'decimated'); S.decimated = false; end
if ~isfield(S,'framerate'); S.framerate = 10; end
if ~isfield(S,'qualcheck'); S.qualcheck = false; end

if isempty(S.clims)
    S.clims = 'auto';
end

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

if ~isfield(S,'separateHem')
    S.separateHem = (S.inflationstep-1)*10;
end

if ~isfield(S,'gfs')
    if iscell(surf_fn)
        S.gfs = export(gifti(surf_fn{1}));
        surfav = export(gifti(surf_fn{2}));
        S.gfs.vertices = (S.gfs.vertices + surfav.vertices)/2;
    else
        S.gfs = export(gifti(surf_fn));
    end
    if S.decimation
        dec = load(fullfile(thisfolder, ['/surf/vlocs_20000_' S.hem '.mat']));
        S.gfs.vertices = S.gfs.vertices(dec.vlocs,:);
        S.gfs.faces = dec.faces;
        S.decimated = true;
    end
end

if ~isfield(S,'gfsinf')
    S.gfsinf = export(gifti(surfrender_fn));
    if S.decimation
        % Load / create the reduced path set indexes
        dec = load(['/imaging/dp01/toolboxes/mni2fs/surf/vlocs_20000_' S.hem '.mat']);
        S.gfsinf.vertices = S.gfsinf.vertices(dec.vlocs,:);
        S.gfsinf.faces = dec.faces;
    end
else
    S.separateHem = 0;
end

if ischar(S.mnivol)
    NII = mni2fs_load_nii(S.mnivol);
elseif isstruct(S.mnivol)
    if ~isfield(S.mnivol, 'loadmethod')
        error('You must use mni2fs_load_nii to preload the nifti file.');
    else
        NII = S.mnivol;
    end
end

if isinteger(NII.img) % Convert NII image to single
    NII.img = single(NII.img);
end

if S.smoothdata > 0
    disp('Smoothing Volume')
    for si = 1:size(NII.img,4)
        NII.img(:,:,:,si) = smooth3(NII.img(:,:,:,si),'gaussian',5,S.smoothdata);
    end
end

% Get the average from the three vertex values for each face
V = S.gfs.vertices(S.gfs.faces(:,1),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,2),:)/3;
V = V+S.gfs.vertices(S.gfs.faces(:,3),:)/3;

disp('Interpolating Data')
for si = 1:size(NII.img,4)
    Vsurf(:,si) = mni2fs_extract(NII, V, S.interpmethod, si, S.qualcheck); %#ok<AGROW>
end

switch S.hem
    case 'lh'
        S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)-S.separateHem;
    case 'rh'
        S.gfsinf.vertices(:,1) = S.gfsinf.vertices(:,1)+S.separateHem;
end

if ischar(S.clims)
    if strcmp(S.clims,'auto')
        if strcmp(S.climstype,'abs')
            S.clims = [quantile2(abs(Vsurf(:)), S.clims_perc, [], 'R-5') max(abs(Vsurf(:)))];
        else
            S.clims = [quantile2(Vsurf(:),S.clims_perc, [], 'R-5') max(Vsurf(:))];
        end
    else
        error('Unrecognised value for S.clims')
    end
end

if numel(S.clims) == 1
    S.clims(2) = max(abs(Vsurf(:)));
end

% Set up figure
mni2fs_addtoolbar();
if S.decimated == false
    rot = rotate3d;
    set(rot,'RotateStyle','box')
else
    rotate3d
end

axis equal
axis vis3d
hold on
axis off

loopi = 0;

if size(Vsurf, 2) > 1
    disp('Looping 3 times')
    looplim = size(Vsurf, 2) * 3;
else
    looplim = 0;
end

while loopi <= looplim
    
    loopi = loopi + 1;
    if loopi > 1
        delete(S.p)
    end
    
    for si = 1:size(Vsurf,2)
        ts = tic;
        switch S.climstype
            case 'abs'
                ind = abs(Vsurf(:,si)) >= S.clims(1);
            case 'pos'
                ind = Vsurf(:,si) >= S.clims(1);
            case 'neg'
                ind = Vsurf(:,si) <= S.clims(1);
            otherwise
                error('Correct values for .climstype are ''abs'' or ''pos''')
        end
        
        if si == 1
            S.p = patch('Vertices',S.gfsinf.vertices,'Faces',S.gfsinf.faces(ind,:));
            Va = ones(sum(ind),1).* S.overlayalpha; % can put alpha in here.
            set(S.p,'FaceVertexCData',Vsurf(ind,si),'FaceVertexAlphaData',Va,'FaceAlpha',S.overlayalpha)
            mni2fs_lights
        else
            set(S.p,'Vertices',S.gfsinf.vertices, 'Faces',S.gfsinf.faces(ind,:), 'FaceVertexCData',Vsurf(ind,si))
        end
        shading flat
        
        if sum(ind) ~= 0
            
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
                case 'neg'
                    set(gca,'CLim',S.clims)
            end
            
            colormap(S.lastcolormapused)
            
        end
        
        % Add toolbar if one does not exist.
        te = toc(ts);
        if 1/S.framerate-te > 0
            pause(1/S.framerate-te)
        else
            pause(0.001)
        end
        
        freezeColors
        set(gca,'Tag','overlay')
        
    end
end
