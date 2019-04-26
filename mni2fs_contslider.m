classdef mni2fs_contslider < handle
    
    properties
        currframe = 0;
        OL
        framerate = 10;
    end
    
    properties(Hidden)
        ft = uint64(0);
    end
    
    methods
        function obj = mni2fs_contslider(objarray)
            
            for oi = objarray
                if ~isobject(oi)
                    error('Inputs should be a cell array of overlay "objects"')
                elseif ~strcmp(oi.Type, 'overlay_object')
                    error('Inputs should be a cell array of overlay "objects"')
                end
            end
            
            obj.OL = objarray;
            
            obj.framerate = obj.OL(1).S.framerate; % just grab framerate from the first overlay object
            
            h = uicontrol('style','slider','Position', [0 0 400 20], 'Min',1,'Max',size(oi.Vsurf,2),'Value',1);
            addlistener(h,'Value','PreSet',@obj.contcallback);
          
        end
        
        function animate(obj, nframes)
            if nargin < 2
                nframes = size(obj.OL(1).Vsurf,2);
            end
            
            for ii = 1:nframes
                obj.nextframe();
            end
        end
%         
        function nextframe(obj, nframes)
            
            if nargin == 1
                nframes = 1;
            end 
            
            obj.currframe = obj.currframe + nframes;
            si = mod(obj.currframe, size(obj.OL(1).Vsurf,2))+1;
            for oi = obj.OL
                oi.frame(si);
            end
        end
        
        function contcallback(obj, ~, evt)
            % Callback for continuous slider
            if 1/obj.framerate-toc(obj.ft) < 0
                si = mod(obj.currframe, size(obj.OL(1).Vsurf,2))+1;
                obj.currframe = round(get(evt.AffectedObject, 'Value'));
                for oi = obj.OL
                    oi.frame(si);
                end
                obj.ft = tic;
                disp(sprintf('Animval = %2.2f: ind = %d', obj.OL(1).S.animvals(si), si)); %#ok<DSPS>
            end
        end
    end
end