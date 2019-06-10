classdef mni2fs_make_overlay < handle
    
    properties
        currframe = 0;
        O
        H = mni2fs_overlay_obj.empty(0)
        framerate = 10
    end
    
    properties(Hidden)
        ft = uint64(0);
        Vsurf
        patchexists = false
        anim_button_clicked = false;
        hstart
        hstop
        animtext
    end
    
    methods
        
        function obj = mni2fs_make_overlay(varargin)
            if ~isempty(varargin)
                pardef = {
                    'inflationstep' 4
                    'decimation' true
                    'plotsurf' 'smoothwm'
                    'mnivol' []
                    'clims' []
                    'clims_perc' 0
                    'climstype' 'pos'
                    'interpmethod' 'linear'
                    'surfacecolorspec' false
                    'colormap' 'parula'
                    'framerate' 10
                    'animvals' []
                    'overlayalpha' 1
                    };
                S = varargparse(varargin, pardef(:,1), pardef(:,2));
                S.hem = 'lh';
                obj.overlay(S)
                S.hem = 'rh';
                obj.overlay(S)
            end
        end
        
        function obj = overlay(obj, S)
            
            if ~isfield(S, 'brain')
                S = mni2fs_brain(S);
            end
            
            obj.H(end+1) = mni2fs_overlay_obj(S);
            obj.H(end).frame(1);
            
            if ~isfield(obj.H(end).S,'animvals') 
                obj.H(end).S.animvals = 1:size(obj.H(end).Vsurf, 2);
            end
            
            if isempty(obj.hstart) || ~isvalid(obj.hstart)
                h = uicontrol('style','slider','Position', [0 0 200 20], 'Min',1,'Max',size(obj.H(end).Vsurf,2),'Value',1);
                addlistener(h,'Value','PreSet',@obj.contcallback);
                obj.hstart = uicontrol('style','pushbutton','Position', [230 0 70 20], 'string','Start','callback',@obj.startcallback);
                obj.hstop = uicontrol('style','pushbutton','Position', [310 0 70 20], 'string','Stop','callback',@obj.stopcallback);
                obj.animtext = uicontrol('Style','text','Position',[380 0 140 20],'String',sprintf('Frame: %3d',1));
            end
        end
        
        function startcallback(obj, ~, ~)
            obj.anim_button_clicked = true;
            set(obj.hstart, 'string','Playing')
            obj.animate();
        end
        
        function stopcallback(obj, ~, ~)
            set(obj.hstart, 'string','Start')
            obj.anim_button_clicked = false;
        end
        
        function animate(obj, nframes)
            if obj.anim_button_clicked
                % Use infinite loop after user clicked start
                while obj.anim_button_clicked
                    obj.nextframe();
                    if ~isempty(obj.O)
                        obj.O.nextframe();
                    end
                end
            else
                if nargin < 2
                    nframes = size(obj.Vsurf,2);
                end
                
                for ii = 1:nframes
                    obj.nextframe();
                    if ~isempty(obj.O)
                        obj.O.frame(obj.currframe);
                    end
                end
            end
        end
        
        function nextframe(obj, nframes)
            
            if nargin == 1
                nframes = 1;
            end 
            
            obj.currframe = obj.currframe + nframes;
            si = mod(obj.currframe, size(obj.H(1).Vsurf,2))+1;
            obj.frame(si);
        end
        
        function contcallback(obj, ~, evt)
            % Callback for continuous slider
            if 1/obj.framerate-toc(obj.ft) < 0
                obj.currframe = round(get(evt.AffectedObject, 'Value'));
                si = mod(obj.currframe, size(obj.Vsurf,2))+1;
                obj.frame(si);
                obj.ft = tic;
                if ~isempty(obj.O)
                    obj.O.frame(si);
                    obj.O.ft = tic;
                end
            else
                obj.currframe = round(get(evt.AffectedObject, 'Value'));
            end
        end
        
        function frame(obj,frameind)
            for hi = 1:length(obj.H)
                obj.H(hi).frame(frameind);
                set(obj.animtext, 'string', sprintf('Frame: %2.2f (%2.2f)', frameind, obj.H(hi).S.animvals(frameind)))
            end
        end
        
        function plot(obj)
            h = obj.H;
            obj.H = mni2fs_overlay_obj.empty(0);
            for hi = 1:length(h)
                if isfield(h(hi).S, 'brain')
                    h(hi).S = rmfield(h(hi).S, 'brain');
                    h(hi).S = rmfield(h(hi).S, 'p');
                    h(hi).patchexists = false;
                end
                obj.overlay(h(hi).S);
            end
        end
    end
