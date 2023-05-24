#!/bin/bash

git clone https://github.com/pmlmodelling/NEMO-container.git $CONTAINER_DIR

cd $CONTAINER_DIR

singularity build /home/singularity/base_container/baseOS.sif /home/singularity/base_container/baseOS.def
singularity build /home/singularity/fabm.sif /home/singularity/fabm.def
singularity build /home/singularity/xios.sif /home/singularity/xios.def
singularity build /home/singularity/nemo.sif /home/singularity/nemo.def

# copying compiled sif file to executable directory 
cp $CONTAINER_DIR/nemo.sif $CODE_DIR/executable/nemo.sif

# creating NEMO and XIOS executables based on the `container_executable_template`
cp $CODE_DIR/NEMO-container/container_executable_template $CODE_DIR/executable/nemo
sed 's/NEMO_XIOS/nemo/' $CODE_DIR/executable/nemo
cp $CODE_DIR/NEMO-container/container_executable_template $CODE_DIR/executable/xios
sed 's/NEMO_XIOS/xios/' $CODE_DIR/executable/xios