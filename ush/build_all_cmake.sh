#!/bin/sh

set -ex

cd ..
dir_root=$(pwd)

build_type=${1:-'PRODUCTION'}
dir_root=${2:-$dir_root}
mode=${3:-'EMC'}


# If NCO build, prune directories and files before build
if [ $mode = NCO ]; then
    cd $dir_root/ush
    $dir_root/ush/prune_4nco_global.sh prune
fi


# Initialize and load modules
if [[ -d /dcom && -d /hwrf ]] ; then
    . /usrx/local/Modules/3.2.10/init/sh
    target=wcoss
    . $MODULESHOME/init/sh
elif [[ -d /cm ]] ; then
    . $MODULESHOME/init/sh
    target=wcoss_c
elif [[ -d /ioddev_dell ]]; then
    . $MODULESHOME/init/sh
    target=wcoss_d
elif [[ -d /scratch1 ]] ; then
    . /apps/lmod/lmod/init/sh
    target=hera
elif [[ -d /carddata ]] ; then
    . /opt/apps/lmod/3.1.9/init/sh
    target=s4
elif [[ -d /jetmon ]] ; then
    . $MODULESHOME/init/sh
    target=jet
elif [[ -d /glade ]] ; then
    . $MODULESHOME/init/sh
    target=cheyenne
elif [[ -d /sw/gaea ]] ; then
    . /opt/cray/pe/modules/3.2.10.5/init/sh
    target=gaea
elif [[ -d /discover ]] ; then
#   . /opt/cray/pe/modules/3.2.10.5/init/sh
    target=discover
    build_type=0
    export SPACK_ROOT=/discover/nobackup/mapotts1/spack
    export PATH=$PATH:$SPACK_ROOT/bin
    . $SPACK_ROOT/share/spack/setup-env.sh    
elif [[ -d /work ]]; then
    . $MODULESHOME/init/sh
    target=orion
elif [[ -d /lfs/h2 ]] ; then
    target=wcoss2
else
    echo "unknown target = $target"
    exit 9
fi

dir_modules=$dir_root/modulefiles
dir_versions=$dir_root/versions
if [ ! -d $dir_modules ]; then
    echo "modulefiles does not exist in $dir_modules"
    exit 10
fi

if [ $target = wcoss_d ]; then
    module purge
    module use -a $dir_modules
    module load modulefile.ProdGSI.$target
elif [ $target = wcoss -o $target = gaea ]; then
    module purge
    module load $dir_modules/modulefile.ProdGSI.$target
elif [ $target = hera -o $target = cheyenne -o $target = orion ]; then
    module purge
    source $dir_modules/modulefile.ProdGSI.$target
elif [ $target = wcoss_c ]; then
    module purge
    module load $dir_modules/modulefile.ProdGSI.$target
elif [ $target = discover ]; then
    module load $dir_modules/modulefile.ProdGSI.$target
elif [ $target = wcoss2 ]; then
    module purge
    source $dir_versions/build.ver
    module use $dir_modules
    module load modulefile.ProdGSI.$target
    module list
else 
    module purge
    source $dir_modules/modulefile.ProdGSI.$target
fi


# Create exec and build directories
[ -d $dir_root/exec ] || mkdir -p $dir_root/exec
rm -rf $dir_root/build
mkdir -p $dir_root/build
cd $dir_root/build


# Execute cmake
if [ $build_type = PRODUCTION -o $build_type = DEBUG ] ; then
  cmake -DBUILD_UTIL=ON -DBUILD_NCDIAG_SERIAL=ON -DCMAKE_BUILD_TYPE=$build_type -DBUILD_CORELIBS=OFF ..
else 
  cmake ..
fi


# Build apps.  Echo extra printout for NCO build
if [ $mode = NCO ]; then
    make VERBOSE=1 -j 8
else
    make -j 8
fi
rc=$?


# If NCO build is successful, remove build directory
if [ $mode = NCO -a $rc -eq 0 ]; then
    rm -rf $dir_root/build
fi

exit
