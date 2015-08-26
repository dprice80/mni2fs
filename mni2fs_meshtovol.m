function [NII] = mni2fs_meshtovol(data,g,vol,smooth,volsmooth)
% Test function for converting from a colin brain to a high res mesh
% Uses some functionality grafted from SPM12

vol = spm_vol(vol);

g = export(g,'patch');
GL = spm_mesh_smooth(g);

datasm = spm_mesh_smooth(GL,data,smooth);

load('/imaging/dp01/results/cc280/picnaming_sourceloc/R2SigmoidFits/Fits.mat','Fit','ff','q')

Voutones = spm_mesh_to_grid(g,vol,ones(size(datasm)));
Vout = spm_mesh_to_grid(g,vol,datasm);

NII = load_nii('/imaging/dp01/templates/MNI152_T1_2mm.nii');

Vout = smooth3(Vout, 'gaussian',volsmooth(1),volsmooth(2));
Voutones = smooth3(Voutones, 'gaussian',volsmooth(1),volsmooth(2));

Vout = Vout./Voutones;

NII.img = Vout;
NII.img(isnan(NII.img)) = 0;
NII.hdr.dime.datatype = 64;
NII.hdr.dime.bitpix = 64;
NII.hdr.dime.cal_max = max(abs(NII.img(:)));
NII.hdr.dime.cal_min = 0;
