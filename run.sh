#!/bin/bash

################################################################################
# funcs

# from fsl_anat
quick_smooth() {
	echo "quick_smooth"
	local in=$1
	local out=$2
	local tmpDir=$(dirname $out)/qs_tmpDir/
	mkdir -p $tmpDir

	$FSLDIR/bin/fslmaths $in -subsamp2 -subsamp2 -subsamp2 -subsamp2 ${tmpDir}/vol16
	$FSLDIR/bin/flirt -in ${tmpDir}/vol16 -ref $in -out $out -noresampblur -applyxfm -paddingsize 16
	# possibly do a tiny extra smooth to $out here?
	$FSLDIR/bin/imrm ${tmpDir}/vol16
	rm -rv ${tmpDir}/
}

# from fsl_anat
quick_bias_corr()
{
	local in=$(remove_ext $1)
	local out=$2
	local tmpDir=$(dirname $out)/qbc_tmpDir/
	mkdir -p $tmpDir

	echo "doing quick bias corr"

	quick_smooth ${in} ${tmpDir}/${in}_s20
	$FSLDIR/bin/fslmaths ${in} -div ${tmpDir}/${in}_s20 ${tmpDir}/${in}_hpf

	$FSLDIR/bin/bet ${tmpDir}/${in}_hpf ${tmpDir}/${in}_hpf_brain -m -f 0.1 -v
    # get a smoothed version without the edge effects
	$FSLDIR/bin/fslmaths ${in} -mas ${tmpDir}/${in}_hpf_brain_mask ${tmpDir}/${in}_hpf_s20
	quick_smooth ${tmpDir}/${in}_hpf_s20 ${tmpDir}/${in}_hpf_s20
	quick_smooth ${tmpDir}/${in}_hpf_brain_mask ${tmpDir}/${in}_initmask_s20
	$FSLDIR/bin/fslmaths ${tmpDir}/${in}_hpf_s20 -div ${tmpDir}/${in}_initmask_s20 -mas ${tmpDir}/${in}_hpf_brain_mask ${tmpDir}/${in}_hpf2_s20
	$FSLDIR/bin/fslmaths ${in} -mas ${tmpDir}/${in}_hpf_brain_mask -div ${tmpDir}/${in}_hpf2_s20 ${tmpDir}/${in}_hpf2_brain
	# make sure the overall scaling doesn't change (equate medians)
	med0=`$FSLDIR/bin/fslstats ${in} -k ${tmpDir}/${in}_hpf_brain_mask -P 50`;
	med1=`$FSLDIR/bin/fslstats ${in}_hpf2_brain -k ${tmpDir}/${in}_hpf_brain_mask -P 50`;
	$FSLDIR/bin/fslmaths ${tmpDir}/${in}_hpf2_brain -div $med1 -mul $med0 ${tmpDir}/${in}_hpf2_brain

	# cleanup
	mv ${tmpDir}/${in}_hpf2_brain.nii.gz $out
	rm -rv ${tmpDir}/
}

################################################################################
################################################################################
# inputs

if [[ -e config.json ]] ; then 
	img1=$(jq -r .image1 config.json)
	img2=$(jq -r .image2 config.json)
	outDir=${PWD}/output_avg/
	mkdir -p ${outDir}
	do_skullS=$(jq -r .skulls config.json)
else
	if [[ "$#" -lt 2 ]] ; then
		echo "need args plz. exiting." ; exit 1
	fi
	img1=$1
	img2=$2

	# set output dir
	if [[ "$#" -gt 2 ]] ; then
		outDir=$3
	else
		outDir=${PWD}/
	fi
	# set output dir
	if [[ "$#" -gt 3 ]] ; then
		skullS=$4
	fi
	if [[ ${skullS} == "true" ]] || [[ ${skullS} == "1" ]] ; then
		do_skullS="true"
	else
		do_skullS="nah"
	fi
fi

# check the inputs
if [[ ! -e $img1 ]] || [[ ! -e $img2 ]] ; then
	echo "need valid files. exiting." ; exit 1
fi

flargs="-searchrx -60 60 \
		-searchry -60 60 \
		-searchrz -60 60 \
		-dof 12 -v"

################################################################################
# reor for kicks

