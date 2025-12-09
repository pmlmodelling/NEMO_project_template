#!/bin/bash --login
#
#SBATCH --job-name=archive_AMM7
#SBATCH --time=02:30:00
#SBATCH --ntasks=30
#SBATCH --nodes=1
#SBATCH --account=n01-PML  
#SBATCH --partition=serial
#SBATCH --qos=serial




# Set the number of threads to 1
#   This prevents any threaded system libraries from automatically 
#   using threading.


source /work/n01/n01/yuti/AMM7_projections/scripts/config.sh

#export OMP_NUM_THREADS=1
#module restore /etc/cray-pe.d/PrgEnv-gnu
	


#y0=$1
#yb=$(( y0 - 1 ))

#mkdir -p $ARCHIVEDIR

#./archive_rm_restarts.sh $yb

#cd /work/n01/n01/yuti/AMM7_projections/RUN/CNRM-ESM2/restarts/

/work/n01/n01/yuti/clean_projections/scripts/rebuild_nemo.exe nam_rebuild_trc 
/work/n01/n01/yuti/clean_projections/scripts/rebuild_nemo.exe nam_rebuild 
#nccopy -k 4 -d 5 restart.nc $ARCHIVEDIR/restart.nc && echo "   restart.nc" || echo '   restart.nc failed!!!'
#nccopy -k 4 -d 5 restart_trc.nc $ARCHIVEDIR/restart_trc.nc && echo "   restart_trc.nc" || echo '   restart_trc.nc failed!!!' 




