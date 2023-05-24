This directory contains the files needed to perform a cycle run. 

The following files will need to be edited for your project:

<b>set_environment.sh</b> - Configuration file for cycle;
                      set working directories, run length, cycle length and slurm options

<b>setup_initial.sh</b> - Setup that gets run before the first cycle; 
                    creates folders, links restarts, domain files and executables. Edit to create links to all your files

<b>setup_year.sh</b> - Setup needed each year of the cycle;
                    Links yearly files such as lateral and surface boundary files, as well as rivers


The following files should not need to be edited:

<b>cycle.slurm</b> - This is the script to execute to run the cycle. Submit using `sbatch --export=year=$START_YEAR --export=month=01 cycle.slurm`. Will either execute a whole year or individual months and resubmit until the final year in set_environment. 

<b>submit_job</b> - Executes the job for a given month. 

<b>update_nemo_nl</b> - perl script to update namelists each cycle
