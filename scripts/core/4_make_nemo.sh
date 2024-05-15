#!/bin/bash

#############################################
# Build NEMO
#############################################
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

#Build
export FABM_HOME=$FABM_BUILD
export XIOS_HOME=$XIOS_BUILD
cd $NEMO_DIR

#Define architecture
ARCH=X86_ARCHER2-Cray_FABM
yes | cp $CODE_DIR/archer2-files/nemo/Config_cray.pm $NEMO_DIR/ext/FCM/lib/Fcm/Config.pm

REF=AMM7_FABM
printf 'y\nn\nn\ny\nn\nn\nn\nn\n' |./makenemo -n $NEMO_CFG -r $REF -m $ARCH -j 0
./makenemo -n $NEMO_CFG -r $REF -m $ARCH -j 4 clean
rsync -avz $CODE_DIR/MY_SRC $NEMO_DIR/cfgs/$NEMO_CFG/
./makenemo -n $NEMO_CFG -r $REF -m $ARCH -j 16

cd $WORK
