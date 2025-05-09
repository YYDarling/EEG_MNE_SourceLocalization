\n\n#---------------------------------
# New invocation of recon-all Fri Mar 28 15:02:50 CDT 2025 
\n mri_convert /Applications/freesurfer/8.0.0/subjects/sub_125_T1_shrink.nii /Applications/freesurfer/8.0.0/subjects/sub125/mri/orig/001.mgz \n
#--------------------------------------------
#@# MotionCor Fri Mar 28 15:02:54 CDT 2025
\n cp /Applications/freesurfer/8.0.0/subjects/sub125/mri/orig/001.mgz /Applications/freesurfer/8.0.0/subjects/sub125/mri/rawavg.mgz \n
\n mri_info /Applications/freesurfer/8.0.0/subjects/sub125/mri/rawavg.mgz \n
\n mri_convert /Applications/freesurfer/8.0.0/subjects/sub125/mri/rawavg.mgz /Applications/freesurfer/8.0.0/subjects/sub125/mri/orig.mgz --conform \n
\n mri_add_xform_to_header -c /Applications/freesurfer/8.0.0/subjects/sub125/mri/transforms/talairach.xfm /Applications/freesurfer/8.0.0/subjects/sub125/mri/orig.mgz /Applications/freesurfer/8.0.0/subjects/sub125/mri/orig.mgz \n
\n mri_info /Applications/freesurfer/8.0.0/subjects/sub125/mri/orig.mgz \n
\n mri_synthstrip --threads 1 -i /Applications/freesurfer/8.0.0/subjects/sub125/mri/orig.mgz -o /Applications/freesurfer/8.0.0/subjects/sub125/mri/synthstrip.mgz \n
\n mri_synthseg --i /Applications/freesurfer/8.0.0/subjects/sub125/mri/orig.mgz --o /Applications/freesurfer/8.0.0/subjects/sub125/mri/synthseg.rca.mgz --threads 1 --vol /Applications/freesurfer/8.0.0/subjects/sub125/stats/synthseg.vol.csv --keepgeom --addctab --cpu \n
\n fs-synthmorph-reg --s sub125 --threads 1 --i /Applications/freesurfer/8.0.0/subjects/sub125/mri/orig.mgz --test \n
#--------------------------------------------
#@# Nu Intensity Correction Fri Mar 28 15:43:55 CDT 2025
\n mri_nu_correct.mni --i orig.mgz --o nu.mgz --uchar transforms/talairach.xfm --n 2 --ants-n4 \n
\n mri_add_xform_to_header -c /Applications/freesurfer/8.0.0/subjects/sub125/mri/transforms/talairach.xfm nu.mgz nu.mgz \n
#--------------------------------------------
#@# Intensity Normalization Fri Mar 28 15:45:06 CDT 2025
\n mri_normalize -g 1 -seed 1234 -mprage nu.mgz T1.mgz \n
#--------------------------------------
\n#@# MCADura Segmentation Fri Mar 28 15:46:09 CDT 2025
#--------------------------------------
\n#@# VSinus Segmentation Fri Mar 28 15:46:30 CDT 2025
\n mri_mask /Applications/freesurfer/8.0.0/subjects/sub125/mri/T1.mgz /Applications/freesurfer/8.0.0/subjects/sub125/mri/synthstrip.mgz /Applications/freesurfer/8.0.0/subjects/sub125/mri/brainmask.mgz \n
#-------------------------------------
#@# EM Registration Fri Mar 28 15:46:59 CDT 2025
\n mri_em_register -uns 3 -mask brainmask.mgz nu.mgz /Applications/freesurfer/8.0.0/average/RB_all_2020-01-02.gca transforms/talairach.lta \n
#--------------------------------------
#@# CA Normalize Fri Mar 28 15:51:23 CDT 2025
\n mri_ca_normalize -c ctrl_pts.mgz -mask brainmask.mgz nu.mgz /Applications/freesurfer/8.0.0/average/RB_all_2020-01-02.gca transforms/talairach.lta norm.mgz \n
#--------------------------------------
\n#@# EntoWM Segmentation Fri Mar 28 15:52:04 CDT 2025
#--------------------------------------
#@# CC Seg Fri Mar 28 15:52:32 CDT 2025
\n seg2cc --s sub125 \n
#--------------------------------------
#@# Merge ASeg Fri Mar 28 15:52:48 CDT 2025
\n cp aseg.auto.mgz aseg.presurf.mgz \n
#--------------------------------------------
#@# Intensity Normalization2 Fri Mar 28 15:52:48 CDT 2025
\n mri_normalize -seed 1234 -mprage -aseg aseg.presurf.mgz -mask brainmask.mgz norm.mgz brain.mgz \n
#--------------------------------------------
#@# Mask BFS Fri Mar 28 15:54:19 CDT 2025
\n mri_mask -T 5 brain.mgz brainmask.mgz brain.finalsurfs.mgz \n
\n mri_mask -oval 1 -invert brain.finalsurfs.mgz /Applications/freesurfer/8.0.0/subjects/sub125/mri/mca-dura.mgz brain.finalsurfs.mgz \n
\n mri_mask -oval 1 -invert brain.finalsurfs.mgz /Applications/freesurfer/8.0.0/subjects/sub125/mri/vsinus.mgz brain.finalsurfs.mgz \n
\n mri_edit_wm_with_aseg -sa-fix-ento-wm entowm.mgz 2 255 255 brain.finalsurfs.mgz brain.finalsurfs.mgz \n
\n mri_edit_wm_with_aseg -sa-fix-acj aseg.presurf.mgz 255 255 brain.finalsurfs.mgz brain.finalsurfs.mgz \n
#--------------------------------------------
#@# WM Segmentation Fri Mar 28 15:54:24 CDT 2025
\n AntsDenoiseImageFs -i brain.mgz -o antsdn.brain.mgz \n
\n mri_segment -wsizemm 13 -mprage antsdn.brain.mgz wm.seg.mgz \n
\n mri_edit_wm_with_aseg -keep-in -fix-ento-wm entowm.mgz 3 255 255 -fix-acj aseg.presurf.mgz 255 255 -fill-seg-wm -fix-scm-ha 1 wm.seg.mgz brain.mgz aseg.presurf.mgz wm.asegedit.mgz \n
\n mri_pretess wm.asegedit.mgz wm norm.mgz wm.mgz \n
Fixing entowm in wm.mgz
\n mri_edit_wm_with_aseg -sa-fix-ento-wm entowm.mgz 3 255 255 wm.mgz wm.mgz \n
Fixing ACJ in wm.mgz
\n mri_edit_wm_with_aseg -sa-fix-acj aseg.presurf.mgz 255 255 wm.mgz wm.mgz \n
#--------------------------------------------
#@# Fill Fri Mar 28 15:56:02 CDT 2025
\n mri_fill -a ../scripts/ponscc.cut.log -xform transforms/talairach.lta -segmentation aseg.presurf.mgz -ctab /Applications/freesurfer/8.0.0/SubCorticalMassLUT.txt wm.mgz filled.mgz \n
 cp filled.mgz filled.auto.mgz
