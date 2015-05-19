# mni2fs
MNI2FS: Surface Rendering of MNI Space Volumes for MATLAB

Download the support files from 
github.com/dprice80/mni2fs/releases

A stand-alone MATLAB toolbox for rendering MNI space volumes on a canonical FreeSurfer inflated surface. In addition to general purpose use, it is ideal for rendering SPM or FieldTrip EEG/MEG results, since the canonical mesh used here matches those software perfectly. FreeSurfer is not required on the system. 

Tested in matlab 2013a with OpenGL (linux).

NOTE: This is the beta version, so please check your results carefully. Report any bugs.

Instructions

Download the repository *.m files

Download the support files from github.com/dprice80/mni2fs/releases
Unpack the support files into your mni2fs directory and add all folders to your path (see example). 
Note: You must have the /surf folder in your mni2fs root directory, but you can move all other folders elsewhere. If you have SPM on your path you might want to remove gifti-1.4 from the mni2fs root folder, as SPM will complain about this being in two places (this is the case for SPM 12).

