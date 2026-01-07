#/bin/bash

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
REF=AMM7

printf 'y\nn\nn\ny\nn\nn\nn\nn\n' |./makenemo -n $NEMO_CFG -r $REF -m $NEMO_ARCH -j 0
./makenemo -n $NEMO_CFG -r $REF -m $NEMO_ARCH -j 4 clean
rsync -avz $CODE_DIR/MY_SRC $NEMO_DIR/cfgs/$NEMO_CFG/
./makenemo -n $NEMO_CFG -r $REF -m $NEMO_ARCH -j 16

cd $WORK