#--------------------------------------------
#@# Tessellate lh Fri Mar 28 15:56:38 CDT 2025
\n mri_pretess ../mri/filled.mgz 255 ../mri/norm.mgz ../mri/filled-pretess255.mgz \n
\n mri_tessellate ../mri/filled-pretess255.mgz 255 ../surf/lh.orig.nofix \n
\n rm -f ../mri/filled-pretess255.mgz \n
\n mris_extract_main_component ../surf/lh.orig.nofix ../surf/lh.orig.nofix \n
#--------------------------------------------
#@# Tessellate rh Fri Mar 28 15:56:40 CDT 2025
\n mri_pretess ../mri/filled.mgz 127 ../mri/norm.mgz ../mri/filled-pretess127.mgz \n
\n mri_tessellate ../mri/filled-pretess127.mgz 127 ../surf/rh.orig.nofix \n
\n rm -f ../mri/filled-pretess127.mgz \n
\n mris_extract_main_component ../surf/rh.orig.nofix ../surf/rh.orig.nofix \n
#--------------------------------------------
#@# Smooth1 lh Fri Mar 28 15:56:43 CDT 2025
\n mris_smooth -nw -seed 1234 ../surf/lh.orig.nofix ../surf/lh.smoothwm.nofix \n
#--------------------------------------------
#@# Smooth1 rh Fri Mar 28 15:56:45 CDT 2025
\n mris_smooth -nw -seed 1234 ../surf/rh.orig.nofix ../surf/rh.smoothwm.nofix \n
#--------------------------------------------
#@# Inflation1 lh Fri Mar 28 15:56:47 CDT 2025
\n mris_inflate -no-save-sulc ../surf/lh.smoothwm.nofix ../surf/lh.inflated.nofix \n
#--------------------------------------------
#@# Inflation1 rh Fri Mar 28 15:57:00 CDT 2025
\n mris_inflate -no-save-sulc ../surf/rh.smoothwm.nofix ../surf/rh.inflated.nofix \n
#--------------------------------------------
#@# QSphere lh Fri Mar 28 15:57:13 CDT 2025
\n mris_sphere -q -p 6 -a 128 -seed 1234 ../surf/lh.inflated.nofix ../surf/lh.qsphere.nofix \n
#--------------------------------------------
#@# QSphere rh Fri Mar 28 15:58:45 CDT 2025
\n mris_sphere -q -p 6 -a 128 -seed 1234 ../surf/rh.inflated.nofix ../surf/rh.qsphere.nofix \n
#@# Fix Topology lh Fri Mar 28 16:00:32 CDT 2025
\n mris_fix_topology -threads 1 -mgz -sphere qsphere.nofix -inflated inflated.nofix -orig orig.nofix -out orig.premesh -ga -seed 1234 -threads 1 sub125 lh \n
#@# Fix Topology rh Fri Mar 28 16:01:44 CDT 2025
\n mris_fix_topology -threads 1 -mgz -sphere qsphere.nofix -inflated inflated.nofix -orig orig.nofix -out orig.premesh -ga -seed 1234 -threads 1 sub125 rh \n
\n mris_euler_number ../surf/lh.orig.premesh \n
\n mris_euler_number ../surf/rh.orig.premesh \n
\n mris_remesh --remesh --iters 3 --input /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.orig.premesh --output /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.orig \n
\n mris_remesh --remesh --iters 3 --input /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.orig.premesh --output /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.orig \n
\n mris_remove_intersection ../surf/lh.orig ../surf/lh.orig \n
\n rm -f ../surf/lh.inflated \n
\n mris_remove_intersection ../surf/rh.orig ../surf/rh.orig \n
\n rm -f ../surf/rh.inflated \n
#--------------------------------------------
#@# AutoDetGWStats lh Fri Mar 28 16:03:48 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_autodet_gwstats --o ../surf/autodet.gw.stats.lh.dat --i brain.finalsurfs.mgz --wm wm.mgz --surf ../surf/lh.orig.premesh
#--------------------------------------------
#@# AutoDetGWStats rh Fri Mar 28 16:03:50 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_autodet_gwstats --o ../surf/autodet.gw.stats.rh.dat --i brain.finalsurfs.mgz --wm wm.mgz --surf ../surf/rh.orig.premesh
#--------------------------------------------
#@# WhitePreAparc lh Fri Mar 28 16:03:52 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --adgws-in ../surf/autodet.gw.stats.lh.dat --wm wm.mgz --threads 1 --invol brain.finalsurfs.mgz --lh --i ../surf/lh.orig --o ../surf/lh.white.preaparc --white --seg aseg.presurf.mgz --restore-255 --nsmooth 5 --rip-bg-no-annot --rip-bg --rip-bg-lof --restore-255 --outvol mrisps.wpa.mgz
#--------------------------------------------
#@# WhitePreAparc rh Fri Mar 28 16:06:14 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --adgws-in ../surf/autodet.gw.stats.rh.dat --wm wm.mgz --threads 1 --invol brain.finalsurfs.mgz --rh --i ../surf/rh.orig --o ../surf/rh.white.preaparc --white --seg aseg.presurf.mgz --restore-255 --nsmooth 5 --rip-bg-no-annot --rip-bg --rip-bg-lof --restore-255 --outvol mrisps.wpa.mgz
#--------------------------------------------
#@# CortexLabel lh Fri Mar 28 16:08:41 CDT 2025
#--------------------------------------------
#@# CortexLabel+HipAmyg lh Fri Mar 28 16:08:58 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mri_label2label --label-cortex ../surf/lh.white.preaparc aseg.presurf.mgz 1 ../label/lh.cortex+hipamyg.label
#--------------------------------------------
#@# CortexLabel rh Fri Mar 28 16:09:09 CDT 2025
#--------------------------------------------
#@# CortexLabel+HipAmyg rh Fri Mar 28 16:09:24 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mri_label2label --label-cortex ../surf/rh.white.preaparc aseg.presurf.mgz 1 ../label/rh.cortex+hipamyg.label
#--------------------------------------------
#@# Smooth2 lh Fri Mar 28 16:09:35 CDT 2025
\n mris_smooth -n 3 -nw -seed 1234 ../surf/lh.white.preaparc ../surf/lh.smoothwm \n
#--------------------------------------------
#@# Smooth2 rh Fri Mar 28 16:09:38 CDT 2025
\n mris_smooth -n 3 -nw -seed 1234 ../surf/rh.white.preaparc ../surf/rh.smoothwm \n
#--------------------------------------------
#@# Inflation2 lh Fri Mar 28 16:09:40 CDT 2025
\n mris_inflate ../surf/lh.smoothwm ../surf/lh.inflated \n
#--------------------------------------------
#@# Inflation2 rh Fri Mar 28 16:09:55 CDT 2025
\n mris_inflate ../surf/rh.smoothwm ../surf/rh.inflated \n
#--------------------------------------------
#@# Curv .H and .K lh Fri Mar 28 16:10:10 CDT 2025
\n mris_curvature -w -seed 1234 lh.white.preaparc \n
\n mris_curvature -seed 1234 -thresh .999 -n -a 5 -w -distances 10 10 lh.inflated \n
#--------------------------------------------
#@# Curv .H and .K rh Fri Mar 28 16:10:45 CDT 2025
\n mris_curvature -w -seed 1234 rh.white.preaparc \n
\n mris_curvature -seed 1234 -thresh .999 -n -a 5 -w -distances 10 10 rh.inflated \n
#--------------------------------------------
#@# Sphere lh Fri Mar 28 16:11:21 CDT 2025
\n mris_sphere -threads 1 -seed 1234 ../surf/lh.inflated ../surf/lh.sphere \n
#--------------------------------------------
#@# Sphere rh Fri Mar 28 16:18:49 CDT 2025
\n mris_sphere -threads 1 -seed 1234 ../surf/rh.inflated ../surf/rh.sphere \n
#--------------------------------------------
#@# Surf Reg lh Fri Mar 28 16:27:26 CDT 2025
\n mris_register -curv -threads 1 ../surf/lh.sphere /Applications/freesurfer/8.0.0/average/lh.folding.atlas.acfb40.noaparc.i12.2016-08-02.tif ../surf/lh.sphere.reg \n
\n ln -sf lh.sphere.reg lh.fsaverage.sphere.reg \n
#--------------------------------------------
#@# Surf Reg rh Fri Mar 28 16:40:25 CDT 2025
\n mris_register -curv -threads 1 ../surf/rh.sphere /Applications/freesurfer/8.0.0/average/rh.folding.atlas.acfb40.noaparc.i12.2016-08-02.tif ../surf/rh.sphere.reg \n
\n ln -sf rh.sphere.reg rh.fsaverage.sphere.reg \n
#--------------------------------------------
#@# Jacobian white lh Fri Mar 28 16:53:54 CDT 2025
\n mris_jacobian ../surf/lh.white.preaparc ../surf/lh.sphere.reg ../surf/lh.jacobian_white \n
#--------------------------------------------
#@# Jacobian white rh Fri Mar 28 16:53:55 CDT 2025
\n mris_jacobian ../surf/rh.white.preaparc ../surf/rh.sphere.reg ../surf/rh.jacobian_white \n
#--------------------------------------------
#@# AvgCurv lh Fri Mar 28 16:53:56 CDT 2025
\n mrisp_paint -a 5 /Applications/freesurfer/8.0.0/average/lh.folding.atlas.acfb40.noaparc.i12.2016-08-02.tif#6 ../surf/lh.sphere.reg ../surf/lh.avg_curv \n
#--------------------------------------------
#@# AvgCurv rh Fri Mar 28 16:53:57 CDT 2025
\n mrisp_paint -a 5 /Applications/freesurfer/8.0.0/average/rh.folding.atlas.acfb40.noaparc.i12.2016-08-02.tif#6 ../surf/rh.sphere.reg ../surf/rh.avg_curv \n
#-----------------------------------------
#@# Cortical Parc lh Fri Mar 28 16:53:57 CDT 2025
\n mris_ca_label -l ../label/lh.cortex.label -aseg ../mri/aseg.presurf.mgz -seed 1234 sub125 lh ../surf/lh.sphere.reg /Applications/freesurfer/8.0.0/average/lh.DKaparc.atlas.acfb40.noaparc.i12.2016-08-02.gcs ../label/lh.aparc.annot \n
#-----------------------------------------
#@# Cortical Parc rh Fri Mar 28 16:54:03 CDT 2025
\n mris_ca_label -l ../label/rh.cortex.label -aseg ../mri/aseg.presurf.mgz -seed 1234 sub125 rh ../surf/rh.sphere.reg /Applications/freesurfer/8.0.0/average/rh.DKaparc.atlas.acfb40.noaparc.i12.2016-08-02.gcs ../label/rh.aparc.annot \n
#--------------------------------------------
#@# WhiteSurfs lh Fri Mar 28 16:54:09 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --adgws-in ../surf/autodet.gw.stats.lh.dat --seg aseg.presurf.mgz --threads 1 --wm wm.mgz --invol brain.finalsurfs.mgz --lh --i ../surf/lh.white.preaparc --o ../surf/lh.white --white --nsmooth 0 --rip-label ../label/lh.cortex.label --rip-bg --rip-surf ../surf/lh.white.preaparc --aparc ../label/lh.aparc.annot --restore-255 --restore-255 --outvol mrisps.white.mgz --rip-bg-lof
#--------------------------------------------
#@# WhiteSurfs rh Fri Mar 28 16:56:09 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --adgws-in ../surf/autodet.gw.stats.rh.dat --seg aseg.presurf.mgz --threads 1 --wm wm.mgz --invol brain.finalsurfs.mgz --rh --i ../surf/rh.white.preaparc --o ../surf/rh.white --white --nsmooth 0 --rip-label ../label/rh.cortex.label --rip-bg --rip-surf ../surf/rh.white.preaparc --aparc ../label/rh.aparc.annot --restore-255 --restore-255 --outvol mrisps.white.mgz --rip-bg-lof
#--------------------------------------------
#@# T1PialSurf lh Fri Mar 28 16:58:16 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --adgws-in ../surf/autodet.gw.stats.lh.dat --seg aseg.presurf.mgz --threads 1 --wm wm.mgz --invol brain.finalsurfs.mgz --lh --i ../surf/lh.white --o ../surf/lh.pial.T1 --pial --nsmooth 0 --rip-label ../label/lh.cortex+hipamyg.label --pin-medial-wall ../label/lh.cortex.label --aparc ../label/lh.aparc.annot --repulse-surf ../surf/lh.white --white-surf ../surf/lh.white --restore-255
#--------------------------------------------
#@# T1PialSurf rh Fri Mar 28 17:00:51 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --adgws-in ../surf/autodet.gw.stats.rh.dat --seg aseg.presurf.mgz --threads 1 --wm wm.mgz --invol brain.finalsurfs.mgz --rh --i ../surf/rh.white --o ../surf/rh.pial.T1 --pial --nsmooth 0 --rip-label ../label/rh.cortex+hipamyg.label --pin-medial-wall ../label/rh.cortex.label --aparc ../label/rh.aparc.annot --repulse-surf ../surf/rh.white --white-surf ../surf/rh.white --restore-255
#@# white curv lh Fri Mar 28 17:03:27 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --curv-map ../surf/lh.white 2 10 ../surf/lh.curv
#@# white area lh Fri Mar 28 17:03:28 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --area-map ../surf/lh.white ../surf/lh.area
#@# pial curv lh Fri Mar 28 17:03:29 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --curv-map ../surf/lh.pial 2 10 ../surf/lh.curv.pial
#@# pial area lh Fri Mar 28 17:03:30 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --area-map ../surf/lh.pial ../surf/lh.area.pial
#@# thickness lh Fri Mar 28 17:03:31 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --thickness ../surf/lh.white ../surf/lh.pial 20 5 ../surf/lh.thickness
#@# area and vertex vol lh Fri Mar 28 17:03:53 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
#@# white curv rh Fri Mar 28 17:03:55 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --curv-map ../surf/rh.white 2 10 ../surf/rh.curv
#@# white area rh Fri Mar 28 17:03:56 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --area-map ../surf/rh.white ../surf/rh.area
#@# pial curv rh Fri Mar 28 17:03:57 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --curv-map ../surf/rh.pial 2 10 ../surf/rh.curv.pial
#@# pial area rh Fri Mar 28 17:03:58 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --area-map ../surf/rh.pial ../surf/rh.area.pial
#@# thickness rh Fri Mar 28 17:03:59 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
mris_place_surface --thickness ../surf/rh.white ../surf/rh.pial 20 5 ../surf/rh.thickness
#@# area and vertex vol rh Fri Mar 28 17:04:22 CDT 2025
cd /Applications/freesurfer/8.0.0/subjects/sub125/mri
\n#-----------------------------------------
#@# Curvature Stats lh Fri Mar 28 17:04:23 CDT 2025
\n mris_curvature_stats -m --writeCurvatureFiles -G -o ../stats/lh.curv.stats -F smoothwm sub125 lh curv sulc \n
\n#-----------------------------------------
#@# Curvature Stats rh Fri Mar 28 17:04:25 CDT 2025
\n mris_curvature_stats -m --writeCurvatureFiles -G -o ../stats/rh.curv.stats -F smoothwm sub125 rh curv sulc \n
#--------------------------------------------
#@# Cortical ribbon mask Fri Mar 28 17:04:27 CDT 2025
\n mris_volmask --aseg_name aseg.presurf --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon sub125 \n
#-----------------------------------------
#@# Cortical Parc 2 lh Fri Mar 28 17:08:13 CDT 2025
\n mris_ca_label -l ../label/lh.cortex.label -aseg ../mri/aseg.presurf.mgz -seed 1234 sub125 lh ../surf/lh.sphere.reg /Applications/freesurfer/8.0.0/average/lh.CDaparc.atlas.acfb40.noaparc.i12.2016-08-02.gcs ../label/lh.aparc.a2009s.annot \n
#-----------------------------------------
#@# Cortical Parc 2 rh Fri Mar 28 17:08:21 CDT 2025
\n mris_ca_label -l ../label/rh.cortex.label -aseg ../mri/aseg.presurf.mgz -seed 1234 sub125 rh ../surf/rh.sphere.reg /Applications/freesurfer/8.0.0/average/rh.CDaparc.atlas.acfb40.noaparc.i12.2016-08-02.gcs ../label/rh.aparc.a2009s.annot \n
#-----------------------------------------
#@# Cortical Parc 3 lh Fri Mar 28 17:08:29 CDT 2025
\n mris_ca_label -l ../label/lh.cortex.label -aseg ../mri/aseg.presurf.mgz -seed 1234 sub125 lh ../surf/lh.sphere.reg /Applications/freesurfer/8.0.0/average/lh.DKTaparc.atlas.acfb40.noaparc.i12.2016-08-02.gcs ../label/lh.aparc.DKTatlas.annot \n
#-----------------------------------------
#@# Cortical Parc 3 rh Fri Mar 28 17:08:35 CDT 2025
\n mris_ca_label -l ../label/rh.cortex.label -aseg ../mri/aseg.presurf.mgz -seed 1234 sub125 rh ../surf/rh.sphere.reg /Applications/freesurfer/8.0.0/average/rh.DKTaparc.atlas.acfb40.noaparc.i12.2016-08-02.gcs ../label/rh.aparc.DKTatlas.annot \n
#-----------------------------------------
#@# WM/GM Contrast lh Fri Mar 28 17:08:41 CDT 2025
\n pctsurfcon --s sub125 --lh-only \n
#-----------------------------------------
#@# WM/GM Contrast rh Fri Mar 28 17:08:44 CDT 2025
\n pctsurfcon --s sub125 --rh-only \n
#-----------------------------------------
#@# Relabel Hypointensities Fri Mar 28 17:08:46 CDT 2025
\n mri_relabel_hypointensities aseg.presurf.mgz ../surf aseg.presurf.hypos.mgz \n
#-----------------------------------------
#@# APas-to-ASeg Fri Mar 28 17:08:55 CDT 2025
\n mri_surf2volseg --o aseg.mgz --i aseg.presurf.hypos.mgz --fix-presurf-with-ribbon /Applications/freesurfer/8.0.0/subjects/sub125/mri/ribbon.mgz --threads 1 --lh-cortex-mask /Applications/freesurfer/8.0.0/subjects/sub125/label/lh.cortex.label --lh-white /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.white --lh-pial /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.pial --rh-cortex-mask /Applications/freesurfer/8.0.0/subjects/sub125/label/rh.cortex.label --rh-white /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.white --rh-pial /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.pial \n
\n mri_brainvol_stats --subject sub125 \n
#-----------------------------------------
#@# AParc-to-ASeg aparc Fri Mar 28 17:09:03 CDT 2025
\n mri_surf2volseg --o aparc+aseg.mgz --label-cortex --i aseg.mgz --threads 1 --lh-annot /Applications/freesurfer/8.0.0/subjects/sub125/label/lh.aparc.annot 1000 --lh-cortex-mask /Applications/freesurfer/8.0.0/subjects/sub125/label/lh.cortex.label --lh-white /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.white --lh-pial /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.pial --rh-annot /Applications/freesurfer/8.0.0/subjects/sub125/label/rh.aparc.annot 2000 --rh-cortex-mask /Applications/freesurfer/8.0.0/subjects/sub125/label/rh.cortex.label --rh-white /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.white --rh-pial /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.pial \n
#-----------------------------------------
#@# AParc-to-ASeg aparc.a2009s Fri Mar 28 17:10:39 CDT 2025
\n mri_surf2volseg --o aparc.a2009s+aseg.mgz --label-cortex --i aseg.mgz --threads 1 --lh-annot /Applications/freesurfer/8.0.0/subjects/sub125/label/lh.aparc.a2009s.annot 11100 --lh-cortex-mask /Applications/freesurfer/8.0.0/subjects/sub125/label/lh.cortex.label --lh-white /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.white --lh-pial /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.pial --rh-annot /Applications/freesurfer/8.0.0/subjects/sub125/label/rh.aparc.a2009s.annot 12100 --rh-cortex-mask /Applications/freesurfer/8.0.0/subjects/sub125/label/rh.cortex.label --rh-white /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.white --rh-pial /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.pial \n
#-----------------------------------------
#@# AParc-to-ASeg aparc.DKTatlas Fri Mar 28 17:12:16 CDT 2025
\n mri_surf2volseg --o aparc.DKTatlas+aseg.mgz --label-cortex --i aseg.mgz --threads 1 --lh-annot /Applications/freesurfer/8.0.0/subjects/sub125/label/lh.aparc.DKTatlas.annot 1000 --lh-cortex-mask /Applications/freesurfer/8.0.0/subjects/sub125/label/lh.cortex.label --lh-white /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.white --lh-pial /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.pial --rh-annot /Applications/freesurfer/8.0.0/subjects/sub125/label/rh.aparc.DKTatlas.annot 2000 --rh-cortex-mask /Applications/freesurfer/8.0.0/subjects/sub125/label/rh.cortex.label --rh-white /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.white --rh-pial /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.pial \n
#-----------------------------------------
#@# WMParc Fri Mar 28 17:13:53 CDT 2025
\n mri_surf2volseg --o wmparc.mgz --label-wm --i aparc+aseg.mgz --threads 1 --lh-annot /Applications/freesurfer/8.0.0/subjects/sub125/label/lh.aparc.annot 3000 --lh-cortex-mask /Applications/freesurfer/8.0.0/subjects/sub125/label/lh.cortex.label --lh-white /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.white --lh-pial /Applications/freesurfer/8.0.0/subjects/sub125/surf/lh.pial --rh-annot /Applications/freesurfer/8.0.0/subjects/sub125/label/rh.aparc.annot 4000 --rh-cortex-mask /Applications/freesurfer/8.0.0/subjects/sub125/label/rh.cortex.label --rh-white /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.white --rh-pial /Applications/freesurfer/8.0.0/subjects/sub125/surf/rh.pial \n
\n mri_segstats --seed 1234 --seg mri/wmparc.mgz --sum stats/wmparc.stats --pv mri/norm.mgz --excludeid 0 --brainmask mri/brainmask.mgz --in mri/norm.mgz --in-intensity-name norm --in-intensity-units MR --subject sub125 --surf-wm-vol --ctab /Applications/freesurfer/8.0.0/WMParcStatsLUT.txt --etiv --stiv /Applications/freesurfer/8.0.0/subjects/sub125/stats/synthseg.tiv.dat \n
#-----------------------------------------
#@# Parcellation Stats lh Fri Mar 28 17:17:07 CDT 2025
\n mris_anatomical_stats -th3 -mgz -cortex ../label/lh.cortex.label -f ../stats/lh.aparc.stats -b -a ../label/lh.aparc.annot -c ../label/aparc.annot.ctab sub125 lh white \n
\n mris_anatomical_stats -th3 -mgz -cortex ../label/lh.cortex.label -f ../stats/lh.aparc.pial.stats -b -a ../label/lh.aparc.annot -c ../label/aparc.annot.ctab sub125 lh pial \n
#-----------------------------------------
#@# Parcellation Stats rh Fri Mar 28 17:17:21 CDT 2025
\n mris_anatomical_stats -th3 -mgz -cortex ../label/rh.cortex.label -f ../stats/rh.aparc.stats -b -a ../label/rh.aparc.annot -c ../label/aparc.annot.ctab sub125 rh white \n
\n mris_anatomical_stats -th3 -mgz -cortex ../label/rh.cortex.label -f ../stats/rh.aparc.pial.stats -b -a ../label/rh.aparc.annot -c ../label/aparc.annot.ctab sub125 rh pial \n
#-----------------------------------------
#@# Parcellation Stats 2 lh Fri Mar 28 17:17:36 CDT 2025
\n mris_anatomical_stats -th3 -mgz -cortex ../label/lh.cortex.label -f ../stats/lh.aparc.a2009s.stats -b -a ../label/lh.aparc.a2009s.annot -c ../label/aparc.annot.a2009s.ctab sub125 lh white \n
#-----------------------------------------
#@# Parcellation Stats 2 rh Fri Mar 28 17:17:44 CDT 2025
\n mris_anatomical_stats -th3 -mgz -cortex ../label/rh.cortex.label -f ../stats/rh.aparc.a2009s.stats -b -a ../label/rh.aparc.a2009s.annot -c ../label/aparc.annot.a2009s.ctab sub125 rh white \n
#-----------------------------------------
#@# Parcellation Stats 3 lh Fri Mar 28 17:17:52 CDT 2025
\n mris_anatomical_stats -th3 -mgz -cortex ../label/lh.cortex.label -f ../stats/lh.aparc.DKTatlas.stats -b -a ../label/lh.aparc.DKTatlas.annot -c ../label/aparc.annot.DKTatlas.ctab sub125 lh white \n
#-----------------------------------------
#@# Parcellation Stats 3 rh Fri Mar 28 17:17:59 CDT 2025
\n mris_anatomical_stats -th3 -mgz -cortex ../label/rh.cortex.label -f ../stats/rh.aparc.DKTatlas.stats -b -a ../label/rh.aparc.DKTatlas.annot -c ../label/aparc.annot.DKTatlas.ctab sub125 rh white \n
#--------------------------------------------
#@# ASeg Stats Fri Mar 28 17:18:07 CDT 2025
\n mri_segstats --seed 1234 --seg mri/aseg.mgz --sum stats/aseg.stats --pv mri/norm.mgz --empty --brainmask mri/brainmask.mgz --brain-vol-from-seg --excludeid 0 --excl-ctxgmwm --supratent --subcortgray --in mri/norm.mgz --in-intensity-name norm --in-intensity-units MR --etiv --stiv /Applications/freesurfer/8.0.0/subjects/sub125/stats/synthseg.tiv.dat --surf-wm-vol --surf-ctx-vol --totalgray --euler --ctab /Applications/freesurfer/8.0.0/ASegStatsLUT.txt --subject sub125 \n
#--------------------------------------------
#@# BA_exvivo Labels lh Fri Mar 28 17:19:46 CDT 2025
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA1_exvivo.label --trgsubject sub125 --trglabel ./lh.BA1_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA2_exvivo.label --trgsubject sub125 --trglabel ./lh.BA2_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA3a_exvivo.label --trgsubject sub125 --trglabel ./lh.BA3a_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA3b_exvivo.label --trgsubject sub125 --trglabel ./lh.BA3b_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA4a_exvivo.label --trgsubject sub125 --trglabel ./lh.BA4a_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA4p_exvivo.label --trgsubject sub125 --trglabel ./lh.BA4p_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA6_exvivo.label --trgsubject sub125 --trglabel ./lh.BA6_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA44_exvivo.label --trgsubject sub125 --trglabel ./lh.BA44_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA45_exvivo.label --trgsubject sub125 --trglabel ./lh.BA45_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.V1_exvivo.label --trgsubject sub125 --trglabel ./lh.V1_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.V2_exvivo.label --trgsubject sub125 --trglabel ./lh.V2_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.MT_exvivo.label --trgsubject sub125 --trglabel ./lh.MT_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.entorhinal_exvivo.label --trgsubject sub125 --trglabel ./lh.entorhinal_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.perirhinal_exvivo.label --trgsubject sub125 --trglabel ./lh.perirhinal_exvivo.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.FG1.mpm.vpnl.label --trgsubject sub125 --trglabel ./lh.FG1.mpm.vpnl.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.FG2.mpm.vpnl.label --trgsubject sub125 --trglabel ./lh.FG2.mpm.vpnl.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.FG3.mpm.vpnl.label --trgsubject sub125 --trglabel ./lh.FG3.mpm.vpnl.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.FG4.mpm.vpnl.label --trgsubject sub125 --trglabel ./lh.FG4.mpm.vpnl.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.hOc1.mpm.vpnl.label --trgsubject sub125 --trglabel ./lh.hOc1.mpm.vpnl.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.hOc2.mpm.vpnl.label --trgsubject sub125 --trglabel ./lh.hOc2.mpm.vpnl.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.hOc3v.mpm.vpnl.label --trgsubject sub125 --trglabel ./lh.hOc3v.mpm.vpnl.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.hOc4v.mpm.vpnl.label --trgsubject sub125 --trglabel ./lh.hOc4v.mpm.vpnl.label --hemi lh --regmethod surface \n
\n mris_label2annot --s sub125 --ctab /Applications/freesurfer/8.0.0/average/colortable_vpnl.txt --hemi lh --a mpm.vpnl --maxstatwinner --noverbose --l lh.FG1.mpm.vpnl.label --l lh.FG2.mpm.vpnl.label --l lh.FG3.mpm.vpnl.label --l lh.FG4.mpm.vpnl.label --l lh.hOc1.mpm.vpnl.label --l lh.hOc2.mpm.vpnl.label --l lh.hOc3v.mpm.vpnl.label --l lh.hOc4v.mpm.vpnl.label \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA1_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.BA1_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA2_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.BA2_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA3a_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.BA3a_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA3b_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.BA3b_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA4a_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.BA4a_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA4p_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.BA4p_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA6_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.BA6_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA44_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.BA44_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.BA45_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.BA45_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.V1_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.V1_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.V2_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.V2_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.MT_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.MT_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.entorhinal_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.entorhinal_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/lh.perirhinal_exvivo.thresh.label --trgsubject sub125 --trglabel ./lh.perirhinal_exvivo.thresh.label --hemi lh --regmethod surface \n
\n mris_label2annot --s sub125 --hemi lh --ctab /Applications/freesurfer/8.0.0/average/colortable_BA.txt --l lh.BA1_exvivo.label --l lh.BA2_exvivo.label --l lh.BA3a_exvivo.label --l lh.BA3b_exvivo.label --l lh.BA4a_exvivo.label --l lh.BA4p_exvivo.label --l lh.BA6_exvivo.label --l lh.BA44_exvivo.label --l lh.BA45_exvivo.label --l lh.V1_exvivo.label --l lh.V2_exvivo.label --l lh.MT_exvivo.label --l lh.perirhinal_exvivo.label --l lh.entorhinal_exvivo.label --a BA_exvivo --maxstatwinner --noverbose \n
\n mris_label2annot --s sub125 --hemi lh --ctab /Applications/freesurfer/8.0.0/average/colortable_BA_thresh.txt --l lh.BA1_exvivo.thresh.label --l lh.BA2_exvivo.thresh.label --l lh.BA3a_exvivo.thresh.label --l lh.BA3b_exvivo.thresh.label --l lh.BA4a_exvivo.thresh.label --l lh.BA4p_exvivo.thresh.label --l lh.BA6_exvivo.thresh.label --l lh.BA44_exvivo.thresh.label --l lh.BA45_exvivo.thresh.label --l lh.V1_exvivo.thresh.label --l lh.V2_exvivo.thresh.label --l lh.MT_exvivo.thresh.label --l lh.perirhinal_exvivo.thresh.label --l lh.entorhinal_exvivo.thresh.label --a BA_exvivo.thresh --maxstatwinner --noverbose \n
\n mris_anatomical_stats -th3 -mgz -f ../stats/lh.BA_exvivo.stats -b -a ./lh.BA_exvivo.annot -c ./BA_exvivo.ctab sub125 lh white \n
\n mris_anatomical_stats -th3 -mgz -f ../stats/lh.BA_exvivo.thresh.stats -b -a ./lh.BA_exvivo.thresh.annot -c ./BA_exvivo.thresh.ctab sub125 lh white \n
#--------------------------------------------
#@# BA_exvivo Labels rh Fri Mar 28 17:21:49 CDT 2025
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA1_exvivo.label --trgsubject sub125 --trglabel ./rh.BA1_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA2_exvivo.label --trgsubject sub125 --trglabel ./rh.BA2_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA3a_exvivo.label --trgsubject sub125 --trglabel ./rh.BA3a_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA3b_exvivo.label --trgsubject sub125 --trglabel ./rh.BA3b_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA4a_exvivo.label --trgsubject sub125 --trglabel ./rh.BA4a_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA4p_exvivo.label --trgsubject sub125 --trglabel ./rh.BA4p_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA6_exvivo.label --trgsubject sub125 --trglabel ./rh.BA6_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA44_exvivo.label --trgsubject sub125 --trglabel ./rh.BA44_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA45_exvivo.label --trgsubject sub125 --trglabel ./rh.BA45_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.V1_exvivo.label --trgsubject sub125 --trglabel ./rh.V1_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.V2_exvivo.label --trgsubject sub125 --trglabel ./rh.V2_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.MT_exvivo.label --trgsubject sub125 --trglabel ./rh.MT_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.entorhinal_exvivo.label --trgsubject sub125 --trglabel ./rh.entorhinal_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.perirhinal_exvivo.label --trgsubject sub125 --trglabel ./rh.perirhinal_exvivo.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.FG1.mpm.vpnl.label --trgsubject sub125 --trglabel ./rh.FG1.mpm.vpnl.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.FG2.mpm.vpnl.label --trgsubject sub125 --trglabel ./rh.FG2.mpm.vpnl.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.FG3.mpm.vpnl.label --trgsubject sub125 --trglabel ./rh.FG3.mpm.vpnl.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.FG4.mpm.vpnl.label --trgsubject sub125 --trglabel ./rh.FG4.mpm.vpnl.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.hOc1.mpm.vpnl.label --trgsubject sub125 --trglabel ./rh.hOc1.mpm.vpnl.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.hOc2.mpm.vpnl.label --trgsubject sub125 --trglabel ./rh.hOc2.mpm.vpnl.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.hOc3v.mpm.vpnl.label --trgsubject sub125 --trglabel ./rh.hOc3v.mpm.vpnl.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.hOc4v.mpm.vpnl.label --trgsubject sub125 --trglabel ./rh.hOc4v.mpm.vpnl.label --hemi rh --regmethod surface \n
\n mris_label2annot --s sub125 --ctab /Applications/freesurfer/8.0.0/average/colortable_vpnl.txt --hemi rh --a mpm.vpnl --maxstatwinner --noverbose --l rh.FG1.mpm.vpnl.label --l rh.FG2.mpm.vpnl.label --l rh.FG3.mpm.vpnl.label --l rh.FG4.mpm.vpnl.label --l rh.hOc1.mpm.vpnl.label --l rh.hOc2.mpm.vpnl.label --l rh.hOc3v.mpm.vpnl.label --l rh.hOc4v.mpm.vpnl.label \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA1_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.BA1_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA2_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.BA2_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA3a_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.BA3a_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA3b_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.BA3b_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA4a_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.BA4a_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA4p_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.BA4p_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA6_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.BA6_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA44_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.BA44_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.BA45_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.BA45_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.V1_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.V1_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.V2_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.V2_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.MT_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.MT_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.entorhinal_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.entorhinal_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mri_label2label --srcsubject fsaverage --srclabel /Applications/freesurfer/8.0.0/subjects/fsaverage/label/rh.perirhinal_exvivo.thresh.label --trgsubject sub125 --trglabel ./rh.perirhinal_exvivo.thresh.label --hemi rh --regmethod surface \n
\n mris_label2annot --s sub125 --hemi rh --ctab /Applications/freesurfer/8.0.0/average/colortable_BA.txt --l rh.BA1_exvivo.label --l rh.BA2_exvivo.label --l rh.BA3a_exvivo.label --l rh.BA3b_exvivo.label --l rh.BA4a_exvivo.label --l rh.BA4p_exvivo.label --l rh.BA6_exvivo.label --l rh.BA44_exvivo.label --l rh.BA45_exvivo.label --l rh.V1_exvivo.label --l rh.V2_exvivo.label --l rh.MT_exvivo.label --l rh.perirhinal_exvivo.label --l rh.entorhinal_exvivo.label --a BA_exvivo --maxstatwinner --noverbose \n
\n mris_label2annot --s sub125 --hemi rh --ctab /Applications/freesurfer/8.0.0/average/colortable_BA_thresh.txt --l rh.BA1_exvivo.thresh.label --l rh.BA2_exvivo.thresh.label --l rh.BA3a_exvivo.thresh.label --l rh.BA3b_exvivo.thresh.label --l rh.BA4a_exvivo.thresh.label --l rh.BA4p_exvivo.thresh.label --l rh.BA6_exvivo.thresh.label --l rh.BA44_exvivo.thresh.label --l rh.BA45_exvivo.thresh.label --l rh.V1_exvivo.thresh.label --l rh.V2_exvivo.thresh.label --l rh.MT_exvivo.thresh.label --l rh.perirhinal_exvivo.thresh.label --l rh.entorhinal_exvivo.thresh.label --a BA_exvivo.thresh --maxstatwinner --noverbose \n
\n mris_anatomical_stats -th3 -mgz -f ../stats/rh.BA_exvivo.stats -b -a ./rh.BA_exvivo.annot -c ./BA_exvivo.ctab sub125 rh white \n
\n mris_anatomical_stats -th3 -mgz -f ../stats/rh.BA_exvivo.thresh.stats -b -a ./rh.BA_exvivo.thresh.annot -c ./BA_exvivo.thresh.ctab sub125 rh white \n
