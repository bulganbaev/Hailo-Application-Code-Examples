cmake_minimum_required(VERSION 3.18)
project(vstream_yolov8seg_example_cpp LANGUAGES CXX)

# ──────────────────────────────  компилятор  ───────────────────────────────
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS  OFF)

set(COMMON_WARNINGS
        -Wall -Wextra -Wconversion -Werror
        -Wno-reorder -Wno-ignored-qualifiers -Wno-unused-value
)
add_compile_options(${COMMON_WARNINGS} -O3 -fconcepts)

# ──────────────────────────────  зависимости  ──────────────────────────────
find_package(Threads  REQUIRED)
find_package(OpenCV   REQUIRED)
find_package(HailoRT  REQUIRED)
find_package(xtl      REQUIRED)          # ищет xtlConfig.cmake
find_package(xtensor  REQUIRED)          # ищет xtensorConfig.cmake
find_package(xtensor-blas REQUIRED)      # ищет xtensor-blasConfig.cmake

# Если библиотеки лежат НЕ в /usr/local, добавьте:
#   cmake -DCMAKE_PREFIX_PATH="/opt/xtensor;/opt/xtl" …

# ─────────────────────  «обёртки» x*.hpp (по желанию)  ─────────────────────
# Если ваши готовые пакеты xtensor уже кладут xview.hpp, xarray.hpp и т. д.
# в корень include/xtensor, блок ниже можно удалить/закомментировать.

set(XTENSOR_INCLUDE_DIR "${xtensor_DIR}/../../include/xtensor") # путь от xtensorConfig.cmake
add_custom_target(xtensor-wrap ALL
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/wrap_xtensor.cmake
        BYPRODUCTS "${XTENSOR_INCLUDE_DIR}/xview.hpp"
        COMMENT "Creating wrapper x*.hpp links in xtensor/"
)

file(WRITE ${CMAKE_BINARY_DIR}/wrap_xtensor.cmake
        "file(GLOB_RECURSE hdrs \"${XTENSOR_INCLUDE_DIR}/*/x*.hpp\")\n"
        "foreach(hdr IN LISTS hdrs)\n"
        "  get_filename_component(base \${hdr} NAME)\n"
        "  set(dst \"${XTENSOR_INCLUDE_DIR}/\${base}\")\n"
        "  if(NOT EXISTS \${dst})\n"
        "    execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink \${hdr} \${dst})\n"
        "  endif()\n"
        "endforeach()\n"
        "\n"
        "# подпапки (core / containers / views / misc ...) → уровень выше\n"
        "file(GLOB dirs \"${XTENSOR_INCLUDE_DIR}/*\")\n"
        "foreach(d IN LISTS dirs)\n"
        "  if(IS_DIRECTORY \${d})\n"
        "    get_filename_component(base \${d} NAME)\n"
        "    set(link \"${XTENSOR_INCLUDE_DIR}/../\${base}\")\n"
        "    if(NOT EXISTS \${link})\n"
        "      execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink \${d} \${link})\n"
        "    endif()\n"
        "  endif()\n"
        "endforeach()\n"
)

# ─────────────────────────────  исходники  ────────────────────────────────
file(GLOB SRC CONFIGURE_DEPENDS *.cpp)

add_executable(${PROJECT_NAME} ${SRC})
add_dependencies(${PROJECT_NAME} xtensor-wrap)   # уберите, если wrap не нужен

target_include_directories(${PROJECT_NAME} PRIVATE
        ${OpenCV_INCLUDE_DIRS}
)

target_link_libraries(${PROJECT_NAME}
        HailoRT::libhailort
        xtensor-blas::xtensor-blas
        xtensor::xtensor
        xtl::xtl
        ${OpenCV_LIBS}
        Threads::Threads
)

# ─────────────────────────────  вывод  ────────────────────────────────
message(STATUS "\n ─────── Build configuration ───────")
message(STATUS "   xtl dir:          ${xtl_DIR}")
message(STATUS "   xtensor dir:      ${xtensor_DIR}")
message(STATUS "   xtensor-blas dir: ${xtensor-blas_DIR}")
message(STATUS " ─────────────────────────────────────\n")
