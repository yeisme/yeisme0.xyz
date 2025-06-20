+++
title = "现代 CMake 学习（1）"
date = "2025-06-20T15:52:40+08:00"
description = ""
tags = ["CMake","C++","C"]
categories = ["编程"]
series = []
aliases = []
image = ""
draft = false
+++

# 现代 CMake 学习（1）

## 引言

> CMake 是现代 C/C++ 开发生态中不可或缺的工具之一。它不仅是一个构建系统生成器，更是连接代码组织、依赖管理、测试和部署流程的核心枢纽。本文将从基础到进阶，逐步介绍如何使用 现代 CMake（Modern CMake） 来构建一个结构清晰、易于维护、跨平台的 C/C++ 项目。

很多人讨厌 cmake 的原因是因为它的语法和逻辑与传统的 Makefile 有很大不同，但实际上 CMake 提供了更强大的功能和更好的跨平台支持，而且 cmake 命令通常都是语义化的，易于理解，这也是我个人非常喜欢 CMake 的原因（因人而异，就像 PowerShell）。

我计划写 10 篇文章来介绍 CMake 的使用，本文是第一篇，主要介绍 CMake 的基础知识和命令行工具的使用。

## cmake cli

> cmake 命令行工具不是必学的，通过使用各种 IDE（如 Visual Studio、CLion、Qt Creator 等）可以更方便地使用 CMake。但了解 cmake 的命令行工具可以帮助我们更好地理解 CMake 的工作原理和配置方式(推荐学习)。

cmake 主要有 3 个命令行工具：

1. `cmake`：CMake 的主命令行工具，用于配置和生成构建系统。
2. `ctest`：CMake 测试工具，用于运行和管理测试。
3. `cpack`：CMake 包管理工具，用于处理 CMake 包。

### 1. `cmake` - 主配置工具

```bash
# 配置项目（生成构建文件）
cmake -S . -B build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

# 构建项目
cmake --build build
cmake --build build --config Release --target MyTarget

# 安装项目
cmake --install build --prefix /usr/local
```

### 2. `ctest` - 测试工具

```bash
# 运行所有测试
ctest --test-dir build

# 运行特定测试
ctest --test-dir build -R "TestName"

# 并行运行测试
ctest --test-dir build -j 4
```

### 3. `cpack` - 打包工具

```bash
# 生成安装包
cpack --config build/CPackConfig.cmake
```

## 一个基础 CMakeLists.txt 文件

以一个简单的 C++ 项目为例，假设我们有一个名为 `MyProject` 的项目，包含一个可执行文件 `MyExecutable` 和一个外部库 `MyLibrary`。我们需要在 CMakeLists.txt 中配置这些内容。

```cmake
cmake_minimum_required(VERSION 3.10)

project(MyProject)

find_package(MyLibrary REQUIRED)

add_executable(MyExecutable main.cpp)

set(CMAKE_CXX_STANDARD 17)

# 添加头文件搜索路径
target_include_directories(
    MyExecutable PRIVATE ${CMAKE_SOURCE_DIR}/include
    ${MyLibrary_INCLUDE_DIRS}
)

# 添加库文件搜索路径
target_link_libraries(MyExecutable PRIVATE MyLibrary)
```

- `cmake_minimum_required`: 指定 CMake 的最低版本要求。
- `project`: 定义项目的名称和版本。
- `find_package`: 查找并配置外部库。
- `add_executable`: 添加可执行文件，指定源文件。
- `set`: 设置变量或属性，CMAKE_CXX_STANDARD 是 CMake 的内置变量，用于指定 C++ 标准版本。
- `target_include_directories`: 添加头文件搜索路径，对于 gcc 编译器来说，通常使用 `-I` 选项。
- `target_link_libraries`: 链接库文件，对于 gcc 编译器来说，通常使用 `-l` 选项。

对于一个 C++ 项目而言，CMakeLists.txt 文件通常包含以下几个部分：

1. 项目基本信息
2. 查找依赖库
3. 添加源文件
4. 设置编译选项

这个 CMakeLists.txt 文件是一个基础的示例，简单到可以直接用 gcc 命令行编译，唯一的优势是它可以跨平台(自动处理不同平台的编译选项和依赖)。

```bash
gcc -o MyExecutable main.cpp -Iinclude -lMyLibrary
```

## 子目录和多目标项目

在实际项目中，我们通常会将源代码组织成多个子目录，每个子目录可能包含一个或多个目标（可执行文件或库）。CMake 提供了 `add_subdirectory` 命令来处理这种情况。

