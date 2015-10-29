function [S] = mni2fs_overlay(S)
% mni2fs_update
%
% Written by Darren Price, CSLB, University of Cambridge, 2015

if ~isfield(S,{'mnivol'})
    help mni2fs_overlay
    error('.mnivol is a required field of the input structure')
end

if ~isfield(S,'clims'); S.clims = 'auto'; end
if ~isfield(S,'climstype'); S.climstype = 'abs'; end
if ~isfield(S,'smoothdata'); S.smoothdata = 0; end
if ~isfield(S,'clims_perc'); S.clims_perc = 0.8; end
if ~isfield(S,'colormap'); S.colormap = 'jet'; end
if ~isfield(S,'interpmethod'); S.interpmethod = 'cubic'; end
if ~isfield(S,'overlayalpha'); S.overlayalpha = 1; end

S.lastcolormapused = S.colormap;

thisfolder = fileparts(mfilename('fullpath'));

if ~isfield(S,'gfs');
    error('Missing the field .gfs. You need to run mni2fs_overlay once before running this function')
end

if ~isfield(S,'gfsinf');
    error('Missing the field .gfsinf. You need to run mni2fs_overlay once before running this function')
end

if ischar(S.mnivol)
    NII = load_untouch_nii(S.mnivol);
elseif isstruct(S.mnivol)
    NII = S.mnivol;
end

if isinteger(NII.img) % Convert NII image to double
    NII.img = single(NII.img);
end

if S.smoothdata > 0
    disp('Smoothing Volume')
    NII.img = smooth3(NII.img,'gaussian',S.smoothdata);
end

% Get the average from the three vertex values for each face

NIIframe = NII;
disp('Loading Frames')
for surfi = 1:size(NII.img,4)
    printProgress(surfi,size(NII.img,4))
    NIIframe.img = NII.img(:,:,:,surfi);
    V = S.gfs.vertices(S.gfs.faces(:,1),:)/3;
    V = V+S.gfs.vertices(S.gfs.faces(:,2),:)/3;
    V = V+S.gfs.vertices(S.gfs.faces(:,3),:)/3;
    Vsurf(:,surfi) = mni2fs_extract(NIIframe,V,S.interpmethod);
end

for ii = 1:10
for surfi = 1:size(NII.img,4)
    
    if ischar(S.clims)
        if strcmp(S.clims,'auto')
            if strcmp(S.climstype,'abs')
                S.clims = [quantile2(abs(Vsurf(:,surfi)), S.clims_perc, [], 'R-5') max(abs(Vsurf(:,surfi)))];
            else
                S.clims = [quantile2(Vsurf(:,surfi), S.clims_perc, [], 'R-5') max(Vsurf(:,surfi))];
            end
        else
            error('unrecognised value for S.clims')
        end
    end
    
    if numel(S.clims) == 1
        S.clims(2) = max(abs(Vsurf(:,surfi)));
    end
    
    switch S.climstype
        case 'abs'
            ind = abs(Vsurf(:,surfi)) >= S.clims(1);
        case 'pos'
            ind = Vsurf(:,surfi) >= S.clims(1);
        otherwise
            error('Correct values for .climstype are ''abs'' or ''pos''')
    end
    
    Va = ones(sum(ind),1).* S.overlayalpha;
    
    set(S.p,'Faces',S.gfsinf.faces(ind,:),'FaceVertexCData',Vsurf(ind,surfi),'FaceVertexAlphaData',Va,'FaceAlpha',S.overlayalpha)
    pause(1/S.fps)
    
end
end

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