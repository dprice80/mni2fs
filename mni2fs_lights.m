function c = mni2fs_lights(onoff,lightset)
% Turn on/off the lights! 
% onoff = 'on' or 'off'
% lightset = [ambient diffuse specular] strength. See "help material"

if nargin == 0
    onoff = 'on';
end

if nargin < 2
    lightset = [0.6 0.5 0.1];
end
%
switch onoff
    case 'on'
        v = get(gca,'View');
        delete(findall(gcf,'type','light'));
        view(0,0)
%         c(1) = camlight(v(1)-90,v(2)+20);
%         c(2) = camlight(v(1)+90,v(2)+20);
        c(1) = camlight(-90,20);
        c(2) = camlight(90,20);
        set(gca,'View',v)
        material(lightset);
    case 'off'
        delete(findall(gcf,'type','light'));
        disp('HEY! Who turned the light off??')
end

