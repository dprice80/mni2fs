function [Vsurf] = mni2fs_extract(NII,V,InterpMethod)
% Extracts values from an MNI space volume
% NII = nifti structure, which should have .img and .hdr fields
% V is an Mx3 matrix of vertex coordinates [X Y Z]
% InterpMethod can be either 'nearest' 'linear' 'cubic' 'spline'
% Vsurf is an Mx1 array of extracted values, one for each vertex

Tmni = [NII.hdr.hist.srow_x; NII.hdr.hist.srow_y; NII.hdr.hist.srow_z; 0 0 0 1];

sz = size(NII.img);
[X, Y, Z] = ndgrid(1:sz(1),1:sz(2),1:sz(3));

X = X(:)-1; Y = Y(:)-1; Z = Z(:)-1;

L = length(X);

XYZmni = [X Y Z];

XYZmni = [XYZmni ones(L,1)]*Tmni'; % transform from voxel to mni space

X = reshape(XYZmni(:,1),sz);
Y = reshape(XYZmni(:,2),sz);
Z = reshape(XYZmni(:,3),sz);

% Get veritces in MNI space
thisfolder = fileparts(mfilename('fullpath'));
load(fullfile(thisfolder,'surf/transmats.mat'),'Tfstovox_rcor','Trsvoxtomni_rcor');
V = [V ones(length(V),1)]*Tfstovox_rcor'*Trsvoxtomni_rcor';
Vsurf = interpn(X,Y,Z,NII.img,V(:,1),V(:,2),V(:,3),InterpMethod);

% % Save check to file
% Vmnivox = round(V*inv(Tmni)');
% for ii = 1:length(Vmnivox)
%     NII.img(Vmnivox(ii,1),Vmnivox(ii,2),Vmnivox(ii,3)) = NII.img(Vmnivox(ii,1),Vmnivox(ii,2),Vmnivox(ii,3))+0.2;
% end
% save_untouch_nii(NII,'/imaging/dp01/toolboxes/mni2fs/test_surf.nii')
