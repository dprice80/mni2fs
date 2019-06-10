classdef mni2fs_brain_obj < handle
    
    properties
        S
        currframe = 0;
        O
        Type = 'overlay_object';
    end
    
    methods
        
        function obj = mni2fs_brain(S)
            % obj.S = mni2fs_brain(obj.S)
            % Render the inflated surface, prior to the ROI or Overlay
            % Required Fields of obj.S
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
            %    obj.S = [];
            %    obj.S.hem = 'lh'; % choose the hemesphere 'lh' or 'rh'
            %    obj.S.inflationstep = 6; (fully inflated)
            %    obj.S.decimation = false;
            %    obj.S = mni2fs_brain(obj.S);
            %    mni2fs_lights
            %    view([-50 30])
            %
            % Darren Price, CSLB, University of Cambridge, 2015
            
            obj.S = S;
            clear S
            
            if ~isfield(obj.S,'hem'); error('hem input is required'); end
            if isfield(obj.S,'surfacetype'); obj.S.plotsurf = obj.S.surfacetype; warning('You may now also specify a look up surface that is different to the plotting surface. Use .lookupsurf (see help mni2fs_brain)'); end
            if ~isfield(obj.S,'plotsurf'); obj.S.plotsurf = 'inflated'; end
            if ~isfield(obj.S,'inflationstep'); obj.S.inflationstep = 5; end
            if ~isfield(obj.S,'surfacecolorspec'); obj.S.surfacecolorspec = false; end
            if ~isfield(obj.S,'surfacealpha'); obj.S.surfacealpha = 1; end
            if ~isfield(obj.S,'lookupsurf'); obj.S.lookupsurf = 'smoothwm'; end
            if ~isfield(obj.S,'decimation'); obj.S.decimation = 20000; end
            if ~isfield(obj.S,'decimated'); obj.S.decimated = false; end
            
            V = ver('MATLAB');
            if obj.S.decimation == false
                if str2double(V.Version) == 8.5
                    warning('There is a known issue with high resolution plotting in Matlab 2015a. Use decimated surface, or try another version.')
                end
            end
            
            if ~isfield(obj.S,'priv')
                % Set default values for private settings
                obj.S.priv.lh.sep = false;
                obj.S.priv.rh.sep = false;
            end
            
            thisfolder = fileparts(mfilename('fullpath'));
            
            mni2fs_checkpaths
            
            switch obj.S.plotsurf
                case 'pial'
                    surfrender_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.pial.surf.gii']);
                otherwise
                    surfrender_fn = fullfile(thisfolder,['/surf/' obj.S.hem '.inflated' num2str(obj.S.inflationstep) '.surf.gii']);
            end
            
            if all(strcmp({'inflated' 'smoothwm' 'pial' 'mid'},obj.S.plotsurf) == 0)
                error('Options for .surfacetype = inflated, smoothwm, pial or mid')
            end
            
            if ~isfield(obj.S,'separateHem');
                obj.S.separateHem = (obj.S.inflationstep-1)*10;
            end
            
            curvecontrast = [-0.15 0.15];
            UseAlphaData = false;
            
            if ~isfield(obj.S,'gfsinf')
                obj.S.gfsinf = export(gifti(surfrender_fn));
                curv_fn = fullfile(thisfolder,['/surf/' obj.S.hem 'curv.mat']);
                load(curv_fn);
                if obj.S.decimation ~= 0
                    dec = load(fullfile(thisfolder, ['/surf/vlocs_20000_' obj.S.hem '.mat']));
                    obj.S.gfsinf.vertices = obj.S.gfsinf.vertices(dec.vlocs,:);
                    obj.S.gfsinf.faces = dec.faces;
                    obj.S.decimated = true;
                    curv = curv(dec.vlocs);
                end
                obj.S.curv = curv;
            end
            
            switch obj.S.hem
                case 'lh'
                    if ~obj.S.priv.lh.sep
                        obj.S.gfsinf.vertices(:,1) = obj.S.gfsinf.vertices(:,1)-obj.S.separateHem;
                        obj.S.priv.lh.sep = true;
                    end
                    obj.S.priv.loaded = 'lh'; % remember which is the currently loaded hem
                case 'rh'
                    if ~obj.S.priv.rh.sep
                        obj.S.gfsinf.vertices(:,1) = obj.S.gfsinf.vertices(:,1)+obj.S.separateHem;
                        obj.S.priv.rh.sep = true;
                    end
                    obj.S.priv.loaded = 'rh';
            end
            
            obj.S.p = patch('Vertices',obj.S.gfsinf.vertices,'Faces',obj.S.gfsinf.faces);
            
            if any(strcmp(obj.S.plotsurf,{'smoothwm' 'pial'}))
                curv = curv./max(abs(curv));
                curv = curv*max(curvecontrast);
            else
                curv(curv > 0) = curvecontrast(2); %#ok<*NODEF>
                curv(curv < 0) = curvecontrast(1);
            end
            
            if obj.S.surfacecolorspec == false
                curv = -curv;
                Va = ones(size(curv,1),1).*obj.S.surfacealpha;
                set(obj.S.p,'FaceVertexCData',curv,'FaceVertexAlphaData',Va,'FaceAlpha',obj.S.surfacealpha)
                set(gca,'CLim',[-1 1])
            else
                if ischar(obj.S.surfacecolorspec)
                    colortable = [1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; 0 0 0];
                    colorlabels = {'y' 'm' 'c' 'r' 'g' 'b' 'w' 'k'};
                    cdata = colortable(strcmp(colorlabels,obj.S.surfacecolorspec),:);
                    cdata = repmat(cdata,length(curv),1);
                else
                    cdata = repmat(obj.S.surfacecolorspec,length(curv),1);
                end
                Va = ones(size(cdata,1),1).*obj.S.surfacealpha; % can put alpha in here.
                set(obj.S.p,'FaceVertexCData',cdata,'FaceVertexAlphaData',Va,'FaceAlpha',obj.S.surfacealpha)
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
            
            if obj.S.decimated == 1
                disp('NOTE: Using Decimated Surface. For full print quality resolution set .decimation = 0')
            end
            
        end
    end
end