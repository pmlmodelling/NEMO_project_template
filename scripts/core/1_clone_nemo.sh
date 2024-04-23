#!/bin/bash
  
NEMO_DIR=$CODE_DIR/nemo
NEMO_REV=c2c5f0f05923145423141b8d435df1aa066a14e5
git clone https://github.com/pmlmodelling/NEMO4.0-FABM.git $NEMO_DIR
cd $NEMO_DIR && git checkout $NEMO_REV

cd $WORK_DIR

