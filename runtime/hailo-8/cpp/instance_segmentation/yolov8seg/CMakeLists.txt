# ---------------------------------------------------------------------------
#  CMakeLists.txt — vstream_yolov8seg_example_cpp
#
#  Cleaned-up version without the automatic download / build of
#  xtl, xtensor, and xtensor-blas.
#
#  Copy this entire file as-is and place it in the project root.
# ---------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.11)
project(vstream_yolov8seg_example_cpp)

# ---------------------------------------------------------------------------
#  Toolchain & compiler settings
# ---------------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 20)

# Strict warnings + high-O, but keep noisy ones disabled
set(COMPILE_OPTIONS
        -Werror -Wall -Wextra -Wconversion -O3
        -Wno-reorder -Wno-ignored-qualifiers -Wno-extra
        -Wno-unused-local-typedefs -Wno-conversion -Wno-parentheses
        -Wno-unused-but-set-variable -Wno-array-bounds -Wno-unused-value
)

# ---------------------------------------------------------------------------
#  Paths
# ---------------------------------------------------------------------------
set(BASE_DIR /path/to/yolov8seg/example/folder)   # ← adjust to your source tree

# ---------------------------------------------------------------------------
#  Thread support
# ---------------------------------------------------------------------------
set(CMAKE_THREAD_LIBS_INIT "-lpthread")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
set(CMAKE_HAVE_THREADS_LIBRARY 1)
set(CMAKE_USE_WIN32_THREADS_INIT 0)
set(CMAKE_USE_PTHREADS_INIT 1)
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads)

# ---------------------------------------------------------------------------
#  External libraries
# ---------------------------------------------------------------------------
find_package(HailoRT REQUIRED)        # Provides HailoRT::libhailort target
find_package(OpenCV REQUIRED)         # Populates OpenCV_LIBS / OpenCV_INCLUDE_DIRS

message(STATUS "Found OpenCV headers at: ${OpenCV_INCLUDE_DIRS}")

# ---------------------------------------------------------------------------
#  Project sources
# ---------------------------------------------------------------------------
file(GLOB SOURCES
        ./*.cpp
)

# ---------------------------------------------------------------------------
#  Target definition
# ---------------------------------------------------------------------------
add_executable(${PROJECT_NAME} ${SOURCES})

# Include directories (OpenCV + optional ONNX Runtime if you use it)
include_directories(
        ${OpenCV_INCLUDE_DIRS}
        ${ONNXRUNTIME_INCLUDE_DIR}         # Define this in your toolchain/file if needed
)

# Compile options
target_compile_options(${PROJECT_NAME} PRIVATE ${COMPILE_OPTIONS} -fconcepts)

# Link libraries
target_link_libraries(${PROJECT_NAME}
        HailoRT::libhailort
        ${CMAKE_THREAD_LIBS_INIT}
        ${OpenCV_LIBS}
)

# ---------------------------------------------------------------------------
#  Notes
#
#  • The previous ExternalProject_Add blocks that automatically cloned and
#    built xtl / xtensor / xtensor-blas have been completely removed.
#
#  • If your code still depends on those headers, make sure they are installed
#    system-wide (e.g., via your package manager) or specify their include
#    paths with `target_include_directories` instead of rebuilding them here.
#
#  • C++20’s standard library already provides <filesystem>, so linking
#    against stdc++fs is no longer necessary.
# ---------------------------------------------------------------------------
