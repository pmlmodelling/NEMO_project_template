#!/bin/bash

#############################################
# Build NEMO
#############################################
source ../config.sh

#Build
export FABM_HOME=$CODE_DIR/fabm-build
export XIOS_HOME=$CODE_DIR/xios-build
export NEMO_DIR=$CODE_DIR/nemo
cd $NEMO_DIR

#Define architecture
ARCH=X86_ARCHER2-Cray_FABM
yes | cp $CODE_DIR/archer2-files/nemo/Config_cray.pm $NEMO_DIR/ext/FCM/lib/Fcm/Config.pm

CFG=AMM7_FABM_BENCHMARK
REF=AMM7_FABM
printf 'y\nn\nn\ny\nn\nn\nn\nn\n' |./makenemo -n $CFG -r $REF -m $ARCH -j 0
./makenemo -n $CFG -r $REF -m $ARCH -j 4 clean
rsync -avz $CODE_DIR/MY_SRC $NEMO_DIR/cfgs/$CFG/
./makenemo -n $CFG -r $REF -m $ARCH -j 16

cd $WORK
