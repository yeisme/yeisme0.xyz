+++
title = "现代 CMake 学习（5）"
date = "2025-07-04T15:36:39+08:00"
description = ""
tags = ["CMake","C++","C"]
categories = ["编程","教程"]
series = []
aliases = []
image = ""
draft = false
+++

# 现代 CMake 学习（5）：安装与打包 (install & CPack)

在本节中，我们将学习如何使用 CMake 的安装功能和 CPack 进行打包。安装功能允许我们将构建的目标文件、头文件和其他资源安装到指定的目录中，而 CPack 则用于创建可分发的安装包。

## 从 install 开始

我们从一个简单的 CMake 项目开始，假设我们有一个动态库 `mylib`

```cmake
cmake_minimum_required(VERSION 3.25)

project(cmake_pack_and_install VERSION 1.0.0 LANGUAGES CXX)

# 构建动态库
add_library(mylib SHARED
    src/mylib.cpp
)
target_include_directories(mylib
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

install(TARGETS mylib
    EXPORT mylib-targets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)
install(DIRECTORY include/ DESTINATION include)
```

```txt
.
├── CMakeLists.txt
├── include
│   └── mylib.h
└── src
    └── mylib.cpp
```

> 下面两个代码片段是 `include/mylib.h` 和 `src/mylib.cpp` 的内容，对于 CMake 的安装和打包功能，我们不需要修改这两个文件，后面不再提及。

```cpp
// File: include/mylib.h
#pragma once
#include <cstdint>

#ifdef __cplusplus
extern "C"
{
#endif

    int32_t mylib_add(int32_t a, int32_t b);
    int32_t mylib_subtract(int32_t a, int32_t b);
    int32_t mylib_multiply(int32_t a, int32_t b);
    int32_t mylib_divide(int32_t a, int32_t b);

#ifdef __cplusplus
}
#endif

```

```cpp
// File: src/mylib.cpp

#include "mylib.h"
#include <cstdint>

extern "C"
{

    int32_t mylib_add(int32_t a, int32_t b)
    {
        return a + b;
    }
    int32_t mylib_subtract(int32_t a, int32_t b)
    {
        return a - b;
    }
    int32_t mylib_multiply(int32_t a, int32_t b)
    {
        return a * b;
    }
    int32_t mylib_divide(int32_t a, int32_t b)
    {
        return b ? a / b : 0;
    }
}
```

> 使用 vscode 的 cmake 插件，配置 `CMakeLists.txt` 实际执行的命令

```bash
[proc] 执行命令: C:\Users\yeisme\scoop\shims\cmake.EXE -DCMAKE_TOOLCHAIN_FILE:STRING=C:/Users/yeisme/lib/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE -DCMAKE_C_COMPILER:FILEPATH=C:\Users\yeisme\scoop\apps\llvm\current\bin\clang.exe -DCMAKE_CXX_COMPILER:FILEPATH=C:\Users\yeisme\scoop\apps\llvm\current\bin\clang++.exe --no-warn-unused-cli -SC:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install -Bc:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/build -G "Ninja Multi-Config"
```

当我们运行 `cmake --build build --target all --config release` 时，CMake 会构建我们的动态库 `mylib`。接下来，我们可以使用 `cmake --install build --prefix install` 命令将构建的目标文件和头文件安装到指定的目录中 (当前目录的 install/)。

```bash
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install> cmake --build build --target all --config release
[2/2] Linking CXX shared library Release\mylib.dll
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install> cmake --install build --prefix install
-- Install configuration: "Release"
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/lib/mylib.lib
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/bin/mylib.dll
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/include
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/include/mylib.h
```

目前这个 cmake 项目导出 C api，同时安装了动态库和头文件到 `install/` 目录下，对于 C++ 项目来说，这个安装目录结构是比较常见的，但是对于现代 CMake 项目来说，这还不够，我们进行改进。

> 当前的安装目录结构如下：

```bash
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install> cd .\install\
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install\install> eza --tree
.
├── bin
│   └── mylib.dll
├── include
│   └── mylib.h
└── lib
    └── mylib.lib
```

