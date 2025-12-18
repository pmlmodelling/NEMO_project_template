# NEMO_project_template

Repository containing setup and run files for configurations of NEMO-ERSEM. Each configuration is a separate branch, with the following structure:

```
project folder
├── BGC_setup (collection of scripts to generate input files)
├── RUN
│   ├── EXP00 (default run configuration files) 
├── code (location for nemo to be compiled, contains any addition compilation files)
├── INPUTS (input files, not to be stored on github)
    ├── DOM (domain files, coordinates, bathymetry and initial conditions)
    ├── LBC (physics and BGC lateral/open boundary conditions)
    ├── RIV (river forcing files)
    ├── SBC (atmospheric forcing and BGC surface forcing)
    └── TIDES (tidal forcing files)
├── scripts (scripts for compiling code and executing simulations)
```
