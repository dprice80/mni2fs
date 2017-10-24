function s = mni2fs_readsurf(fn)

if strfind(fn,'.gii')
    s = export(gifti(fn));
else
    [s.vertices,s.faces] = read_surf(fn);
    s.faces = s.faces + 1;
end