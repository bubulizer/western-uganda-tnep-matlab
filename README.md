# Western Uganda TNEP MATLAB source code

Version: 1.0.0

The workflow implements the research-case AC load flow, hybrid MOPSO-DE expansion search, N−1 screening, economic assessment, and result export described in the accompanying article. It was developed with MATLAB R2025b. No third-party MATLAB toolbox is required by the numerical core.

To reproduce the recorded run, open MATLAB in this directory (which contains the `data/` and `matlab/` folders) and run `run('matlab/run_study.m')`. The run manifest in the Extended Data archive records the random seed and principal reported outputs.

The `data/` folder contains the model inputs and provenance dictionary. Inputs combine public-source values, proposal-derived topology and stated assumptions; they are not utility operational measurements. The same inputs and the supporting result tables are also deposited as Extended Data.

Code license: MIT (applies to the MATLAB source files). Data license: CC BY 4.0 (applies to files in `data/`).
Archived software DOI: https://doi.org/10.5281/zenodo.22817102

Recommended citation: Asiimwe, J., Bubu, P. E., & Abdalla, E. A. H. (2026). Hybrid MOPSO-DE MATLAB Code for Multi-Objective AC Transmission Network Optimisation (Version 1.0.0) [Computer software]. Zenodo. https://doi.org/10.5281/zenodo.22817102

Version-controlled source: https://github.com/bubulizer/western-uganda-tnep-matlab


