# NEMO_project_template

Repository contain recommended folder structure for a project, including a set of scripts to handle automatic run cycling.

## Repository structure/workflow

Clone repository for a specific project, for example, `NECCTON` rather than `NEMO_project_template`.

### Code

First, to you will need to set the enviroment via `0_set_environment.sh`

We advise people to ue the singularity container to install NEMO-FABM-ERSEM here https://github.com/pmlmodelling/NEMO-container.

Alternatively, if singularity is not available the scripts to build NEMO-FABM-ERSEM are here.

### INPUTS

The basic structure of the `INPUTS` folder is as follows:
#### DOM  

Domain files

#### LBC  

Lateral/open boundary conditions

#### RIV  

River forcing files

#### SBC

Atmospheric and other surface forcing

#### TIDES

Tidal forcing

### RUN
### OUTPUTS

Will be populated from run scripts



