# UPDATE LOG

## May 2026

Simultaneous Runs 
==================
The repository is now setup to be able to perform runs simultaneously. This means both cycle and testing runs must be started from the run directory instead of the scripts directory, requiring the dry run to be performed to set up the run folder.

Variable Outputs 
=================
In config.sh there is an option to turn on which files to output. Default file outputs include daily/monthly sets of physics and tracer variables, monthly diagnostics and monthly budget terms. 

Restructure of scripts directory 
================================
Most scripts were previously held in a single directory (core-scripts), this have been split into the following structure:

<H4>compile-scripts</H4> - Anything involving cloning and compiling code
<H4>core-scripts</H4> - Scripts essential to the working of the repository that shouldn't need to be edited
<H4>input-scripts</H4> - Initial/Yearly scripts that link the input files needed
<H4>submission-scripts</H4> - Slurm runscripts and scripts to produce them (see below)
<H4>utility-scripts</H4> - Functional scripts for other tasks (e.g. running a spinup, rebuilding nemo restarts)

Addition of Spectral/Mizer models and tracer budgets
=====================================================
There are now flags in the config.sh that turn on the spectral and/or mizer models. Additionally there are additional default run directories with setups for these models. When you compile the code it will create executables with "spectral" or "mizer" suffixes, or both so that you may create multiple options. You will need to run `compile_code.sh -fc` again when adding/removing these options before recompiling nemo.   

There is also a flag to compile nemo with the keys needed to calculate a tracer budget

ERSEM version and Nitrous Oxide 
===============================
The repository now clones the ERSEM version released in February 2026. Nitrous oxide (n2o) has been added the model as standard

Submission script generator 
===========================
There is now the ability to produce the runscripts for both cycling and single runs, allowing the user to change to the number of nodes needed to run. This script is provided here:
```
scripts/submission-scripts/update_runscripts.sh
```
with instructions on how to use it contained within the script

Perform Spinups 
===============
A script has been provided to perform a spinup of the BGC tracer field:
```
scripts/utility-scripts/perform_spinup.slurm
```
with instructions in the script on how to use it. By default it starts with the 1993 file generated from observations, and does 5 cycles of 5-years, using the tracer field from the end of each cycle at the start of the next. 


