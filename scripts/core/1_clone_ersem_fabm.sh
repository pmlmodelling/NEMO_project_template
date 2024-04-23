#!/bin/bash
  
# Clone code bases for XIOS, ERSEM, FABM and NEMO
ERSEM_DIR=$CODE_DIR/ersem
ERSEM_REV=373b142e531736c1845304cd37c2a6002804e98c
git clone https://github.com/pmlmodelling/ersem.git $ERSEM_DIR
cd $ERSEM_DIR && git checkout $ERSEM_REV

FABM_DIR=$CODE_DIR/fabm
FABM_REV=25c4d1cb3afcaca87dc103cc60f0a9e8abac0796
git clone https://github.com/fabm-model/fabm.git $FABM_DIR
cd $FABM_DIR && git checkout $FABM_REV

cd $WORK_DIR