end

%             if ~isfield(S,{'mnivol'})
%                 help mni2fs_overlay
%                 error('.mnivol is a required field of the input structure')
%             end
%             
%             if nargin == 2
%                 obj.O = Ol;
%             end
%             
%             obj.S = S;
%             
%             if ~isfield(obj.S,'clims'); obj.S.clims = 'auto'; end
%             if ~isfield(obj.S,'climstype'); obj.S.climstype = 'abs'; end
%             if ~isfield(obj.S,'smoothdata'); obj.S.smoothdata = 0; end
%             if ~isfield(obj.S,'clims_perc'); obj.S.clims_perc = 0.8; end
%             if ~isfield(obj.S,'inflationstep'); obj.S.inflationstep = 5; end
%             if ~isfield(obj.S,'colormap'); obj.S.colormap = 'jet'; end
%             if ~isfield(obj.S,'interpmethod'); obj.S.interpmethod = 'cubic'; end
%             if ~isfield(obj.S,'overlayalpha'); obj.S.overlayalpha = 1; end
%             if ~isfield(obj.S,'lookupsurf'); obj.S.lookupsurf = 'smoothwm'; end
%             if ~isfield(obj.S,'plotsurf'); obj.S.plotsurf = 'inflated'; end
%             if ~isfield(obj.S,'decimation'); obj.S.decimation = true; end
%             if ~isfield(obj.S,'decimated'); obj.S.decimated = false; end
%             if ~isfield(obj.S,'framerate'); obj.S.framerate = 10; end
%             if ~isfield(obj.S,'qualcheck'); obj.S.qualcheck = false; end
% 
%             if isempty(obj.S.clims)
%                 obj.S.clims = 'auto';
%             end
%             
%             obj.S.lastcolormapused = obj.S.colormap;
%             
%             thisfolder = fileparts(mfilename('fullpath'));
%             
%             mni2fs_checkpaths
%             
%             switch obj.S.plotsurf
%                 case 'inflated'
%                     surfrender_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.inflated' num2str(obj.S.inflationstep) '.surf.gii']);
%                 case 'smoothwm'
%                     surfrender_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.surf.gii']);
%                 case 'mid'
%                     surfrender_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.inflated' num2str(obj.S.inflationstep) '.surf.gii']);
%                 case 'pial'
%                     surfrender_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.inflated' num2str(obj.S.inflationstep) '.surf.gii']);
%                 otherwise
%                     error('Options for .surfacetype = inflated, smoothwm, or pial')
%             end
%             
%             switch obj.S.lookupsurf
%                 case 'inflated'
%                     error('.lookupsurf should be either ''smoothwm'' ''pial'' or ''mid''')
%                 case 'smoothwm'
%                     surf_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.surf.gii']);
%                 case 'mid'
%                     surf_fn = cell(0);
%                     surf_fn{1} = fullfile(thisfolder,['/surf/' obj.S.hem '.surf.gii']);
%                     surf_fn{2} = fullfile(thisfolder,['/surf/' obj.S.hem '.pial.surf.gii']);
%                 case 'pial'
%                     surf_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.pial.surf.gii']);
%                 otherwise
%                     error('Options for .surfacetype = inflated, smoothwm, or pial')
%             end
%             
%             if ~isfield(S,'separateHem')
%                 obj.S.separateHem = (obj.S.inflationstep-1)*10;
%             end
%             
%             if ~isfield(S,'gfs')
%                 if iscell(surf_fn)
%                     obj.S.gfs = export(gifti(surf_fn{1}));
%                     surfav = export(gifti(surf_fn{2}));
%                     obj.S.gfs.vertices = (obj.S.gfs.vertices + surfav.vertices)/2;
%                 else
%                     obj.S.gfs = export(gifti(surf_fn));
%                 end
%                 if obj.S.decimation
%                     dec = load(fullfile(thisfolder, ['/surf/vlocs_20000_' obj.S.hem '.mat']));
%                     obj.S.gfs.vertices = obj.S.gfs.vertices(dec.vlocs,:);
%                     obj.S.gfs.faces = dec.faces;
%                     obj.S.decimated = true;
%                 end
%             end
%             
%             if ~isfield(S,'gfsinf')
%                 obj.S.gfsinf = export(gifti(surfrender_fn));
%                 if obj.S.decimation
%                     % Load / create the reduced path set indexes
%                     dec = load(['/imaging/dp01/toolboxes/mni2fs/surf/vlocs_20000_' obj.S.hem '.mat']);
%                     obj.S.gfsinf.vertices = obj.S.gfsinf.vertices(dec.vlocs,:);
%                     obj.S.gfsinf.faces = dec.faces;
%                 end
%             else
%                 obj.S.separateHem = 0;
%             end
%             
%             if ischar(obj.S.mnivol)
%                 NII = mni2fs_load_nii(obj.S.mnivol);
%             elseif isstruct(obj.S.mnivol)
%                 if ~isfield(obj.S.mnivol, 'loadmethod')
%                     error('You must use mni2fs_load_nii to preload the nifti file.');
%                 else
%                     NII = obj.S.mnivol;
%                 end
%             end
%             
%             if isinteger(NII.img) % Convert NII image to single
%                 NII.img = single(NII.img);
%             end
%             
%             if obj.S.smoothdata > 0
%                 disp('Smoothing Volume')
%                 for si = 1:size(NII.img,4)
%                     NII.img(:,:,:,si) = smooth3(NII.img(:,:,:,si),'gaussian',5,obj.S.smoothdata);
%                 end
%             end
%             
%             % Get the average from the three vertex values for each face
%             V = obj.S.gfs.vertices(obj.S.gfs.faces(:,1),:)/3;
%             V = V+obj.S.gfs.vertices(obj.S.gfs.faces(:,2),:)/3;
%             V = V+obj.S.gfs.vertices(obj.S.gfs.faces(:,3),:)/3;
%             
%             disp('Interpolating Data')
%             for si = 1:size(NII.img,4)
%                 obj.Vsurf(:,si) = mni2fs_extract(NII, V, obj.S.interpmethod, si, obj.S.qualcheck); 
%             end
%             
%             switch obj.S.hem
%                 case 'lh'
%                     obj.S.gfsinf.vertices(:,1) = obj.S.gfsinf.vertices(:,1)-obj.S.separateHem;
%                 case 'rh'
%                     obj.S.gfsinf.vertices(:,1) = obj.S.gfsinf.vertices(:,1)+obj.S.separateHem;
%             end
%             
%             if ischar(obj.S.clims)
%                 if strcmp(obj.S.clims,'auto')
%                     if strcmp(obj.S.climstype,'abs')
%                         obj.S.clims = [quantile2(abs(obj.Vsurf(:)), obj.S.clims_perc, [], 'R-5') max(abs(obj.Vsurf(:)))];
%                     else
%                         obj.S.clims = [quantile2(obj.Vsurf(:),obj.S.clims_perc, [], 'R-5') max(obj.Vsurf(:))];
%                     end
%                 else
%                     error('Unrecognised value for obj.S.clims')
%                 end
%             end
%             
%             if numel(obj.S.clims) == 1
%                 obj.S.clims(2) = max(abs(obj.Vsurf(:)));
%             end
%             
%             % Set up figure
%             mni2fs_addtoolbar();
%             if obj.S.decimated == false
%                 rot = rotate3d;
%                 set(rot,'RotateStyle','box')
%             else
%                 rotate3d
%             end
%             

%             
%             axis equal
%             axis vis3d
%             hold on
%             axis off
            