cmd="fslreorient2std $img1 ${outDir}/img1_reor.nii.gz"
echo $cmd && eval $cmd 
cmd="fslreorient2std $img2 ${outDir}/img2_reor.nii.gz"
echo $cmd && eval $cmd 

################################################################################
# possibly skull strip?

flirt1bet=''
flirt2bet=''
if [[ ${do_skullS} == "true" ]] ; then
	echo "doing quick bias corr & skul strip to get better alignment hopefully"

	quick_bias_corr ${outDir}/img1_reor.nii.gz ${outDir}/img1_reor_bc.nii.gz 
	quick_bias_corr ${outDir}/img2_reor.nii.gz ${outDir}/img2_reor_bc.nii.gz

	cmd="bet ${outDir}/img1_reor_bc.nii.gz ${outDir}/img1_bet -R -m -n -v"
	echo $cmd && eval $cmd 

	cmd="bet ${outDir}/img2_reor_bc.nii.gz ${outDir}/img2_bet -R -m -n -v"
	echo $cmd && eval $cmd 

	cmd="fslmaths ${outDir}/img1_bet_mask.nii.gz \
			-s 2 ${outDir}/img1_bet_mask.nii.gz"
	echo $cmd && eval $cmd 

	cmd="fslmaths ${outDir}/img2_bet_mask.nii.gz \
			-s 2 ${outDir}/img2_bet_mask.nii.gz"
	echo $cmd && eval $cmd 

	flirt1bet="-inweight ${outDir}/img1_bet_mask.nii.gz \
					-refweight ${outDir}/img2_bet_mask.nii.gz"
	flirt2bet="-inweight ${outDir}/img2_bet_mask.nii.gz \
					-refweight ${outDir}/img1_bet_mask.nii.gz"
fi

################################################################################
# register to each other

cmd="flirt -in ${outDir}/img1_reor.nii.gz \
		-ref ${outDir}/img2_reor.nii.gz \
		-omat ${outDir}/img1_to_img2.xfm $flargs $flirt1bet"
echo $cmd && eval $cmd 
cmd="flirt -in ${outDir}/img2_reor.nii.gz \
		-ref ${outDir}/img1_reor.nii.gz \
		-omat ${outDir}/img2_to_img1.xfm $flargs $flirt2bet"
echo $cmd && eval $cmd 

cp ${outDir}/img1_to_img2.xfm ${outDir}/tmp_img1_to_img2.xfm
cp ${outDir}/img2_to_img1.xfm ${outDir}/tmp_img2_to_img1.xfm

################################################################################
## copied from FSL siena_flirt

# replace both transforms with "average" (reduces error level AND makes system symmetric)
F=${outDir}/tmp_img1_to_img2.xfm
B=${outDir}/tmp_img2_to_img1.xfm

cmd="${FSLDIR}/bin/convert_xfm -concat $B -omat ${outDir}/tmp_F_then_B $F"
echo $cmd && eval $cmd 

cmd="${FSLDIR}/bin/avscale ${outDir}/tmp_F_then_B ${img1} > ${outDir}/tmp_F_then_B.avscale"
echo $cmd && eval $cmd 

cmd="${FSLDIR}/bin/extracttxt Backward ${outDir}/tmp_F_then_B.avscale 4 1 > ${outDir}/tmp_F_then_B_halfback"
echo $cmd && eval $cmd 

cmd="${FSLDIR}/bin/convert_xfm -concat ${outDir}/tmp_F_then_B_halfback -omat $F $F"
echo $cmd && eval $cmd 

cmd="${FSLDIR}/bin/convert_xfm -inverse -omat $B $F"
echo $cmd && eval $cmd 

cmd="/bin/rm ${outDir}/tmp_F_then_B ${outDir}/tmp_F_then_B.avscale ${outDir}/tmp_F_then_B_halfback"
echo $cmd && eval $cmd 

# replace the .mat matrix that takes 2->1 with one that takes 2->halfway and one that takes 1->halfway
cmd="${FSLDIR}/bin/avscale ${B} ${img1} > ${outDir}/img2_to_img1.mat_avscale"
echo $cmd && eval $cmd 
cmd="${FSLDIR}/bin/extracttxt Forward ${outDir}/img2_to_img1.mat_avscale 4 1 > ${outDir}/img2_halfwayto_img1.mat"
echo $cmd && eval $cmd 
cmd="${FSLDIR}/bin/extracttxt Backward ${outDir}/img2_to_img1.mat_avscale 4 1 > ${outDir}/img1_halfwayto_img2.mat"
echo $cmd && eval $cmd 

