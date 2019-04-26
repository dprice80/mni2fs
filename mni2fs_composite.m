classdef mni2fs_composite < handle
    % mni2fs_composite(varargin)
    % Default name value pair arguments
        % 'inflationstep' 4
        % 'decimation' true
        % 'plotsurf' 'smoothwm'
        % 'mnivol' []
        % 'clims' []
        % 'clims_perc' 0
        % 'climstype' 'pos'
        % 'interpmethod' 'linear'
        % 'surfacecolorspec' []
        % 'colormap' 'parula'
        % 'framerate' 10
        % 'animvals' []
        % 'overlayalpha' 1
    
    properties
        H
        ori
        pardef
    end
    
    methods
        
        function obj = mni2fs_composite(varargin)
            % If input is pair val args, and there is no ori field, then
            % use default preset.
            % If varargin is a cell array of pair val args then loop
            % through each set, adding defaults where necessary
           
            obj.ori{1}.hem = 'lh';
            obj.ori{1}.rot = [0 0 180];
            obj.ori{1}.trans = [-100 10 0];
            
            obj.ori{2}.hem = 'rh';
            obj.ori{2}.rot = [0 0 0];
            obj.ori{2}.trans = [0 200 0];
            
            obj.ori{3}.hem = 'lh';
            obj.ori{3}.rot = [0 0 0];
            obj.ori{3}.trans = [-100 10 -140];
            
            obj.ori{4}.hem = 'rh';
            obj.ori{4}.rot = [0 0 180];
            obj.ori{4}.trans = [0 200 -140];
            
            obj.pardef = {
                'inflationstep' 4
                'decimation' true
                'plotsurf' 'smoothwm'
                'mnivol' []
                'clims' []
                'clims_perc' 0
                'climstype' 'pos'
                'interpmethod' 'linear'
                'surfacecolorspec' [.7 .7 .7]
                'colormap' 'parula'
                'framerate' 10
                'animvals' []
                'overlayalpha' 1
                };
            
            if ~isempty(varargin) && ischar(varargin{1})
                obj.overlay(varargin{:})
                axis normal
                axis equal
                mni2fs_lights
            end
        end
        
        function frame(obj,ind)
            for hi = 1:length(obj.H)
                obj.H(hi).frame(ind);
            end
        end
        
%         function frame(obj,ind)
%             for hi = 1:length(obj.H)
%                 obj.H(hi).frame(ind);
%             end
%         end
        
        function overlay(obj,varargin)
            
            % test validity of args
            varargparse(varargin, obj.pardef(:,1), obj.pardef(:,2));
            % loop through orientations
            for oi = 1:length(obj.ori)
                % perse arguments
                
                S.hem = obj.ori{oi}.hem;
                
                if ~isempty(obj.H)
                    % If H exists then assign some values from S stored
                    % in the overlay object H
                    S = obj.H(oi).S; %#ok<*AGROW>
                    for vi = 1:2:length(varargin)
                        % Assign args. Args are already validated 
                        S.(varargin{vi}) = varargin{vi+1};
                    end
                else
                    if ischar(varargin{1})
                        S = varargparse(varargin, obj.pardef(:,1), obj.pardef(:,2));
                    else
                        S = varargin{1};
                    end
                    S.hem = obj.ori{oi}.hem;
                    S = mni2fs_brain(S);
                end
                
                hnew(oi) = mni2fs_overlay_obj(S);
                hnew(oi).transform(obj.ori{oi}.rot, obj.ori{oi}.trans);
                pause(0.1)
            end
            view([90 0])
            colorbar
            obj.H = [obj.H hnew];
        end
    end
end