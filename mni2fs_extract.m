function [Vsurf] = mni2fs_extract(NII,V,InterpMethod,ind4d,qualcheck)
% Extracts values from an MNI space volume
% NII = nifti structure, which should have .img and .hdr fields
% V is an Mx3 matrix of vertex coordinates [X Y Z]
% InterpMethod can be either 'nearest' 'linear' 'cubic' 'spline'
% Vsurf is an Mx1 array of extracted values, one for each vertex

if nargin <= 4
    ind4d = 1;
    qualcheck = false;
end

Tmni = [NII.hdr.hist.srow_x; NII.hdr.hist.srow_y; NII.hdr.hist.srow_z; 0 0 0 1];
if any([NII.hdr.hist.quatern_b NII.hdr.hist.quatern_c NII.hdr.hist.quatern_d])
    niitrans = mni2fs_load_affine(NII);
    Tmni = niitrans.hdr.hist.old_affine;
end

sz = size(NII.img);
sz = sz(1:3);

[X, Y, Z] = ndgrid(0:sz(1)-1,0:sz(2)-1,0:sz(3)-1);

XYZmni = [reshape(permute(cat(4, X,Y,Z),[4 1 2 3]), 3, [])' ones(numel(X),1)]*Tmni';

X = reshape(XYZmni(:,1),sz);
Y = reshape(XYZmni(:,2),sz);
Z = reshape(XYZmni(:,3),sz);

% Get vertices in MNI space
thisfolder = fileparts(mfilename('fullpath'));
load(fullfile(thisfolder,'surf/transmats.mat'),'Tfstovox_rcor','Trsvoxtomni_rcor');
V = [V ones(length(V),1)]*Tfstovox_rcor'*Trsvoxtomni_rcor';
Vsurf = interpn(X,Y,Z,NII.img(:,:,:,ind4d),V(:,1),V(:,2),V(:,3),InterpMethod);


%% Save check to file
if qualcheck
    Vmnivox = round(V*inv(Tmni)')+1;
    NIIs = NII;
    ind = sub2ind(size(NII.img), Vmnivox(:,1), Vmnivox(:,2), Vmnivox(:,3));
    NIIs.img(ind) = NIIs.img(ind)+max(NIIs.img(:));
    save_untouch_nii(NIIs,'/imaging/dp01/temp/test_surf.hdr')
    view_nii(load_nii('/imaging/dp01/temp/test_surf.hdr'))
end
