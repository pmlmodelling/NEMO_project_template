#!/bin/bash --login
#
#SBATCH --job-name=archive_AMM7
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --account=n01-PML  
#SBATCH --partition=serial
#SBATCH --qos=serial
#SBATCH --mem=25GB




# Set the number of threads to 1
#   This prevents any threaded system libraries from automatically 
#   using threading.


source /work/n01/n01/rmilling/test_projections_2/scripts/config.sh
module load nco
outdir=$1
echo"Archiving $outdir"

cd $outdir

for f in $NAME*1d*.org_T*
do
       ncks -4 -L5 $f $f.gz
       if [ -f $f.gz ]
       then
	rm $f
        mv $f.gz $f
       fi
done       



