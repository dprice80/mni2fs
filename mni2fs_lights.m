function c = mni2fs_lights(preset,onoff,lightset)
% Turn on/off the lights!
% onoff = 'on' or 'off'
% lightset = [ambient diffuse specular] strength. See "help material"

switch nargin 
    case 0
        onoff = 'on';
        preset = 'default';
        lightset = [0.6 0.5 0.1];
    case 1
        onoff = 'on';
        lightset = [0.6 0.5 0.1];
    case 2
        lightset = [0.6 0.5 0.1];
end

switch preset
    case 'default'
        %
        switch onoff
            case 'on'
                v = get(gca,'View');
                delete(findall(gcf,'type','light'));
                view(0,0)
                c(1) = camlight(-90,20);
                c(2) = camlight(90,20);
                set(gca,'View',v)
                material(lightset);
            case 'off'
                delete(findall(gcf,'type','light'));
                disp('HEY! Who turned the light off??')
        end
        
    case 'relief'

        switch onoff
            case 'on'
                v = get(gca,'View');
                delete(findall(gcf,'type','light'));
                view(0,0);
                c(1) = camlight(-90,90);
                set(gca,'View',v)
                material(lightset);
            case 'off'
                delete(findall(gcf,'type','light'));
                disp('HEY! Who turned the light off??')
        end
end
