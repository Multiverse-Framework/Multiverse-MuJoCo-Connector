#!/bin/bash

start_time=$(date +%s)

CURRENT_DIR=$PWD
cd $(dirname $0)
SRC_DIR=$PWD/src
MUJOCO_VERSION=3.3.0
MUJOCO_SRC_DIR=$SRC_DIR/mujoco-$MUJOCO_VERSION
if [ ! -d $SRC_DIR ]; then
    mkdir -p $SRC_DIR
    MUJOCO_TAR_FILE=mujoco-$MUJOCO_VERSION.tar.gz
    curl -L -o $SRC_DIR/$MUJOCO_TAR_FILE https://github.com/google-deepmind/mujoco/archive/refs/tags/$MUJOCO_VERSION.tar.gz
    tar xf $SRC_DIR/$MUJOCO_TAR_FILE -C $MUJOCO_SRC_DIR --strip-components=1
    rm -f $SRC_DIR/$MUJOCO_TAR_FILE
fi

BUILD_DIR=$PWD/build
INSTALL_DIR=$PWD/install
if [ ! -d $INSTALL_DIR ]; then
    mkdir -p $INSTALL_DIR
fi
if [ ! -d $BUILD_DIR ]; then
    mkdir -p $BUILD_DIR
fi

ln -sf $PWD/plugin/multiverse_connector $MUJOCO_SRC_DIR/plugin
CMAKE_PATH=$MUJOCO_SRC_DIR/CMakeLists.txt
LINE_TO_ADD="add_subdirectory(plugin/multiverse_connector)"
if ! grep -Fxq "$LINE_TO_ADD" "$CMAKE_PATH"; then
    echo "$LINE_TO_ADD" >> $CMAKE_PATH
fi

cmake -S $MUJOCO_SRC_DIR -B $BUILD_DIR -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DMUJOCO_BUILD_EXAMPLES=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_BUILD_SIMULATE=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF
cmake --build $BUILD_DIR
cmake --install $BUILD_DIR

cp -f $BUILD_DIR/lib/libmultiverse_connector.so $PWD/mujoco_plugin
ln -sf $PWD/mujoco_plugin $INSTALL_DIR/bin

end_time=$(date +%s)
elapsed=$(( end_time - start_time ))

echo "Build completed in $elapsed seconds"