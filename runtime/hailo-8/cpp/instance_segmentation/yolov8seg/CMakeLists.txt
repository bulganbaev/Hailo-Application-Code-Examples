cmake_minimum_required(VERSION 3.18)           # FetchContent без лишних флагов
project(vstream_yolov8seg_example_cpp LANGUAGES CXX)

# ---------------------------------------------------------------------------
# ⬤  Общие опции компилятора
# ---------------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS   OFF)

set(COMMON_WARNINGS
        -Wall -Wextra -Wconversion -Werror
        -Wno-reorder -Wno-ignored-qualifiers -Wno-unused-value
)
add_compile_options(${COMMON_WARNINGS} -O3 -fconcepts)

find_package(Threads REQUIRED)
find_package(OpenCV  REQUIRED)
find_package(HailoRT REQUIRED)

# ---------------------------------------------------------------------------
# ⬤  FetchContent: xtl ▸ xtensor ▸ xtensor-blas
# ---------------------------------------------------------------------------
include(FetchContent)

set(EXTERNAL_INSTALL "${CMAKE_BINARY_DIR}/external")   # единая install-точка
set(BUILD_TYPE       Release)

function(fetch_and_install NAME GIT_URL GIT_TAG)
    FetchContent_Declare(${NAME}
            GIT_REPOSITORY  ${GIT_URL}
            GIT_TAG         ${GIT_TAG}
    )
    FetchContent_MakeAvailable(${NAME})

    add_custom_target(${NAME}-install ALL
            COMMAND ${CMAKE_COMMAND} -S ${${NAME}_SOURCE_DIR} -B ${NAME}-build
            -DCMAKE_BUILD_TYPE=${BUILD_TYPE}
            -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL}
            -DBUILD_TESTS=OFF
            COMMAND ${CMAKE_COMMAND} --build ${NAME}-build --target install -j
            BYPRODUCTS ${EXTERNAL_INSTALL}/include
            COMMENT "Installing ${NAME} → ${EXTERNAL_INSTALL}"
    )
endfunction()

fetch_and_install(xtl          https://github.com/xtensor-stack/xtl.git            0.8.0)
fetch_and_install(xtensor      https://github.com/xtensor-stack/xtensor.git        0.26.0)
fetch_and_install(xtensorblas  https://github.com/xtensor-stack/xtensor-blas.git   0.22.0)

# ---------------------------------------------------------------------------
# ⬤  Раздать “x*.hpp” в корень xtensor/ (обёртки для старых include-путей)
# ---------------------------------------------------------------------------
add_custom_target(xtensor-wrap ALL
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/wrap_xtensor.cmake
        DEPENDS xtensorblas-install        # ждём, пока xtensor уже установлен
        COMMENT "Creating wrapper x*.hpp links in xtensor/"
)

file(WRITE ${CMAKE_BINARY_DIR}/wrap_xtensor.cmake
        "file(GLOB_RECURSE hdrs \"${EXTERNAL_INSTALL}/include/xtensor/*/x*.hpp\")\n"
        "foreach(hdr IN LISTS hdrs)\n"
        "  get_filename_component(base \${hdr} NAME)\n"
        "  set(dst \"${EXTERNAL_INSTALL}/include/xtensor/\${base}\")\n"
        "  if(NOT EXISTS \${dst})\n"
        "    execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink \${hdr} \${dst})\n"
        "  endif()\n"
        "endforeach()\n"
)

# ---------------------------------------------------------------------------
# ⬤  Исходники примера
# ---------------------------------------------------------------------------
file(GLOB SRC CONFIGURE_DEPENDS *.cpp)

add_executable(${PROJECT_NAME} ${SRC})
add_dependencies(${PROJECT_NAME}
        xtl-install xtensor-install xtensorblas-install xtensor-wrap
)

# include / lib для внешних пакетов
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

# ---------------------------------------------------------------------------
# ⬤  Пара удобных сообщений
# ---------------------------------------------------------------------------
message(STATUS "")
message(STATUS " ───────── Build configuration ─────────")
message(STATUS "   Install dir:  ${EXTERNAL_INSTALL}")
message(STATUS "   xtl tag:      0.8.0")
message(STATUS "   xtensor tag:  0.26.0")
message(STATUS "   xtensor-blas: 0.22.0")
message(STATUS " ───────────────────────────────────────")
