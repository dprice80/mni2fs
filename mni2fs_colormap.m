function cm = mni2fs_colormap(map, cbands, lightness)

if ischar(map)
    cm = colormap(map);
else
    cm = map;
end

if nargin < 3
    lightness = linspace(2,1,size(cbands,1));
end

for cbi = 1:length(lightness)
    cmlight = 1-(1-cm)/lightness(cbi);
    cmvals = linspace(min(cbands(:)), max(cbands(:)), size(cm,1))';
    ind = cmvals >= cbands(cbi,1) & cmvals <= cbands(cbi,2);
    cm(ind, :) = cmlight(ind,:);
end