## 更规范的 CMake 安装目录结构

在现代 CMake 项目中，我们通常会使用更规范的安装目录结构，以便于其他项目能够更容易地找到和使用我们的库。我们可以通过以下方式改进我们的 `CMakeLists.txt` 文件：

```cmake
# 在以上的 CMakeLists.txt 文件中添加以下内容
# 配置包文件
include(CMakePackageConfigHelpers)

# 安装导出目标
install(EXPORT mylib-targets
    FILE mylibTargets.cmake
    NAMESPACE mylib::
    DESTINATION lib/cmake/mylib
)

# 生成配置文件
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/mylibConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/mylibConfig.cmake
    INSTALL_DESTINATION lib/cmake/mylib
)

# 生成版本文件
write_basic_package_version_file(
    mylibConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

# 安装配置文件
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/mylibConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/mylibConfigVersion.cmake
    DESTINATION lib/cmake/mylib
)

```

我们编写一个 `mylibConfig.cmake.in` 文件，用于生成配置文件：

```cmake
# File: mylibConfig.cmake.in
@PACKAGE_INIT@
include("${CMAKE_CURRENT_LIST_DIR}/mylibTargets.cmake")
```

```bash
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install> cmake --build build --target all --config release
[2/2] Linking CXX shared library Release\mylib.dll
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install> cmake --install build --prefix install
-- Install configuration: "Release"
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/lib/mylib.lib
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/bin/mylib.dll
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/include
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/include/mylib.h
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/lib/cmake/mylib/mylibTargets.cmake
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/lib/cmake/mylib/mylibTargets-release.cmake
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/lib/cmake/mylib/mylibConfig.cmake
-- Installing: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/lib/cmake/mylib/mylibConfigVersion.cmake
```

```txt
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install\install> eza --tree
.
├── bin
│   └── mylib.dll
├── include
│   └── mylib.h
└── lib
    ├── cmake
    │   └── mylib
    │       ├── mylibConfig.cmake
    │       ├── mylibConfigVersion.cmake
    │       ├── mylibTargets-release.cmake
    │       └── mylibTargets.cmake
    └── mylib.lib
```

我们编写一个 `example/main.cpp` 和 `example/CMakeLists.txt` 文件来测试安装的库：

```cpp
// File: example/main.cpp
#include "mylib.h"
#include <iostream>

int main()
{
    int a = 10, b = 5;
    std::cout << "a = " << a << ", b = " << b << std::endl;
    std::cout << "a + b = " << mylib_add(a, b) << std::endl;
    std::cout << "a - b = " << mylib_subtract(a, b) << std::endl;
    std::cout << "a * b = " << mylib_multiply(a, b) << std::endl;
    try
    {
        std::cout << "a / b = " << mylib_divide(a, b) << std::endl;
    }
    catch (...)
    {
        std::cout << "Divide by zero error!" << std::endl;
    }
    return 0;
}

```

```cmake
# exmpale/CMakeLists.txt
cmake_minimum_required(VERSION 3.25)

project(cmake_pack_and_install_example VERSION 1.0.0 LANGUAGES CXX)

option(BUILD_EXAMPLES "Build examples" OFF)

if(BUILD_EXAMPLES)
    set(CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../install")
    find_package(mylib CONFIG REQUIRED)

    add_executable(use_lib main.cpp)
    target_link_libraries(use_lib PRIVATE mylib::mylib)
    target_include_directories(use_lib PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../include)
endif()

```

