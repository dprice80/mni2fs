function colrescaled = mni2fs_rescale_colormap(col,clims)
% Rescales a colormap. 
% Input col = a numeric color map obtained using colormap('option')
% clims = two element vector of positive scalars e.g. [0.2 1]
% col will be resampled so that clims(2) related to the +/- max of the
% colormap while clims(1) relates to the +/- min of the. The region between
% -min and +min will be recolored to represent 0.

L = (length(col)-1)/2; % get half index length (first index is 1)
cmin = clims(1); % get clims
cmax = clims(2);
scale = L/cmax; % get index length (from middle to max) to clim scaling
cmin = cmin*scale/2+L/2; % scale cmin and add intercept
cmax = cmax*scale; % scale cmax
deriv = L/(L-cmin); % calculate derivative for interpolation (will be more accurate than rounding off)
ucol = linspace(L-L*deriv,L,L*2+1); % calculate first slope for resampling reference vector
ucol(ucol < 0) = 0;
lcol = linspace(0,L*deriv,L*2+1);
lcol(lcol > L) = L;
ramp = ucol+lcol+1; % add upper and lower ramps
for ii = 1:3
    colrescaled(:,ii) = interpn([1:L*2+1]',col(:,ii),ramp','cubic'); % interpolate new colors for each channel
end
colrescaled(colrescaled > 1) = 1; % set extrapolated values to
colrescaled(colrescaled < 0) = 0;