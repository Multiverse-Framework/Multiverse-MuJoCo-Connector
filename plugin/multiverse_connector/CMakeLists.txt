set(MUJOCO_MULTIVERSE_CONNECTOR_INCLUDE 
  ${CMAKE_CURRENT_SOURCE_DIR}/../..
  ${CMAKE_CURRENT_SOURCE_DIR}/../../src
)

set(MUJOCO_MULTIVERSE_CONNECTOR_SRCS
  multiverse_connector.cc
  multiverse_connector.h
  register.cc
)

add_library(multiverse_connector SHARED)
target_sources(multiverse_connector PRIVATE ${MUJOCO_MULTIVERSE_CONNECTOR_SRCS})
target_include_directories(multiverse_connector PRIVATE ${MUJOCO_MULTIVERSE_CONNECTOR_INCLUDE})
target_link_libraries(multiverse_connector PRIVATE 
  mujoco
  ${CMAKE_CURRENT_SOURCE_DIR}/libmultiverse_client_json.a
  ${CMAKE_CURRENT_SOURCE_DIR}/libmultiverse_client.a
  ${CMAKE_CURRENT_SOURCE_DIR}/libjsoncpp.a
  ${CMAKE_CURRENT_SOURCE_DIR}/libzmq.a
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
