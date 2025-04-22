set(MUJOCO_MULTIVERSE_CONNECTOR_INCLUDE
  ${CMAKE_CURRENT_SOURCE_DIR}/../../src
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)

set(MUJOCO_MULTIVERSE_CONNECTOR_SRCS
  src/multiverse_connector.cc
  src/register.cc
)

set(MUJOCO_MULTIVERSE_CONNECTOR_LIB
  ${CMAKE_CURRENT_SOURCE_DIR}/lib
)

add_library(multiverse_connector SHARED)
target_sources(multiverse_connector PRIVATE ${MUJOCO_MULTIVERSE_CONNECTOR_SRCS})
target_include_directories(multiverse_connector PRIVATE ${MUJOCO_MULTIVERSE_CONNECTOR_INCLUDE})
target_link_directories(multiverse_connector PRIVATE ${MUJOCO_MULTIVERSE_CONNECTOR_LIB})
target_link_libraries(multiverse_connector PRIVATE 
  mujoco
  multiverse_client_json
  multiverse_client
  jsoncpp
  zmq
)
target_compile_options(
  multiverse_connector
  PRIVATE ${AVX_COMPILE_OPTIONS}
          ${MUJOCO_MACOS_COMPILE_OPTIONS}
          ${EXTRA_COMPILE_OPTIONS}
          ${MUJOCO_CXX_FLAGS}
)
target_link_options(
  multiverse_connector
  PRIVATE
  ${MUJOCO_MACOS_LINK_OPTIONS}
  ${EXTRA_LINK_OPTIONS}
)
