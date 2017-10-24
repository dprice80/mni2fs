function [T, NII] = mni2fs_loadnii(NII)
% Loads nifti image ensuring image is resliced, or checks nifti and
% reslices if necessary.
% NII = character or struct from NII = load_nii(fn)
% [fsdir, '/mri/T1.nii']

if ischar(NII)
    if ~exist(NII,'file') 
        error(['Not found: ', NII])
    end
    NII = load_nii(NII);
    T = [NII.hdr.hist.srow_x; NII.hdr.hist.srow_y; NII.hdr.hist.srow_z; 0 0 0 1];
elseif isstruct(NII)
    T = [NII.hdr.hist.srow_x; NII.hdr.hist.srow_y; NII.hdr.hist.srow_z; 0 0 0 1];
else
    error('Input should either be a struct or character array')
end
    I = eye(3);
    Ttest = T(1:3,1:3);
if ~all(Ttest(:) == I(:))
    disp(T)
    warning(sprintf('%s\nAffine transform detected (may produce undesireable results). \nAutomatically reslicing image. \nTo save time, reslice the image using reslice_nii(old.nii, new.nii)',NII.fileprefix)) %#ok<SPWRN>
    if exist([NII.fileprefix, '.nii'],'file')
        NII = reslice_return_nii([NII.fileprefix, '.nii']);
    elseif exist([NII.fileprefix, '.hdr'],'file')
        NII = reslice_return_nii([NII.fileprefix, '.hdr']);
    else
        error(['Not found (nii or hdr extension) ', NII.fileprefix])
    end
    T = [NII.hdr.hist.srow_x; NII.hdr.hist.srow_y; NII.hdr.hist.srow_z; 0 0 0 1];
end