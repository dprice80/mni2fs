function nii = mni2fs_load_nii(filename)
% Load nifti/analyse file without applying the sform/qform transform. The
% appropriate affine transform, taking into account sform and qform codes 
% is loaded into nii.transform, and should give the proper mapping from
% voxels to real world coordinates.

nii = load_untouch_nii(filename);
nii.loadmethod = 'mni2fs';
nii = mni2fs_load_affine(nii);
nii.transform = nii.hdr.hist.old_affine;