<h1 align="center">Midway align and average T1w</h1>

<p align="center">
  A single, higher-SNR T1-weighted image from two repeat T1w acquisitions of the same subject, aligned in a halfway space.
</p>

<p align="center">
  <a href="https://github.com/brainlife/abcd-spec"><img src="https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg" alt="ABCD Spec v1.1"></a>
  <a href="https://doi.org/10.25663/brainlife.app.385"><img src="https://img.shields.io/badge/Brainlife-brainlife.app.385-blue.svg" alt="Run on brainlife.io"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="MIT license"></a>
</p>

## At a glance

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

> **Aligns two T1-weighted images of the same subject into a midway space with FSL flirt and averages them into a single higher-SNR T1w image.**

Reorients both images, optionally bias-corrects and skull-strips them to weight the registration, registers each to the other with FSL flirt, places both in a halfway space and averages them, reslicing to the resolution of the first image. Use it when a subject has repeated anatomical acquisitions; check the result visually, as the README recommends.

| | |
|---|---|
| **Inputs** | `neuro/anat/t1w` ×2 |
| **Outputs** | `neuro/anat/t1w` |
| **Container** | `brainlife/fsl:5.0.9` |
| **Resources** | 1 CPUs · 0.42 h walltime |
| **Run it** | [doi.org/10.25663/brainlife.app.385](https://doi.org/10.25663/brainlife.app.385) |

#### Inputs

| Input | Datatype | Required | Description |
|---|---|---|---|
| `image1` | `neuro/anat/t1w` | yes | First T1-weighted image; its resolution is used for the averaged output. |
| `image2` | `neuro/anat/t1w` | yes | Second T1-weighted image of the same subject. |

#### Outputs

| Output | Datatype | Description |
|---|---|---|
| `output_avg` | `neuro/anat/t1w` | average of inputs, reslices to resolution of image1 |

<details>
<summary><b>Parameters</b> (1)</summary>

| Parameter | Type | Default | Description |
|---|---|---|---|
| `skulls` | boolean | `true` | do skull struct |

</details>

<!-- brainlife-app:end -->

## How it works

1. Both images are reoriented to the standard orientation (`fslreorient2std`).
2. If `skulls` is set, each image gets a quick bias correction (adapted from `fsl_anat`) and an FSL `bet` brain mask; the smoothed masks weight the registration.
3. Each image is registered to the other with FSL `flirt` (12 degrees of freedom). The two transforms are averaged, as in FSL `siena_flirt`, so the registration is symmetric and both images are moved halfway towards each other.
4. The two halfway images are resliced to the grid of the first image (spline interpolation) and averaged.

Repeat anatomical acquisitions averaged this way should have a higher signal-to-noise ratio than either one alone. Always check the result visually.

## Running the App

### On brainlife.io

Open the App at [doi.org/10.25663/brainlife.app.385](https://doi.org/10.25663/brainlife.app.385), choose two T1-weighted datasets of the same subject from your project (`image1` and `image2`), decide whether to use skull-stripped masks for the registration and press **Execute**. The averaged image is archived to your project as a new `neuro/anat/t1w` dataset.

### Locally

You need [Singularity/Apptainer](https://apptainer.org/) and [`jq`](https://jqlang.github.io/jq/). `main` runs `run.sh` inside the `brainlife/fsl:5.0.9` container. Without Singularity you can run `run.sh` directly in a Unix environment with [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/) and `jq` installed.

1. Clone this repository.
2. Create `config.json` with the paths to your two images:

   ```json
   {
       "image1": "/path/img1.nii.gz",
       "image2": "/path/img2.nii.gz",
       "skulls": true
   }
   ```

   `skulls`: when `true`, bias-correct and skull-strip (FSL `bet`) both images before alignment and use the brain masks to weight the registration.

3. Run the App:

   ```bash
   ./main
   ```

## Outputs

Everything is written under the current working directory:

```text
output_avg/
├── t1.nii.gz             the averaged T1w image (resolution of image1)
├── img1_reor.nii.gz      reoriented inputs
├── img2_reor.nii.gz
├── img1_halfway.nii.gz   each input resampled into the halfway space
└── img2_halfway.nii.gz
```

The file of interest is `output_avg/t1.nii.gz`. With `skulls` set, the bias-corrected images and brain masks used for the registration are also kept.

## Citing

> [!TIP]
> If you use this App in your work, please cite the App, the software it builds on and brainlife.io (below). GitHub's **Cite this repository** button gives the App citation in APA and BibTeX.

- midway align and average T1w. brainlife.io App. [doi:10.25663/brainlife.app.385](https://doi.org/10.25663/brainlife.app.385)
- Jenkinson et al. FSL. *NeuroImage* 62:782-790 (2012). [doi:10.1016/j.neuroimage.2011.09.015](https://doi.org/10.1016/j.neuroimage.2011.09.015)
- Hayashi S, Caron BA, Heinsfeld AS, et al. brainlife.io: a decentralized and open-source cloud platform to support neuroscience research. *Nature Methods* 21:809–813 (2024). [doi:10.1038/s41592-024-02237-2](https://doi.org/10.1038/s41592-024-02237-2)
- Avesani P, McPherson B, Hayashi S, et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. *Scientific Data* 6:69 (2019). [doi:10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)

## Authors

- Franco Pestilli (project director)
- Josh Faskowitz

**Contributors:** Soichi Hayashi

## Funding

[![Wellcome-226486/Z/22/Z](https://img.shields.io/badge/Wellcome-226486%2FZ%2F22%2FZ-purple.svg)](https://wellcome.org/)
[![NIH-NINDS-U24NS140384](https://img.shields.io/badge/NIH_NINDS-U24NS140384-green.svg)](https://reporter.nih.gov/project-details/11261037)
[![NIH-NINDS-UM1NS132207](https://img.shields.io/badge/NIH_NINDS-UM1NS132207-green.svg)](https://reporter.nih.gov/project-details/11411328)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://reporter.nih.gov/project-details/10262925)
[![NIH-NIBIB-R01EB030896](https://img.shields.io/badge/NIH_NIBIB-R01EB030896-green.svg)](https://reporter.nih.gov/project-details/10428625)
[![NIH-NIMH-R01MH126699](https://img.shields.io/badge/NIH_NIMH-R01MH126699-green.svg)](https://reporter.nih.gov/project-details/10460628)
[![NIH-NIDCD-R01DC020088](https://img.shields.io/badge/NIH_NIDCD-R01DC020088-green.svg)](https://reporter.nih.gov/project-details/11140284)
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-2203524](https://img.shields.io/badge/NSF_BCS-2203524-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2203524)
[![NSF-IIS-1636893](https://img.shields.io/badge/NSF_IIS-1636893-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-OAC-2148729](https://img.shields.io/badge/NSF_OAC-2148729-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148729)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NSF-IIS-2148700](https://img.shields.io/badge/NSF_IIS-2148700-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148700)
[![NSF-OAC-1916518](https://img.shields.io/badge/NSF_OAC-1916518-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1916518)

<sub>brainlife.io is publicly funded, and acknowledging that support helps keep it running. This App was developed with support from Wellcome, the U.S. National Institutes of Health (including the BRAIN Initiative BRAIN CONNECTS program: The Axonal Projectome EXchange, U24NS140384, and the Center for Mesoscale Connectomics, UM1NS132207) and the U.S. National Science Foundation.</sub>

<sub>This material is based upon work supported by the National Science Foundation Graduate Research Fellowship under Grant No. 1342962. Any opinion, findings, and conclusions or recommendations expressed in this material are those of the authors(s) and do not necessarily reflect the views of the National Science Foundation.</sub>

## License

[MIT](LICENSE), Copyright (c) Josh Faskowitz and brainlife.io. FSL itself is distributed under its own [license](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence) (non-commercial use).
