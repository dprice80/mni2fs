classdef mni2fs < handle
    % TODO: use [T] = evalc('m.disp') to generate custom output. 
    % Search through T, and append default options / additional info to each property.
    
    properties
        hem
        plotsurf
        surfacecolorspec
        surfacealpha
        lookupsurf
        decimation
        inflationstep
        Sb
        Sr
        So
        toolboxpath
    end
    
    properties (Hidden)
        decimated = false
    end
    
    methods
        function obj = mni2fs(varargin)
            obj.toolboxpath = fileparts(mfilename('fullpath'));
            
            % Parse arguments
            pardef = {
                'hem'               'both'
                'plotsurf'          'mid'
                'surfacecolorspec'  false
                'surfacealpha'      1
                'lookupsurf'        'smoothwm'
                'decimation'        true
                'inflationstep'     4
                };
            
            args = varargparse(varargin, pardef(:,1), pardef(:,2));
            
            fns = fieldnames(args);
            
            % Assign parsed arguments to object properties
            for ii = 1:length(fns)
                obj.(fns{ii}) = args.(fns{ii});
            end
            
            fprintf('Object created with the following properties\n\n')
            disp(obj)
        end
        
        %         function display(obj)
        %             disp(obj.fields) %#ok<MCNPN>
        %         end
        
        function h = brain(obj)
            
            switch obj.hem
                case 'both'
                    obj.Sb{1} = [];
                    obj.Sb{1}.hem = 'lh';
                    obj.Sb{1}.inflationstep = obj.inflationstep;
                    obj.Sb{1}.plotsurf = obj.plotsurf;
                    obj.Sb{1}.lookupsurf = obj.lookupsurf;
                    obj.Sb{1}.decimation = obj.decimation;
                    obj.Sb{2} = obj.Sb{1};
                    obj.Sb{1} = mni2fs_brain(obj.Sb{1});
                    h(1) = obj.Sb{1}.p;
                    obj.Sb{2}.hem = 'rh'; % choose the hemesphere 'lh' or 'rh'
                    obj.Sb{2} = mni2fs_brain(obj.Sb{2});
                    h(2) = obj.Sb{2}.p;
                case {'lh' 'rh'}
                    obj.Sb{1} = [];
                    obj.Sb{1}.hem = obj.hem; % choose the hemesphere 'lh' or 'rh'
                    obj.Sb{1}.inflationstep = obj.inflationstep;
                    obj.Sb{1}.plotsurf = obj.plotsurf;
                    obj.Sb{1}.lookupsurf = obj.lookupsurf;
                    obj.Sb{1}.decimation = obj.decimation;
                    obj.Sb{1} = mni2fs_brain(obj.Sb{1});
                    h(1) = obj.Sb{1}.p;
                otherwise
                    error('Property hem should either be both, lh, or rh')
            end
            mni2fs_lights;
            rotate3d
        end
        
        function h = roi(obj, varargin)
            
            pardef = {
                'roicolorspec' 'lines'
                'roialpha' 1
                'mnivol' '/imaging/at07/templates/HarvardOxford-cort-maxprob-thr0-2mm.nii'
                };
            
            if nargin == 1
                disp('Default options: (specify arguments using name value pairs)')
                disp(pardef)
                return
            end
            
            obj.checkbrain();
            
            if length(varargin) > 1
                args = varargparse(varargin, pardef(:,1), pardef(:,2));
            end
            
            if ischar(args.mnivol)
                NII = load_nii(args.mnivol);
            elseif isstruct(args.mnivol)
                NII = args.mnivol;
                args.mnivol = [];
            else
                error('mnivol should either be a character (path to volume) or struct (nifti loaded using load_nii)')
            end
            
            if strcmp(args.roicolorspec, 'lines')
                disp('Using default colourmap (lines). See help mni2fs_roi for options')
                Nlines = length(unique(NII.img));
                args.roicolorspec = repmat(lines, ceil(Nlines/length(lines)), 1);
            end
            
            for si = 1:length(obj.Sb)
                % Plot an ROI, and make it semi-transparent
                obj.Sr{si} = obj.Sb{si}; % need to use data loaded from brain
                obj.Sr{si}.mnivol = NII;
                obj.Sr{si}.roicolorspec = args.roicolorspec; % color. Can also be a three-element vector
                obj.Sr{si}.roialpha = 1; % transparency 0-1
                obj.Sr{si} = mni2fs_roi(obj.Sr{si});
                h{si} = obj.Sr{si}.p; %#ok<AGROW>
            end
            mni2fs_lights
            rotate3d
        end
        
        function h = overlay(obj, varargin)
            
            pardef = {
                'clims_perc' 0.98
                'clims' 'auto' 
                'roialpha' 1
                'mnivol' [obj.toolboxpath '/examples/AudMean.nii']
                'qualcheck' false
                };
            
            if nargin == 1
                disp('Default options: (specify arguments using name value pairs)')
                disp(pardef)
                return
            end
            
            obj.checkbrain();
            
            args = varargparse(varargin, pardef(:,1), pardef(:,2));
            
            if ~(ischar(args.mnivol) || isstruct(args.mnivol))
                error('mnivol should either be a character (path to volume) or struct (nifti loaded using load_nii)')
            end
            
            obj.So = obj.Sb;
            
            for ii = 1:length(obj.So)
                obj.So{ii}.mnivol = args.mnivol;
                obj.So{ii}.clims_perc = args.clims_perc;
                obj.So{ii}.clims = args.clims;
                obj.So{ii}.qualcheck = args.qualcheck;
                obj.So{ii} = mni2fs_overlay(obj.So{ii});
                h(ii) = obj.So{ii}.p; %#ok<AGROW>
            end

            mni2fs_lights % Dont forget to turn on the lights!
        end

    end
    
    methods (Hidden)
        function checkbrain(obj)
            % May extend this function at some point
            if isempty(obj.Sb)
                obj.brain
                %             else
                %                 for ii = 1:length(obj.Sb)
                %                 try
                %                     get(obj.Sb{ii}.p)
                %                 catch
                %                     obj.brain
                %                 end
            end
        end

        function findprop(obj);     disp(obj); end
        function gt(obj);           disp(obj); end
        function le(obj);           disp(obj); end
        function lt(obj);           disp(obj); end
        function ne(obj);           disp(obj); end
        function notify(obj);       disp(obj); end
        function ge(obj);           disp(obj); end
        function findobj(obj);      disp(obj); end
        function addlistener(obj);  disp(obj); end
        function eq(obj);           disp(obj); end
    end
end


