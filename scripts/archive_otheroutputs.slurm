#!/bin/bash --login
#
#SBATCH --job-name=archive_AMM7
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --account=n01-PML  
#SBATCH --partition=serial
#SBATCH --qos=serial




# Set the number of threads to 1
#   This prevents any threaded system libraries from automatically 
#   using threading.


source /work/n01/n01/yuti/AMM7_projections/scripts/config.sh
module load nco 

outdir=$1
cd $outdir

echo"Archiving $outdir"

for f in $NAME*1d*grid_*
do
       ncks -4 -L5 $f $f.gz
       if [ -f $f.gz ]
       then
	rm $f
        mv $f.gz $f
       fi
done       
for f in $NAME*1d*.benthos_*
do
       ncks -4 -L5 $f $f.gz
       if [ -f $f.gz ]
       then
	rm $f
        mv $f.gz $f
       fi
done       
for f in $NAME*1m*_*
do
       ncks -4 -L5 $f $f.gz
       if [ -f $f.gz ]
       then
	rm $f
        mv $f.gz $f
       fi
done       



