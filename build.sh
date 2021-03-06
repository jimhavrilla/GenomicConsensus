#!/bin/bash

echo "# DEPENDENCIES"
echo "## Load modules"
source /mnt/software/Modules/current/init/bash
module load git gcc/5.3.0 python/2.7.9 cmake cram swig ccache virtualenv zlib/1.2.5 ninja boost

echo "## Get into virtualenv"
if [ ! -d venv ]
then
    /mnt/software/v/virtualenv/13.0.1/virtualenv.py venv
fi
source venv/bin/activate

echo "## Install pip modules"
pip install --upgrade pip
pip install numpy cython h5py pysam cram nose jsonschema avro
pip install --no-deps git+https://github.com/PacificBiosciences/pbcommand.git
pip install --no-deps git+https://github.com/PacificBiosciences/pbcore.git

echo "## Get external dependencies"
if [ ! -d _deps ] ; then mkdir _deps ; fi

echo "### Get PacBioTestData"
if [ ! -d _deps/PacBioTestData ]
then
    ( cd _deps                                                         &&\
    git clone https://github.com/PacificBiosciences/PacBioTestData.git &&\
    cd PacBioTestData                                                  &&\
    git lfs pull                                                       &&\
    make python )
fi

echo "## Fetch unanimity submodules"
( cd _deps/unanimity && git submodule update --init --remote )

echo "# BUILD"
echo "## pip install CC2"
( cd _deps/unanimity && CMAKE_BUILD_TYPE=ReleaseWithAssert CMAKE_COMMAND=cmake ZLIB_INCLUDE_DIR=/mnt/software/z/zlib/1.2.5/include ZLIB_LIBRARY=/mnt/software/z/zlib/1.2.5/lib/libz.so VERBOSE=1 pip install --verbose --upgrade --no-deps . )

echo "## install ConsensusCore"
( cd _deps/ConsensusCore && python setup.py install --boost=$BOOST_ROOT )

echo "## install GC"
( pip install --upgrade --no-deps --verbose . )

echo "# TEST"
echo "## CC2 version test"
python -c "import ConsensusCore2 ; print ConsensusCore2.__version__"

echo "## test CC2 via GC"
make check

deactivate