```bash
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install\example> cmake -B build -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DBUILD_EXAMPLES=ON
-- Configuring done (1.0s)
-- Generating done (0.3s)
-- Build files have been written to: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/example/build
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install\example> cmake --build build --target all --config release
[2/2] Linking CXX executable use_lib.exe
FAILED: use_lib.exe
C:\WINDOWS\system32\cmd.exe /C "cd . && C:\Users\yeisme\scoop\apps\llvm\current\bin\clang++.exe -nostartfiles -nostdlib -O0 -D_DEBUG -D_DLL -D_MT -Xclang --dependent-lib=msvcrtd -g -Xclang -gcodeview -Xlinker /subsystem:console  -fuse-ld=lld-link CMakeFiles/use_lib.dir/main.cpp.obj -o use_lib.exe -Xlinker /MANIFEST:EMBED -Xlinker /implib:use_lib.lib -Xlinker /pdb:use_lib.pdb -Xlinker /version:0.0   C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/install/lib/mylib.lib  -lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32 -loldnames  && cd ."
lld-link: error: undefined symbol: mylib_add
>>> referenced by C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install\example\main.cpp:9
>>>               CMakeFiles/use_lib.dir/main.cpp.obj:(main)

lld-link: error: undefined symbol: mylib_subtract
>>> referenced by C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install\example\main.cpp:10
>>>               CMakeFiles/use_lib.dir/main.cpp.obj:(main)

lld-link: error: undefined symbol: mylib_multiply
>>> referenced by C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install\example\main.cpp:11
>>>               CMakeFiles/use_lib.dir/main.cpp.obj:(main)

lld-link: error: undefined symbol: mylib_divide
>>> referenced by C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install\example\main.cpp:14
>>>               CMakeFiles/use_lib.dir/main.cpp.obj:(main)
clang++: error: linker command failed with exit code 1 (use -v to see invocation)
ninja: build stopped: subcommand failed.
```

显然，我们发现了一个问题：在 `example` 目录下编译时，链接器无法找到 `mylib` 的符号。这不是因为我们没有正确设置 `CMAKE_PREFIX_PATH`，导致 CMake 没有找到安装的库。

这个错误意味着，在构建 use_lib.exe 这个可执行文件时，链接器虽然找到了 mylib.lib 这个库，但无法在其中找到 mylib_add, mylib_subtract 等函数的具体实现。

### 根本原因：缺少导出/导入声明 DLL Export/Import

在 Windows 平台上，当你创建一个动态链接库（DLL，也就是你代码中的 `SHARED` 库）时，默认情况下，库中的函数是**不**对外暴露的。你必须明确地告诉编译器：

1. **在构建 DLL 时**：哪些函数需要被**导出**（export），以便其他程序可以使用。
2. **在使用 DLL 时**：哪些函数需要从外部 DLL **导入**（import）。

这个声明是通过 `__declspec(dllexport)` 和 `__declspec(dllimport)` 这两个关键字来完成的。你提供的 `mylib.h` 头文件中缺少了这些声明。

尽管我们使用了 `extern "C"`，这能够解决 C++ 的名称修饰（name mangling）问题，确保函数名在编译后保持原样（例如 `mylib_add`），但它并不能解决 DLL 的函数导出问题。

这并不是 Windows 或者 cmake 的 bug，而且不同操作系统的动态库处理方式不同，Linux 和 macOS 等平台通常不需要这种导出/导入声明。

虽然 Linux 默认全部公开，但这并不一定是好事。如果你的库非常复杂，有很多内部使用的辅助函数，将它们全部公开会：

1. **污染命名空间**：可能会和用户程序或其他库中的函数名冲突(这非常常见，我上周尝试编译 tdesktop 就遇到到了)。
2. **暴露内部实现**：用户可能会错误地依赖你的内部函数，一旦你将来修改或删除了这些函数，就会破坏用户的代码。
3. **可能影响性能**：过大的符号表会稍微增加库的加载时间和内存占用。

因此，Linux 上的**最佳实践**恰恰和 Windows 的默认行为一样：**默认隐藏所有符号，只选择性地公开公共 API**。

这可以通过给编译器传递 `-fvisibility=hidden` 标志来实现。

### 解决方案：添加导出/导入声明

1. 在 `mylib.h` 中添加导出/导入声明 `__declspec(dllexport)` 和 `__declspec(dllimport)`
2. 在 `CMakeLists.txt` 中设置目标属性 `set_target_properties(mylib PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS TRUE)`
3. 使用 `GenerateExportHeader` 模块自动处理导出/导入声明