以 [opencv_class](https://github.com/yeisme/opencv_class/tree/main) 这个项目为例，它包含多个子目录，每个子目录都有自己的 CMakeLists.txt 文件。我们可以在主 CMakeLists.txt 中使用 `add_subdirectory` 来包含这些子目录。

项目结构如下：

```txt
.
├── class1
│   ├── CMakeLists.txt
│   └── main.cpp
├── class2
│   ├── CMakeLists.txt
│   └── main.cpp
├── class3
│   ├── CMakeLists.txt
│   └── main.cpp
├── class4
│   ├── CMakeLists.txt
│   └── main.cpp
├── class5
│   ├── CMakeLists.txt
│   └── main.cpp
├── class6
│   ├── CMakeLists.txt
│   └── main.cpp
├── class7
│   ├── CMakeLists.txt
│   ├── include
│   │   └── utils.h
│   ├── main.cpp
│   └── utils.cpp
├── CMakeLists.txt
├── LICENSE.txt
└── README.md
```

主 CMakeLists.txt 文件是整个项目的入口点，它包含了所有子目录的 CMakeLists.txt 文件，并配置了共享的编译选项和依赖，通过 `add_library(shared_config INTERFACE)` 创建一个共享配置库，供所有子目录使用，所有子目录的 CMakeLists.txt 文件都可以链接这个共享配置库，从而共享编译选项和依赖。

```cmake
cmake_minimum_required(VERSION 3.30)

project(class_learn)

# vcpkg
# set(CMAKE_TOOLCHAIN_FILE ${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake)

# MV
set(MVS_LIB "C:/Program Files (x86)/MVS/Development")
set(MVFG_LIB "C:/Program Files (x86)/MVS/Development/MVFG")

file(GLOB MVS_LIBS "${MVS_LIB}/Libraries/win64/*.lib")
file(GLOB MVFG_LIBS "${MVFG_LIB}/Libraries/win64/*.lib")

# flags
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 创建共享配置库
add_library(shared_config INTERFACE)

# opencv: vcpkg install opencv4
set(OpenCV_ROOT "C:/Users/yeisme/lib/opencv")
find_package(OpenCV REQUIRED)

# 配置共享库
target_include_directories(shared_config INTERFACE
    "${MVS_LIB}/Includes"
    "${MVFG_LIB}/Includes"
    ${OpenCV_INCLUDE_DIRS}
)

target_link_libraries(shared_config INTERFACE
    ${MVS_LIBS}
    ${MVFG_LIBS}
    ${OpenCV_LIBS}
)

if(OpenCV_FOUND)
    message(STATUS "OpenCV version: ${OpenCV_VERSION}")
endif()

# 添加子目录
add_subdirectory(class1)
add_subdirectory(class2)
add_subdirectory(class3)
add_subdirectory(class4)
add_subdirectory(class5)
add_subdirectory(class6)
```

子 CMakeLists.txt 文件示例（以 class1 为例）：

```cmake
add_executable(class1_learn_test "test.cpp")
add_executable(class1_learn_main "main.cpp")

# 链接共享配置到两个可执行文件
target_link_libraries(class1_learn_test PRIVATE shared_config)
target_link_libraries(class1_learn_main PRIVATE shared_config)

# 创建自定义目标用于复制图像文件
add_custom_target(class1_copy_img_files ALL
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_SOURCE_DIR}/img
    ${CMAKE_CURRENT_BINARY_DIR}/img
    COMMENT "正在复制图像文件到构建目录..."
)

# 添加依赖关系，确保在构建可执行文件之前复制图像
add_dependencies(class1_learn_main class1_copy_img_files)
add_dependencies(class1_learn_test class1_copy_img_files)
```

### find\_\* 命令和查找变量

我发现非常多 CMake 用户对 `find_program`、`find_library` 和 `find_path` 等命令的使用不够熟悉，导致在查找依赖时遇到问题，非常多的教程都仅教学 `find_package` 命令，而忽略了其他查找命令的使用。

> 篇幅所限，本文不会详细介绍 `find_*` 命令的使用，后续会单独写一篇文章介绍。

| 变量组       | 主要变量                    | 功能描述           | 控制范围      |
| ------------ | --------------------------- | ------------------ | ------------- |
| **路径控制** | `CMAKE_PREFIX_PATH`         | 查找路径前缀列表   | find\_\* 命令 |
|              | `CMAKE_MODULE_PATH`         | CMake 模块搜索路径 | find_package  |
|              | `CMAKE_PROGRAM_PATH`        | 程序搜索路径       | find_program  |
|              | `CMAKE_LIBRARY_PATH`        | 库搜索路径         | find_library  |
|              | `CMAKE_INCLUDE_PATH`        | 头文件搜索路径     | find_path     |
| **系统路径** | `CMAKE_SYSTEM_PREFIX_PATH`  | 系统前缀路径       | 系统级查找    |
|              | `CMAKE_SYSTEM_LIBRARY_PATH` | 系统库路径         | 系统库查找    |
|              | `CMAKE_SYSTEM_INCLUDE_PATH` | 系统头文件路径     | 系统头文件    |
| **忽略路径** | `CMAKE_IGNORE_PATH`         | 忽略的路径列表     | 查找排除      |
|              | `CMAKE_IGNORE_PREFIX_PATH`  | 忽略的前缀路径     | 前缀排除      |

