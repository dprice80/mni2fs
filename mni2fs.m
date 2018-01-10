classdef mni2fs < handle
    
    properties
        hem = 'both'
        plotsurf = 'mid'
        surfacecolorspec = false
        surfacealpha = 1
        lookupsurf = 'smoothwm'
        decimation = true
        inflationstep = 4
        Sb
        Sr
        So
    end
    
    properties (Hidden)
        decimated = false
    end
    
    methods
        %         function obj = mni2fs()
        %
        %         end
        
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
                    mni2fs_lights
                case {'lh' 'rh'}
                    obj.Sb{1} = [];
                    obj.Sb{1}.hem = obj.hem; % choose the hemesphere 'lh' or 'rh'
                    obj.Sb{1}.inflationstep = obj.inflationstep;
                    obj.Sb{1}.plotsurf = obj.plotsurf;
                    obj.Sb{1}.lookupsurf = obj.lookupsurf;
                    obj.Sb{1}.decimation = obj.decimation;
                    obj.Sb{1} = mni2fs_brain(obj.Sb{1});
                    h(1) = obj.Sb{1}.p;
                    mni2fs_lights
                otherwise
                    error('Property hem should either be both, lh, or rh')
            end
            rotate3d
        end
        
        function h = roi(obj, varargin)
            if isempty(obj.Sb)
                obj.brain
            end
            
            pardef = {
                'roicolorspec' 'r'
                'roialpha' 1
                'mnivol' '/imaging/at07/templates/HarvardOxford-cort-maxprob-thr0-2mm.nii'
                };
            
            if nargin == 1
                disp('Default optionSo{1}. Specift arguments using name value pairs')
                disp(pardef)
                return
            end
            
            args = varargparse(varargin, pardef(:,1), pardef(:,2));
            
            if ischar(args.mnivol)
                NII = load_nii(args.mnivol);
            elseif isstruct(args.mnivol)
                NII = args.mnivol;
                args.mnivol = [];
            else
                error('mnivol should either be a character (path to volume) or struct (nifti loaded using load_nii)')
            end
            
            switch obj.hem
                case 'both'
                    for si = 1:2
                        % Plot an ROI, and make it semi transparent
                        obj.Sr{si} = obj.Sb{si}; % need to use data loaded from brain
                        obj.Sr{si}.mnivol = NII;
                        obj.Sr{si}.roicolorspec = args.roicolorspec; % color. Can also be a three-element vector
                        obj.Sr{si}.roialpha = 1; % transparency 0-1
                        obj.Sr{si} = mni2fs_roi(obj.Sr{si});
                        h(si,:) = obj.Sr{si}.p;
                    end
                case {'lh' 'rh'}
                    obj.Sr{1} = obj.Sb{1}; % need to use data loaded from brain
                    obj.Sr{1}.mnivol = NII;
                    obj.Sr{1}.roicolorspec = args.roicolorspec; % color. Can also be a three-element vector
                    obj.Sr{1}.roialpha = 1; % transparency 0-1
                    obj.Sr{1} = mni2fs_roi(obj.Sr{1});
                otherwise
                    error('Property hem should either be both, lh, or rh')
            end
            mni2fs_lights
            rotate3d
        end
        
        function overlay(obj, varargin)
            
            if isempty(obj.Sb)
                obj.brain
            end
            
            pardef = {
                'clims_perc' 0.98
                'roialpha' 1
                'mnivol' '/imaging/at07/templates/HarvardOxford-cort-maxprob-thr0-2mm.nii'
                };
            
            if nargin == 1
                disp('Default optionSo{1}. Specift arguments using name value pairs')
                disp(pardef)
                return
            end
            
            args = varargparse(varargin, pardef(:,1), pardef(:,2));
            
            if ischar(args.mnivol)

            elseif isstruct(args.mnivol)

            else
                error('mnivol should either be a character (path to volume) or struct (nifti loaded using load_nii)')
            end
            So = Sb;
            So{1}.mnivol = args.mnivol;
            So{1}.clims_perc = 0.98;
            So{1} = mni2fs_overlay(So{1});
            view([-90 0]) % change camera angle
            mni2fs_lights % Dont forget to turn on the lights!
        end
    end
end


