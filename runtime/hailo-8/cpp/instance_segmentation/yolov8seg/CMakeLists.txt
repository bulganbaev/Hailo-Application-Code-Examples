cmake_minimum_required(VERSION 3.18)      # 3.18+ → FetchContent без лишнего
project(vstream_yolov8seg_example_cpp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(COMPILE_OPTIONS
        -Werror -Wall -Wextra -Wconversion -O3
        -Wno-reorder -Wno-ignored-qualifiers -Wno-unused-value
)
add_compile_options(${COMPILE_OPTIONS})
find_package(Threads)
find_package(OpenCV REQUIRED)
find_package(HailoRT REQUIRED)

# ---------- Fetch & build xtl / xtensor / xtensor-blas ----------
include(FetchContent)
set(EXTERNAL_INSTALL ${CMAKE_BINARY_DIR}/external)

function(fetch_and_install name url tag)
    FetchContent_Declare(${name}
            URL       ${url}
            URL_HASH  SHA256=${tag}      # уникальный, меняем на реальный хэш
    )
    FetchContent_MakeAvailable(${name})
    # ручная install, чтобы всё попало в ${EXTERNAL_INSTALL}
    add_custom_target(${name}-install ALL
            COMMAND ${CMAKE_COMMAND} -E make_directory ${name}-build
            COMMAND ${CMAKE_COMMAND} -S ${${name}_SOURCE_DIR} -B ${name}-build
            -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL}
            -DCMAKE_BUILD_TYPE=Release
            -DBUILD_TESTS=OFF
            COMMAND ${CMAKE_COMMAND} --build ${name}-build --target install
            BYPRODUCTS ${EXTERNAL_INSTALL}/include
    )
endfunction()

# xtl 0.8.0
fetch_and_install(xtl
        https://github.com/xtensor-stack/xtl/archive/refs/tags/0.8.0.tar.gz
        c96ff3c2b24ae74bb9cc5eba020a6a2318efcfaa281944278f2dfd0468b2ab07
)

# xtensor 0.26.0
fetch_and_install(xtensor
        https://github.com/xtensor-stack/xtensor/archive/refs/tags/0.26.0.tar.gz
        09b9f0b9f04aa2d2170d02f2667cb6db8b2ab512cb56225784e26405b6758b43
)

# xtensor-blas 0.22.0
fetch_and_install(xtensor_blas
        https://github.com/xtensor-stack/xtensor-blas/archive/refs/tags/0.22.0.tar.gz
        5d72b1a4a315096d17c6901490bb1b18c2ab4c93816be0b4242d6dc35a5d9c00
)

# ---------- «Раздаём» обёртки x*.hpp в корень xtensor ----------
add_custom_target(xt-wrap ALL
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/wrap.cmake
        DEPENDS xtensor-install
)

file(WRITE ${CMAKE_BINARY_DIR}/wrap.cmake
        "file(GLOB_RECURSE hdrs \"${EXTERNAL_INSTALL}/include/xtensor/*/x*.hpp\")\n"
        "foreach(h IN LISTS hdrs)\n"
        "  get_filename_component(base \${h} NAME)\n"
        "  set(dst \"${EXTERNAL_INSTALL}/include/xtensor/\${base}\")\n"
        "  if(NOT EXISTS \${dst})\n"
        "    execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink \${h} \${dst})\n"
        "  endif()\n"
        "endforeach()\n"
)

# ---------- основной таргет ----------
file(GLOB SRC *.cpp)
add_executable(${PROJECT_NAME} ${SRC})
add_dependencies(${PROJECT_NAME}
        xtl-install xtensor-install xtensor_blas-install xt-wrap)

target_include_directories(${PROJECT_NAME} PRIVATE
        ${EXTERNAL_INSTALL}/include
        ${OpenCV_INCLUDE_DIRS}
)

target_link_directories(${PROJECT_NAME} PRIVATE ${EXTERNAL_INSTALL}/lib)
target_link_libraries(${PROJECT_NAME}
        HailoRT::libhailort
        ${OpenCV_LIBS}
        Threads::Threads
)
