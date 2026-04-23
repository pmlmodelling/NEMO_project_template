# NEMO_project_template

Repository containing the recommended folder structure for an AMM7 NEMO-FABM-ERSEM project, including scripts to handle automatic run cycling. This is the base configuration for a 'standard' simulation, with options for including additional models of spectral light and mizer. Project contains the following structure:

```
project folder
├── BGC_setup (collection of scripts to generate input files)
├── RUN
│   ├── EXP00 (default run configuration files) 
│   ├── EXP00_spectral (default run configuration files including spectral model) 
│   ├── EXP00_mizer (default run configuration files including mizer model)
    └── EXP00_spectral_mizer (default run configuration files including spectral and mizer models)
├── code (location for nemo to be compiled, contains any addition compilation files)
├── INPUTS (input files, not to be stored on github)
    ├── DOM (domain files, coordinates, bathymetry and initial conditions)
    ├── LBC (physics and BGC lateral/open boundary conditions)
    ├── RIV (river forcing files)
    ├── SBC (atmospheric forcing and BGC surface forcing)
    └── TIDES (tidal forcing files)
├── scripts (scripts for compiling code and executing simulations)
```

## Repository structure/workflow

Clone repository. It is recommended that you clone for a specific project, for example, `NECCTON` rather than `NEMO_project_template`.
```
git clone -b AMM7 https://github.com/pmlmodelling/NEMO_project_template.git <PROJECT_NAME>
```

### Set Environment

First, navigate to the `scripts/` directory and run `setup_<SYSTEM>.sh`, depending on if you are using scylla or archer2. This will set the module environment, architecture files for compilation and link the inputs to <PROJECT_NAME>/INPUTS, with the folder structure detailed below.

Next edit scripts/config.sh. Most settings here can be left as standard, with the exception of:
1. EXP_NAME - Name for your experiment. If you run multiple experiments under the same project, this can be changed between runs to  keep them separate
2. START_YEAR - Beginning year of the experiment. Please ensure restart files exist in INPUTS/DOM/. If using the existing restarts please keep this as 1993. You can start from a later time by adding the current_date file (see below)
3. END_YEAR - Final year of experiment (inclusive)

### Compiling code

To compile the code needed to run, you can execute `scripts/compile_code.sh` with various flags. The first time you need to include the `-c` flag to also clone the code, subsequent recompiles will not need to include this:
- <H4>XIOS</H4> To compile xios, execute `compile_code.sh -xc`. Note Scylla does not have access to svn, so the base code gets linked through the setup and you just need to execute `compile_code.sh -x`
- <H4>FABM/ERSEM</H4> To compile fabm (with ersem), execute `compile_code.sh -fc`
- <H4>NEMO</H4> To compile nemo, execute `compile_code.sh -nc`. This must be done after compiling XIOS and FABM. 

The executables for xios and nemo should now be available in `code/executables`

### RUN

Before kickstarting a run, its a good idea to check everything is setup correctly. To help with this the script `scripts/dry_run.sh` is provided. This script creates the run folder `RUN/EXP_NAME`, links all the files needed to run from START_YEAR and sets the cfg files as needed. Please check this is as expected. A dry run with the flag `-c` will do perform a clean instance if you make any changes. 
 
To perform a single cycle, navigate to `RUN/<EXP_NAME>` and submit the job using the testing scripts
```
sbatch runscript_testing.slurm
```

To start a cycle run, navigate to `scripts` and submit the run:
```
sbatch runscript.slurm
```

If you want to start from a date other than the January of START_YEAR, or the run needs to be restarted you can do so by creating/editing the file scripts/current_date with the following:
```
export year=XXXX
export month=Y
```
Note that if you change this before running to start from a date other than 1/1/1993, you will need to change scripts/core-scripts/setup_initial.sh to link the correct restart file. 

The cycle run uses the run configuration files in RUN/EXP00. Please make any changes here, or alternatively set a new `DEFAULT_RUN_DIR` in config.sh before running if you want to change the configuration. 

### OUTPUTS

By default, output will be moved to the `OUTPUTS/` directory using the `EXP_NAME/YYYY/MM/` folder structure. 

### INPUTS

Once linked, the INPUTS directory should point to files with the following folder structure:
- <H4>DOM</H4> Includes domain files, coordinates, bathymetry and initial conditions
- <H4>BDY</H4> Folders for physics and BGC Lateral/open boundary conditions
- <H4>RIV</H4> Includes river forcing files
- <H4>SBC</H4> Folders for atmospheric forcing and BGC surface forcing
- <H4>TIDE</H4> Includes tidal forcing files

### BGC_setup

The scripts used to create the biogeochemical inputs: initial conditions, lateral and surface boundary files are found here should you wish to use them to create any alternative input files. 