cmd="flirt -in ${outDir}/img1_reor.nii.gz \
		-ref ${outDir}/img1_reor.nii.gz \
		-applyxfm -init ${outDir}/img1_halfwayto_img2.mat \
		-o ${outDir}/img1_halfway.nii.gz -interp spline"
echo $cmd && eval $cmd 

cmd="flirt -in ${outDir}/img2_reor.nii.gz \
		-ref ${outDir}/img1_reor.nii.gz \
		-applyxfm -init ${outDir}/img2_halfwayto_img1.mat \
		-o ${outDir}/img2_halfway.nii.gz -interp spline"
echo $cmd && eval $cmd 

################################################################################
# and average

cmd="fslmaths ${outDir}/img1_halfway.nii.gz \
		-add ${outDir}/img2_halfway.nii.gz \
		-div 2 -thr 0 ${outDir}/t1.nii.gz"
echo $cmd && eval $cmd 

################################################################################
# cleanup 
ls ${outDir}/*xfm && rm ${outDir}/*xfm
ls ${outDir}/*mat && rm ${outDir}/*mat
ls ${outDir}/*avscale && rm ${outDir}/*avscale

################################################################################
# make png
slicer ${outDir}/out.nii.gz -a ${outDir}/out_aligncheck.png

# create product.json
cat << EOF > product.json
{
    "brainlife": [
        { 
            "type": "image/png", 
            "name": "Alignment Check (-a)",
            "base64": "$(base64 -w 0 ${outDir}/out_aligncheck.png)"
        }
    ]
}
EOF

# FSL LICENSE
#   LICENCE
#
#   FMRIB Software Library, Release 6.0 (c) 2018, The University of
#   Oxford (the "Software")
#
#   The Software remains the property of the Oxford University Innovation
#   ("the University").
#
#   The Software is distributed "AS IS" under this Licence solely for
#   non-commercial use in the hope that it will be useful, but in order
#   that the University as a charitable foundation protects its assets for
#   the benefit of its educational and research purposes, the University
#   makes clear that no condition is made or to be implied, nor is any
#   warranty given or to be implied, as to the accuracy of the Software,
#   or that it will be suitable for any particular purpose or for use
#   under any specific conditions. Furthermore, the University disclaims
#   all responsibility for the use which is made of the Software. It
#   further disclaims any liability for the outcomes arising from using
#   the Software.
#
#   The Licensee agrees to indemnify the University and hold the
#   University harmless from and against any and all claims, damages and
#   liabilities asserted by third parties (including claims for
#   negligence) which arise directly or indirectly from the use of the
#   Software or the sale of any products based on the Software.
#
#   No part of the Software may be reproduced, modified, transmitted or
#   transferred in any form or by any means, electronic or mechanical,
#   without the express permission of the University. The permission of
#   the University is not required if the said reproduction, modification,
#   transmission or transference is done without financial return, the
#   conditions of this Licence are imposed upon the receiver of the
#   product, and all original and amended source code is included in any
#   transmitted product. You may be held legally responsible for any
#   copyright infringement that is caused or encouraged by your failure to
#   abide by these terms and conditions.
#
#   You are not permitted under this Licence to use this Software
#   commercially. Use for which any financial return is received shall be
#   defined as commercial use, and includes (1) integration of all or part
#   of the source code or the Software into a product for sale or license
#   by or on behalf of Licensee to third parties or (2) use of the
#   Software or any derivative of it for research with the final aim of
#   developing software products for sale or license to a third party or
#   (3) use of the Software or any derivative of it for research with the
#   final aim of developing non-software products for sale or license to a
#   third party, or (4) use of the Software to provide any service to an
#   external organisation for which payment is received. If you are
#   interested in using the Software commercially, please contact Oxford
#   University Innovation ("OUI"), the technology transfer company of the
#   University, to negotiate a licence. Contact details are:
#   fsl@innovation.ox.ac.uk quoting Reference Project 9564, FSL.