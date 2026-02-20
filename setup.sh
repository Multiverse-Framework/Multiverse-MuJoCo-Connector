#!/bin/bash

start_time=$(date +%s)

cd $(dirname $0) || exit
SRC_DIR=$PWD/src

EXT_DIR=$PWD/ext
CMAKE_DIR=$EXT_DIR/CMake
if [ ! -d "$CMAKE_DIR" ]; then
    mkdir -p "$CMAKE_DIR"
    CMAKE_TAR_FILE=cmake-4.0.0-linux-x86_64.tar.gz
    curl -L -o "$EXT_DIR"/$CMAKE_TAR_FILE https://github.com/Kitware/CMake/releases/download/v4.0.0/$CMAKE_TAR_FILE
    tar xf "$EXT_DIR"/$CMAKE_TAR_FILE -C "$CMAKE_DIR" --strip-components=1
    rm -f "$EXT_DIR"/$CMAKE_TAR_FILE
fi
CMAKE_EXECUTABLE=$CMAKE_DIR/bin/cmake

# for MUJOCO_VERSION in 3.2.7 3.3.{0..7} 3.4.0; do
for MUJOCO_VERSION in 3.4.0; do
    echo "$MUJOCO_VERSION"
    MUJOCO_SRC_DIR=$SRC_DIR/mujoco-$MUJOCO_VERSION
    if [ ! -d "$MUJOCO_SRC_DIR" ]; then
        mkdir -p "$MUJOCO_SRC_DIR"
        MUJOCO_TAR_FILE=mujoco-$MUJOCO_VERSION.tar.gz
        curl -L -o "$SRC_DIR"/$MUJOCO_TAR_FILE https://github.com/google-deepmind/mujoco/archive/refs/tags/$MUJOCO_VERSION.tar.gz
        tar xf "$SRC_DIR"/$MUJOCO_TAR_FILE -C "$MUJOCO_SRC_DIR" --strip-components=1
        rm -f "$SRC_DIR"/$MUJOCO_TAR_FILE
    fi

    BUILD_DIR=$PWD/build/mujoco-$MUJOCO_VERSION
    INSTALL_DIR=$PWD/install/mujoco-$MUJOCO_VERSION
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
    fi
    if [ ! -d "$BUILD_DIR" ]; then
        mkdir -p "$BUILD_DIR"
    fi

    ln -sf "$PWD"/plugin/multiverse_connector "$MUJOCO_SRC_DIR"/plugin
    CMAKE_PATH=$MUJOCO_SRC_DIR/CMakeLists.txt
    LINE_TO_ADD="add_subdirectory(plugin/multiverse_connector)"
    if ! grep -Fxq "$LINE_TO_ADD" "$CMAKE_PATH"; then
        echo "$LINE_TO_ADD" >> "$CMAKE_PATH"
    fi

    if [ ! -f "$BUILD_DIR"/CMakeCache.txt ]; then
        $CMAKE_EXECUTABLE -S "$MUJOCO_SRC_DIR" -B "$BUILD_DIR" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" -DMUJOCO_BUILD_EXAMPLES=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_BUILD_SIMULATE=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF -DCMAKE_POLICY_VERSION_MINIMUM="3.5" -Wno-deprecated -Wno-dev
    fi
    $CMAKE_EXECUTABLE --build "$BUILD_DIR"
    $CMAKE_EXECUTABLE --install "$BUILD_DIR"

    MUJOCO_PLUGIN_DIR=$PWD/mujoco_plugin/mujoco-$MUJOCO_VERSION
    if [ ! -d "$MUJOCO_PLUGIN_DIR" ]; then
        mkdir -p "$MUJOCO_PLUGIN_DIR"
    fi
    cp -f "$BUILD_DIR"/lib/libmultiverse_connector.so "$MUJOCO_PLUGIN_DIR/libmultiverse_connector.so"
    if [ ! -f "$INSTALL_DIR"/bin/mujoco_plugin/libmultiverse_connector.so ]; then
        ln -sf "$MUJOCO_PLUGIN_DIR" "$INSTALL_DIR"/bin/mujoco_plugin
    fi

    end_time=$(date +%s)
    elapsed=$(( end_time - start_time ))

    echo "Build completed in $elapsed seconds"
done