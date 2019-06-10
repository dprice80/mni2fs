function locs = mni2fs_coords_mni2inf(Vinf, Vmni, approxlocs)


for ii = 1:size(approxlocs,1)
    al = approxlocs(ii,:);
    
    % approxlocs = approximate locations in MNI space.
    % The script will find closes matches in Vmni and give coordinates from Vinf (inflated brain).
    
    l = repmat(al, [size(Vmni,1), 1]);
    d = sqrt(sum((Vmni - l).^2, 2));
    locs(ii, :) = Vinf(d == min(d),:); %#ok<AGROW>
end