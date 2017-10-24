function [Vsurf] = mni2fs_extract(S,V)
% Extracts values from an MNI space volume
% NII = nifti structure, which should have .img and .hdr fields
% V is an Mx3 matrix of vertex coordinates [X Y Z]
% InterpMethod can be either 'nearest' 'linear' 'cubic' 'spline'
% Vsurf is an Mx1 array of extracted values, one for each vertex

if ~isfield(S, 'surfchecks'); S.surfchecks = false; end

Tfs = S.T.Tfs;
Traw = S.T.Traw;

sz = size(S.mnivol.img);
[X, Y, Z] = ndgrid(1:sz(1),1:sz(2),1:sz(3));

X = X(:)-1; Y = Y(:)-1; Z = Z(:)-1;

L = length(X);

XYZraw = [X Y Z];

XYZraw = [XYZraw ones(L,1)]*Traw'; % transform from voxel to raw space

X = reshape(XYZraw(:,1),sz);
Y = reshape(XYZraw(:,2),sz);
Z = reshape(XYZraw(:,3),sz);

% % Get vertices in MNI space
% fid = fopen([fsdir, '/mri/regT1.mat'], 'r');
% TmriT1_to_mriorig = textscan(fid, '%f');
% TmriT1_to_mriorig = reshape(TmriT1_to_mriorig{1}, 4,4)';
% fclose(fid);

Vfsvox = round(V+128);

VT = [Vfsvox ones(length(Vfsvox),1)] * Tfs';
Vsurf = interpn(X,Y,Z,S.mnivol.img,VT(:,1),VT(:,2),VT(:,3),S.interpmethod);

% % Not currently used but don't delete
% Tfsras2vox = [ [-1 0 0 128]' [0 0 -1  128]' [ 0  1 0 128]' [ 0 0 0 1]' ];
% Tfsvox2ras = [ [-1 0 0 128]' [0 0  1 -128]' [ 0 -1 0 128]' [ 0 0 0 1]' ];

% Save checks to file. You should open these volumes and check that surfaces are in
% correct place.
if S.surfchecks == true;
    [~, NIIfs] = mni2fs_loadnii([S.fsdir, '/mri/T1resliced.nii']);
    for ii = 1:length(Vfsvox)
        NIIfs.img(Vfsvox(ii,1),Vfsvox(ii,2),Vfsvox(ii,3)) = 600;
    end
    save_nii(NIIfs, [S.fsdir, '/mri/test_surf_fs.nii'])
    
    [~, NIIout] = mni2fs_loadnii([S.fsdir, '/mri/T1_raw_resliced.nii']);
    Vrawvox = round([Vfsvox(:,1:3) ones(size(Vfsvox(:,1)))]*Tfs'*inv(Traw)');
    for ii = 1:length(Vrawvox)
        NIIout.img(Vrawvox(ii,1),Vrawvox(ii,2),Vrawvox(ii,3)) = 600;
    end
    save_nii(NIIout,[S.fsdir, '/mri/test_surf_raw.nii'])
end
