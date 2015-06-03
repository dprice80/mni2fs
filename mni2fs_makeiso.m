function [iso] = mni2fs_makeiso(NII,maskvals,colorvec,smoothval,Alpha,smoothsurf)

if ~isstruct(NII)
    NII = load_nii(NII);
end

niimask = zeros(size(NII.img));
for ri = 1:length(maskvals)
    niimask(NII.img == maskvals(ri)) = 1;
end

sz = size(NII.img);
[X, Y, Z] = ndgrid(1:sz(1),1:sz(2),1:sz(3));
X = X(:)-1; Y = Y(:)-1; Z = Z(:)-1;
L = length(X);

Tmni = [NII.hdr.hist.srow_x; NII.hdr.hist.srow_y; NII.hdr.hist.srow_z; 0 0 0 1];
XYZmni = [X Y Z ones(L,1)]*Tmni';

thisfolder = fileparts(mfilename('fullpath'));
load(fullfile(thisfolder,'surf/transmats.mat'),'Tfstovox_rcor','Trsvoxtomni_rcor');
XYZmni(:,4) = 1;
XYZ = XYZmni*Trsvoxtomni_rcor*Tfstovox_rcor;

if smoothval > 0
    niimask = smooth3(niimask,'gaussian',smoothval);
end

iso = isosurface(reshape(XYZ(:,1),sz),reshape(XYZ(:,2),sz),reshape(XYZ(:,3),sz),niimask,0.5);

if smoothsurf == 1
    iso.vertices = SurfaceSmooth(iso.vertices, iso.faces, NII.hdr.dime.pixdim(2), 0.01*NII.hdr.dime.pixdim(2), 100, 1, 1);
end

p = patch('vertices',iso.vertices,'faces',iso.faces,'FaceVertexCData',repmat(colorvec,length(iso.vertices),1),'FaceAlpha',Alpha);%,'VertexNormals',norms);

shading flat

axis equal
axis vis3d
freezeColors
hold on
axis off
rotate3d
