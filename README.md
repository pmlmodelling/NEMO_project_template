# NEMO_project_template

Repository containing the recommended folder structure for an AMM7 NEMO-FABM-BGC project, including scripts to handle automatic run cycling. 

## Repository structure/workflow

Clone repository. It is recommended that you clone for a specific project, for example, `NECCTON` rather than `NEMO_project_template`.
```
git clone -b AMM7 https://github.com/pmlmodelling/NEMO_project_template.git <PROJECT_NAME>
```

### Set Environment

First, navigate to the `scripts/` directory and run `setup_<SYSTEM>.sh`, depending on if you are using scylla or archer2. This will set the module environment, architecture files for compilation and link the inputs to <PROJECT_NAME>/INPUTS, with the folder structure detailed below.

Next edit scripts/config.sh. Most settings here can be left as standard, with the exception of:
1. EXP_NAME - Name for your experiment. If you run multiple experiments under the same project, this can be changed between runs to  keep them separate
2. START_YEAR - Beginning year of the experiment. Please ensure restart files exist in INPUTS/DOM/
3. END_YEAR - Final year of experiment (inclusive)

### Compiling code

To compile the code needed to run, you can execute `scripts/compile_code.sh` with various flags. The first time you need to include the `-c` flag to also clone the code, subsequent recompiles will not need to include this:
- <H4>XIOS</H4> To compile xios, execute `compile_code.sh -xc`. Note Scylla does not have access to svn, so the base code gets linked through the setup and you just need to execute `compile_code.sh -x`
- <H4>FABM/ERSEM</H4> To compile fabm (with ersem), execute `compile_code.sh -fc`
- <H4>NEMO</H4> To compile nemo, execute `compile_code.sh -nc`. This must be done after compiling XIOS and FABM. 

The executables for xios and nemo should now be available in `code/executables`

### RUN

Before kickstarting a run, its a good idea to check everything is setup correctly. To help with this the script `scripts/dry_run.sh` is provided. This script creates the run folder `RUN/EXP_NAME`, links all the files needed to run from START_YEAR and sets a cfg files as needed. Please check this is as expected. A dry run with the flag `-c` will do perform a clean instance if you make any changes. 
 
To perform a single cycle, navigate to `RUN/<EXP_NAME>` and submit the job using the testing scripts
```
sbatch runscript_testing.slurm
```

To start a cycle run, navigate to `scripts` and submit the run:
```
sbatch runscript.slurm
```

If you want to start from a date other than the January of START_YEAR, or the run needs to be restarted you can do so. Either export the year/month variables directly in the terminal (Scylla) or create/edit the file scripts/current_date (Archer2) with the following:
```
export year=XXXX
export month=Y
```

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

