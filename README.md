[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.385-blue.svg)](https://doi.org/https://doi.org/10.25663/brainlife.app.385)

# app-average-imgs

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

**Aligns two T1-weighted images of the same subject into a midway space with FSL flirt and averages them into a single higher-SNR T1w image.**

Reorients both images, optionally bias-corrects and skull-strips them to weight the registration, registers each to the other with FSL flirt, places both in a halfway space and averages them, reslicing to the resolution of the first image. Use it when a subject has repeated anatomical acquisitions; check the result visually, as the README recommends.

Run it on brainlife.io: [https://doi.org/10.25663/brainlife.app.385](https://doi.org/10.25663/brainlife.app.385)

| Input | Datatype | Required | Description |
|---|---|---|---|
| `image1` | `neuro/anat/t1w` | yes | First T1-weighted image; its resolution is used for the averaged output. |
| `image2` | `neuro/anat/t1w` | yes | Second T1-weighted image of the same subject. |

| Output | Datatype | Description |
|---|---|---|
| `output_avg` | `neuro/anat/t1w` | average of inputs, reslices to resolution of image1 |

| Parameter | Type | Default | Description |
|---|---|---|---|
| `skulls` | boolean | `true` | do skull struc |

Runtime: container `brainlife/fsl:5.0.9`; 1 CPUs; 0.42 h walltime.

<!-- brainlife-app:end -->

This app aligns one image to another in a midway space, and then averages the two images. This app can be useful when you have repeat anatomical aquisitions, and you'd like to make an average, with persumably higher signal-to-noise. Please verify the output of the app with visual inspection.

### Authors 

- Josh Faskowitz (joshua.faskowitz@gmail.com) 

### Project Contributors 

- Soichi Hayashi (hayashi@iu.edu)
- Franco Pestilli (frakkopesto@gmail.com) 

### Funding 

[![NSF-GRFP-1342962](https://img.shields.io/badge/NSF_GRFP-1342962-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1342962)
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-ACI-1916518](https://img.shields.io/badge/NSF_ACI-1916518-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1916518)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://grantome.com/grant/NIH/R01-EB029272-01)

### Citations 

Please cite the following articles when publishing papers that used data, code or other resources created by the brainlife.io community. 

Avesani, P., McPherson, B., Hayashi, S. et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. Sci Data 6, 69 (2019). https://doi.org/10.1038/s41597-019-0073-y

### Running Locally (on your machine)

1. git clone this repo.
2. Inside the cloned directory, create `config.json` with something like the following content with paths to your input files.

```json
{
        "image1": "/path/img1.nii.gz",
        "image2": "/path/img2.nii.gz",
        "do_skulls" "true"
}
```

*do_skills: if true, automatically skull strip (with FSL bet) before alignment

3. Launch the App by executing `main`

```bash
./main
```

## Output

All output files will be generated under the current working directory (pwd), in directories called `output_avg`. The file of interest is `output_avg/t1.nii.gz`

### Dependencies

This App uses [singularity](https://www.sylabs.io/singularity/) to run. If you don't have singularity, you can run this script in a unix enviroment with:  

  - FSL: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/
  - jq: https://stedolan.github.io/jq/
  
  #### MIT Copyright (c) Josh Faskowitz & brainlife.io

<sub> This material is based upon work supported by the National Science Foundation Graduate Research Fellowship under Grant No. 1342962. Any opinion, findings, and conclusions or recommendations expressed in this material are those of the authors(s) and do not necessarily reflect the views of the National Science Foundation. </sub>
