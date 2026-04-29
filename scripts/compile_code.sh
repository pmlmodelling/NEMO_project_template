#!/bin/bash

#########################################
# EXPORT PATHS
#########################################

source config.sh
cd $CODE_DIR
mkdir -p $EXECUTABLE_DIR

########################################
# Clone code
#########################################

while getopts :x xios; do
    case ${xios} in
        x)
          while getopts :c clone; do
            case ${clone} in
                c) 
                  echo "Cloning XIOS"
                  bash $SCRIPTS_DIR/compile-scripts/1_clone_xios.sh
                  bash $SCRIPTS_DIR/compile-scripts/2_make_xios.sh
                  ;;
            esac
          done
          echo "Building XIOS"
          bash $SCRIPTS_DIR/compile-scripts/2_make_xios.sh
          if [ -f $XIOS_BUILD/bin/xios_server.exe ]; then
            ln -s $XIOS_BUILD/bin/xios_server.exe $EXECUTABLE_DIR/xios_server.exe
          else
            echo "XIOS Build Failed"
          fi
          ;;
    esac
done
OPTIND=1
while getopts :f fabm; do
    case ${fabm} in
        f)
          while getopts :c clone; do
            case ${clone} in
                c) 
                  echo "Cloning ERSEM and FABM"
                  bash $SCRIPTS_DIR/compile-scripts/1_clone_ersem_fabm.sh
                  ;;
            esac
          done
          echo "Building FABM"
          bash $SCRIPTS_DIR/compile-scripts/3_make_fabm.sh
          ;;
    esac
done
OPTIND=1
while getopts :n nemo; do
    case ${nemo} in
        n)
          while getopts :c clone; do
            case ${clone} in
                c) 
                  echo "Cloning NEMO"
                  bash $SCRIPTS_DIR/compile-scripts/1_clone_nemo.sh
                  ;;
            esac
          done
          echo "Building NEMO"
          bash $SCRIPTS_DIR/compile-scripts/4_make_nemo.sh
          if [ -f $NEMO_DIR/cfgs/$NEMO_CFG/BLD/bin/nemo.exe ]; then
            ln -s $NEMO_DIR/cfgs/$NEMO_CFG/BLD/bin/nemo.exe $EXECUTABLE_DIR/nemo
          else
            echo "NEMO Build Failed"
          fi
          ;;
    esac
done

cd $SCRIPTS_DIR


