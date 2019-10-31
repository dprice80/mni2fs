# mni2fs
MNI2FS: Surface Rendering of MNI Space Volumes for MATLAB 

All files are now included in the git repository so no need to download the release files.

MNI2FS is a stand-alone MATLAB toolbox for rendering MNI space volumes on a canonical FreeSurfer inflated surface. In addition to general purpose use, it is ideal for rendering SPM or FieldTrip EEG/MEG results, since the canonical mesh used here matches those software perfectly. FreeSurfer is not required. 

Instructions

Download the repository *.m files

open run_example in the root folder for examples of various functions. 

Use mni2fs_auto for a quick example (see run_example)

Use separate command line functions for more customisable scripting

Changelog: 
03/10/2017: Automatic in-memory reslicing added for cases where the nifti transformation matrix does not conform to the mni2fs requirements.