```cmake
# 1. 包含此模块以使用其功能
include(GenerateExportHeader)

# 2. 为 mylib 目标生成导出头文件 (mylib_export.h) 及 MYLIB_API 宏
#    BASE_NAME 用于指定宏和文件名的基础（可选，默认是目标名）
#    EXPORT_FILE_NAME 用于指定生成的头文件名（可选）
generate_export_header(mylib)
```

> TODO: 这部分目前我也没有完全理解，后续会继续学习。 2025-07-04

## CPack 的作用

`cmake --install` 命令非常有用，它将我们的项目构建产物（库、可执行文件、头文件等）整齐地收集到了一个指定的目录（比如我们例子中的 `install/`）。这个目录结构清晰，可以直接被其他项目使用，或者作为“绿色版”软件分发。

但是，如果我们想将我们的软件分发给**最终用户**呢？直接把 `install` 目录压缩成一个 `.zip` 或 `.tar.gz` 文件然后发给他们？这种方式存在一些显而易见的缺点：

1. 用户需要手动解压文件，并且自己决定应该把这些文件放在系统的哪个位置。如果软件需要配置环境变量（如 `PATH`），用户也必须手动完成。
2. Windows 用户习惯于使用图形化的 `.exe` 安装向导，它可以引导用户完成安装、创建开始菜单快捷方式、并在“控制面板”中留下卸载信息。Linux 用户则更倾向于使用包管理器（如 `apt`, `yum`）来安装 `.deb` 或 `.rpm` 包，以便于管理和更新。macOS 用户则熟悉 `.dmg` 磁盘映像文件。一个简单的压缩包无法满足这些平台原生的体验。
3. 压缩包本身无法携带版本号、开发者信息、项目主页、许可证等元数据。这些信息对于软件的发布和管理至关重要。
4. 相比于一个正式的安装程序，一个简单的压缩包会显得不够专业和可信。

**CPack** 就是为了解决上述所有问题而生的。它是 CMake 套件中专门用于打包的工具。

**`install` 命令和 CPack 的关系是：`install` 定义了“要安装什么内容”，而 CPack 则负责将这些内容打包成一个“对用户友好的、平台原生的”分发包。**

在原来的 `CMakeLists.txt` 中添加以下内容来启用 CPack：

```cmake
include(cmake/pack.cmake)

```

```cmake
# File: cmake/pack.cmake
include(InstallRequiredSystemLibraries)

set(CPACK_PACKAGE_NAME "cmake_pack_and_install")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_CONTACT "your_email@example.com")
set(CPACK_PACKAGE_VENDOR "your_vendor")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "A demo C++ library with CMake packaging")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE" CACHE FILEPATH "License file")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md" CACHE FILEPATH "Readme file")

set(CPACK_GENERATOR "ZIP;TGZ")
set(CPACK_SOURCE_GENERATOR "ZIP;TGZ")

set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_NAME}")

# 安装路径
set(CPACK_PACKAGING_INSTALL_PREFIX ".")

# 包含 CPack
include(CPack)

```

```bash
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install> cmake -B build -G Ninja -DCMAKE_CXX_COMPILER=clang++ -DBUILD_EXAMPLES=ON
-- The CXX compiler identification is Clang 20.1.5 with GNU-like command-line
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: C:/Users/yeisme/scoop/apps/llvm/current/bin/clang++.exe - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Configuring done (11.3s)
-- Generating done (0.3s)
-- Build files have been written to: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/build
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install> 
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install> cmake --build build --target all --config release
[4/4] Linking CXX executable example\use_lib.exe
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install> cd .\build\
PS C:\Users\yeisme\code\cli_dev\learn_project\cmake_pack_and_install\build> cpack -G "INNOSETUP"                                                     
CPack: Create package using INNOSETUP
CPack: Install projects
CPack: - Install project: cmake_pack_and_install []
CPack: Create package
CPack: - package: C:/Users/yeisme/code/cli_dev/learn_project/cmake_pack_and_install/build/cmake_pack_and_install-1.0.0-Windows.exe generated.
```

最后生成了 `build/cmake_pack_and_install-1.0.0-Windows.exe`

{{< figure src="image.png" alt="cmake_5" >}}
