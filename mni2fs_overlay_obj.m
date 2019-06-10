classdef mni2fs_overlay_obj < handle
    
    properties
        S
        currframe = 0;
        O
        Type = 'overlay_object';
    end
    
    properties(Hidden)
        ft = uint64(0);
        Vsurf
        patchexists = false
    end
    
    methods
        function obj = mni2fs_overlay_obj(S)
            if nargin == 0
                return
            end
            
            if ~isfield(S,{'mnivol'})
                help mni2fs_overlay
                error('.mnivol is a required field of the input structure')
            end
            
            if nargin == 2
                obj.O = Ol;
            end
            
            obj.S = S;
            
            if ~isfield(obj.S,'clims'); obj.S.clims = 'auto'; end
            if ~isfield(obj.S,'climstype'); obj.S.climstype = 'abs'; end
            if ~isfield(obj.S,'smoothdata'); obj.S.smoothdata = 0; end
            if ~isfield(obj.S,'clims_perc'); obj.S.clims_perc = 0.8; end
            if ~isfield(obj.S,'inflationstep'); obj.S.inflationstep = 5; end
            if ~isfield(obj.S,'colormap'); obj.S.colormap = 'jet'; end
            if ~isfield(obj.S,'interpmethod'); obj.S.interpmethod = 'linear'; end
            if ~isfield(obj.S,'overlayalpha'); obj.S.overlayalpha = 1; end
            if ~isfield(obj.S,'lookupsurf'); obj.S.lookupsurf = 'smoothwm'; end
            if ~isfield(obj.S,'plotsurf'); obj.S.plotsurf = 'inflated'; end
            if ~isfield(obj.S,'decimation'); obj.S.decimation = true; end
            if ~isfield(obj.S,'decimated'); obj.S.decimated = false; end
            if ~isfield(obj.S,'framerate'); obj.S.framerate = 10; end
            if ~isfield(obj.S,'qualcheck'); obj.S.qualcheck = false; end

            if isempty(obj.S.clims)
                obj.S.clims = 'auto';
            end
            
            if size(obj.S.clims, 1) > 1
                obj.S.colormap = mni2fs_colormap(obj.S.colormap, obj.S.clims);
                obj.S.clims = [obj.S.clims(1,1) obj.S.clims(end,end)];
            end
            
            obj.S.lastcolormapused = obj.S.colormap;
            
            thisfolder = fileparts(mfilename('fullpath'));
            
            mni2fs_checkpaths;
            
            switch obj.S.plotsurf
                case 'inflated'
                    surfrender_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.inflated' num2str(obj.S.inflationstep) '.surf.gii']);
                case 'smoothwm'
                    surfrender_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.surf.gii']);
                case 'mid'
                    surfrender_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.inflated' num2str(obj.S.inflationstep) '.surf.gii']);
                case 'pial'
                    surfrender_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.inflated' num2str(obj.S.inflationstep) '.surf.gii']);
                otherwise
                    error('Options for .surfacetype = inflated, smoothwm, or pial')
            end
            
            switch obj.S.lookupsurf
                case 'inflated'
                    error('.lookupsurf should be either ''smoothwm'' ''pial'' or ''mid''')
                case 'smoothwm'
                    surf_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.surf.gii']);
                case 'mid'
                    surf_fn = cell(0);
                    surf_fn{1} = fullfile(thisfolder,['/surf/' obj.S.hem '.surf.gii']);
                    surf_fn{2} = fullfile(thisfolder,['/surf/' obj.S.hem '.pial.surf.gii']);
                case 'pial'
                    surf_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.pial.surf.gii']);
                otherwise
                    error('Options for .surfacetype = inflated, smoothwm, or pial')
            end
            
            if ~isfield(S,'separateHem')
                obj.S.separateHem = (obj.S.inflationstep-1)*10;
            end
            
            if ~isfield(S,'gfs')
                if iscell(surf_fn)
                    obj.S.gfs = export(gifti(surf_fn{1}));
                    surfav = export(gifti(surf_fn{2}));
                    obj.S.gfs.vertices = (obj.S.gfs.vertices + surfav.vertices)/2;
                else
                    obj.S.gfs = export(gifti(surf_fn));
                end
                if obj.S.decimation
                    dec = load(sprintf('%s/surf/vlocs_20000_%s.mat', thisfolder, obj.S.hem));
                    obj.S.gfs.vertices = obj.S.gfs.vertices(dec.vlocs,:);
                    obj.S.gfs.faces = dec.faces;
                    obj.S.decimated = true;
                end
            end
            
            if ~isfield(S,'gfsinf')
                obj.S.gfsinf = export(gifti(surfrender_fn));
                if obj.S.decimation
                    % Load / create the reduced path set indexes
                    dec = load(sprintf('%s/surf/vlocs_20000_%s.mat', thisfolder, obj.S.hem));
                    obj.S.gfsinf.vertices = obj.S.gfsinf.vertices(dec.vlocs,:);
                    obj.S.gfsinf.faces = dec.faces;
                end
            else
                obj.S.separateHem = 0;
            end
            
            if ischar(obj.S.mnivol)
                NII = mni2fs_load_nii(obj.S.mnivol);
            elseif isstruct(obj.S.mnivol)
                if ~isfield(obj.S.mnivol, 'loadmethod')
                    error('You must use mni2fs_load_nii to preload the nifti file.');
                else
                    NII = obj.S.mnivol;
                end
            end
            
            if isinteger(NII.img) % Convert NII image to single
                NII.img = single(NII.img);
            end
            
            if obj.S.smoothdata > 0
                disp('Smoothing Volume')
                for si = 1:size(NII.img,4)
                    NII.img(:,:,:,si) = smooth3(NII.img(:,:,:,si),'gaussian',5,obj.S.smoothdata);
                end
            end
            
            % Get the average from the three vertex values for each face
            V = obj.S.gfs.vertices(obj.S.gfs.faces(:,1),:)/3;
            V = V+obj.S.gfs.vertices(obj.S.gfs.faces(:,2),:)/3;
            V = V+obj.S.gfs.vertices(obj.S.gfs.faces(:,3),:)/3;
            
            disp('Interpolating Data')
            for si = 1:size(NII.img,4)
                obj.Vsurf(:,si) = mni2fs_extract(NII, V, obj.S.interpmethod, si, obj.S.qualcheck); 
            end
            
            switch obj.S.hem
                case 'lh'
                    obj.S.gfsinf.vertices(:,1) = obj.S.gfsinf.vertices(:,1)-obj.S.separateHem;
                case 'rh'
                    obj.S.gfsinf.vertices(:,1) = obj.S.gfsinf.vertices(:,1)+obj.S.separateHem;
            end
            
            if ischar(obj.S.clims)
                if strcmp(obj.S.clims,'auto')
                    if strcmp(obj.S.climstype,'abs')
                        obj.S.clims = [quantile2(abs(obj.Vsurf(:)), obj.S.clims_perc, [], 'R-5') max(abs(obj.Vsurf(:)))];
                    else
                        obj.S.clims = [quantile2(obj.Vsurf(:),obj.S.clims_perc, [], 'R-5') max(obj.Vsurf(:))];
                    end
                else
                    error('Unrecognised value for obj.S.clims')
                end
            end
            
            if numel(obj.S.clims) == 1
                obj.S.clims(2) = max(abs(obj.Vsurf(:)));
            end
            
            obj.frame(1);
        end
        
        function frame(obj,frameind)
            
            si = frameind;
            
            switch obj.S.climstype
                case 'abs'
                    ind = abs(obj.Vsurf(:,si)) >= obj.S.clims(1);
                case 'pos'
                    ind = obj.Vsurf(:,si) >= obj.S.clims(1);
                case 'neg'
                    ind = obj.Vsurf(:,si) <= obj.S.clims(1);
                otherwise
                    error('Correct values for .climstype are ''abs'' or ''pos''')
            end
            
            ind(isnan(obj.Vsurf(:,si))) = false;
            
            if obj.patchexists == false && any(ind)
                obj.S.p = patch('Vertices',obj.S.gfsinf.vertices,'Faces',obj.S.gfsinf.faces(ind,:));
                if length(obj.S.overlayalpha) == 1
                    Va = ones(sum(ind),1).* obj.S.overlayalpha; % can put alpha in here.
                else
                    Va = obj.S.overlayalpha;
                end
                set(obj.S.p,'FaceVertexCData',obj.Vsurf(ind,si),'FaceVertexAlphaData',Va,'FaceAlpha',obj.S.overlayalpha)
                mni2fs_lights;
                obj.patchexists = true;
                shading flat
            elseif obj.patchexists == true && any(ind)
                set(obj.S.p, 'Faces',obj.S.gfsinf.faces(ind,:), 'FaceVertexCData',obj.Vsurf(ind,si))
                shading flat
            elseif obj.patchexists == true && ~any(ind)
                set(obj.S.p, 'Faces',[], 'FaceVertexCData',[])
                shading flat
            end
            
            if any(ind)
                switch obj.S.climstype
                    case 'abs'
                        if ischar(obj.S.lastcolormapused)
                            col = colormap(obj.S.lastcolormapused);
                        else
                            col = obj.S.lastcolormapused;
                        end
                        coli = mni2fs_rescale_colormap(col,obj.S.clims);
                        obj.S.lastcolormapused = coli;
                        set(gca,'CLim',[-obj.S.clims(2) obj.S.clims(2)])
                    case 'pos'
                        set(gca,'CLim',obj.S.clims)
                    case 'neg'
                        set(gca,'CLim',obj.S.clims)
                end
                
                colormap(obj.S.lastcolormapused)
                
            end 
            
            
            % Add toolbar if one does not exist.
            if ~isempty(obj.ft)
                te = toc(obj.ft);
                if 1/obj.S.framerate-te > 0
                    pause(1/obj.S.framerate-te)
                else
                    pause(0.001)
                end
            else
                pause(0.001)
            end
            
            obj.ft = tic;
            
            freezeColors % Does not significantly impact time
            set(gca,'Tag','overlay')
            
            % Doesn't work well 
%             set(gca, 'SortMethod', 'ChildOrder')
        end
        
        function transform(obj, rotation, translation)
            
            %% Coordinate transforms
            
            rot = rotation;
            
            th = rot(1);
            Rx = [
                1 0 0
                0 cosd(th) -sind(th)
                0 sind(th) cosd(th)
                ];
            
            th = rot(2);
            Ry = [
                cosd(th) 0 -sind(th)
                0 1 0
                sind(th) 0 cosd(th)
                ];
            
            th = rot(3);
            Rz = [
                cosd(th) -sind(th) 0
                sind(th) cosd(th) 0
                0 0 1
                ];
            
            T = translation';
            
            R = [Rx*Ry*Rz T;0 0 0 1];
            
            V = obj.S.gfsinf.vertices;
            V = [V ones(size(V,1),1)];
            V = V*R';
            V = V(:,1:3);
            
            if obj.patchexists
                set(obj.S.p, 'Vertices', V)
            end
            set(obj.S.brain.p, 'Vertices', V)
            
        end
    end
end