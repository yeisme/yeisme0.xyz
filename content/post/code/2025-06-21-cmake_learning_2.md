+++
title = "现代 CMake 学习（2）"
date = "2025-06-21T13:01:36+08:00"
description = ""
tags = ["CMake","C++","C"]
categories = ["编程","教程"]
series = []
aliases = []
image = ""
draft = false
+++

# 现代 CMake 学习（2）

> 现代 CMake 中最重要的概念就是目标（target），它可以是可执行文件、静态库、动态库、可执行文件等。CMake 中的目标是构建系统的核心，所有的编译和链接操作都是围绕目标进行的。

现代 CMake 教程第二篇，库的链接和管理。

## 引言

在现代 CMake 中，库的链接和管理是一个重要的主题。本文将介绍如何在 CMake 中正确地链接库，包括静态库和动态库的使用，以及如何处理库的依赖关系，在学会如何链接库后，我们还将学习如何使用 CMake 的 `find_*` 命令来查找和使用外部库、工具等简化 CMake 脚本的编写。

## CMake 中的库类型

1. 动态库是指在运行时加载的库，通常以 `.so`（Linux）或 `.dll`（Windows）文件形式存在。动态库的优点是可以在多个程序之间共享，节省内存和磁盘空间，但缺点是可能会引入版本兼容性问题。
2. 静态库是指在编译时链接到程序中的库，通常以 `.a`（Linux）或 `.lib`（Windows）文件形式存在。静态库的优点是可以避免版本兼容性问题，但缺点是每个程序都需要包含一份库的副本，可能会增加内存和磁盘空间的使用。
3. 除了静态库和动态库，CMake 还支持其他类型的库，如接口库（Interface Library）、对象库（Object Library）等。模块库和接口库通常用于提供公共接口，而对象库则用于将多个源文件编译为一个对象文件。

我们先从静态库和动态库的链接开始学习，然后再介绍其他类型的库。

## 静态库的链接

在 CMake 中，链接静态库通常使用 `target_link_libraries` 命令，并指定库的类型为 `STATIC`。静态库通常在编译时被链接到可执行文件中，因此在运行时不需要额外的库文件，需要在编译时提供库的路径和头文件的搜索路径。

### 从源代码创建静态库

我们可以使用 CMake 创建一个静态库，并将其链接到可执行文件中。以下是一个简单的示例：

```cmake
add_library(mylib STATIC
    src/mylib.cpp
    include/mylib.h
)

add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE mylib)
# 设置头文件搜索路径
target_include_directories(myapp PRIVATE include)
```

mylib 是一个目标，表示一个静态库。我们使用 `add_library` 命令创建了一个名为 `mylib` 的静态库，并指定了源文件和头文件的路径。然后，我们使用 `target_link_libraries` 命令将 `mylib` 链接到可执行文件 `myapp` 中。

### 从现有的静态库文件链接

如果你已经有一个静态库文件，可以直接链接它。假设我们有一个名为 `libmylib.a` 的静态库文件，位于 `libs` 目录下，我们可以这样链接：

```cmake
add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE ${CMAKE_SOURCE_DIR}/libs/libmylib.a)
# 设置头文件搜索路径
target_include_directories(myapp PRIVATE ${CMAKE_SOURCE_DIR}/include)
```

> 以 duckdb mingw 静态库为例，假设我们有一个静态库 `libduckdb_static.a`，位于 `./libs/duckdb/static-libs-windows-mingw` 目录下，我们可以这样链接：

```text
Directory: .\libs\duckdb\static-libs-windows-mingw

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            2025/4/7    22:41         171603 duckdb.h
-a---            2025/4/7    23:43         433870 libautocomplete_extension.a
-a---            2025/4/7    23:43       17544664 libcore_functions_extension.a
-a---            2025/4/7    23:43         362816 libduckdb_fastpforlib.a
-a---            2025/4/7    23:43         694676 libduckdb_fmt.a
-a---            2025/4/7    23:43          50436 libduckdb_fsst.a
-a---            2025/4/7    23:43          74334 libduckdb_hyperloglog.a
-a---            2025/4/7    23:43         364052 libduckdb_mbedtls.a
-a---            2025/4/7    23:43         188506 libduckdb_miniz.a
-a---            2025/4/7    23:43         604298 libduckdb_pg_query.a
-a---            2025/4/7    23:43        1159216 libduckdb_re2.a
-a---            2025/4/7    23:43          10462 libduckdb_skiplistlib.a
-a---            2025/4/7    23:43       67899422 libduckdb_static.a
-a---            2025/4/7    23:43         395732 libduckdb_utf8proc.a
-a---            2025/4/7    23:43         283810 libduckdb_yyjson.a
-a---            2025/4/7    23:43        1451936 libduckdb_zstd.a
-a---            2025/4/7    23:43       17118394 libicu_extension.a
-a---            2025/4/7    23:43        3380248 libjson_extension.a
-a---            2025/4/7    23:43        7767436 libparquet_extension.a
-a---            2025/4/7    23:43        2823356 libtpcds_extension.a
-a---            2025/4/7    23:43        1305964 libtpch_extension.a
```

如果我们要链接 `libduckdb_static.a` 静态库，可以这样写：

```cmake
add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE ${CMAKE_SOURCE_DIR}/libs/duckdb/static-libs-windows-mingw/libduckdb_static.a)
# 设置头文件搜索路径
target_include_directories(myapp PRIVATE ${CMAKE_SOURCE_DIR}/libs/duckdb/static-libs-windows-mingw)
```

这里的 myapp 也是一个目标，表示一个可执行文件。我们使用 `target_link_libraries` 命令将 `libduckdb_static.a` 静态库链接到可执行文件 `myapp` 中，并使用 `target_include_directories` 命令设置头文件的搜索路径。

> [!TIP]
> 实际上，除了 `target_link_libraries` 命令外，CMake 还提供了 `link_directories` 命令来设置链接目录，`link_directories` 命令在现代 CMake 中已经不推荐使用，建议使用 `target_link_libraries` 和 `target_include_directories` 来指定每个目标的链接库和头文件搜索路径。

### 动态库的链接

动态库（在 Windows 上是 .dll，Linux 上是 .so，macOS 上是 .dylib）与静态库的主要区别在于它是在程序运行时才被加载的，而不是在编译时完全嵌入到可执行文件中。这带来了几个好处：

1. 共享与节约：多个应用程序可以共享同一个动态库的单一副本，节省磁盘和内存空间。
2. 独立更新：只要接口保持兼容，你可以更新动态库而无需重新编译所有使用它的应用程序。

在 CMake 中，链接动态库的方式与静态库类似，但通常不需要指定库的类型为 `SHARED`，因为 CMake 会自动识别动态库。

```cmake
add_library(mydynamiclib SHARED
    src/mydynamiclib.cpp
    include/mydynamiclib.h
)

add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE mydynamiclib)
# 设置头文件搜索路径
target_include_directories(myapp PRIVATE include)
```

上面是一个简单的示例，创建了一个名为 `mydynamiclib` 的动态库，并将其链接到可执行文件 `myapp` 中。CMake 会自动处理动态库的编译和链接。

在实际开发中，通常需要使用三方库或系统库，这些库可能已经以动态库的形式存在。我们可以使用 `find_package` 命令来查找和使用这些库，我们还是以 OpenCV 为例，假设我们要使用 OpenCV 的动态库，可以这样写：

```cmake
find_package(OpenCV REQUIRED)
add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE ${OpenCV_LIBS})
# 设置头文件搜索路径
target_include_directories(myapp PRIVATE ${OpenCV_INCLUDE_DIRS})
```

在这个例子中，`find_package(OpenCV REQUIRED)` 会查找 OpenCV 的安装路径，并寻找 OpenCVConfig.cmake 和 OpenCVConfig-version.cmake 文件，通常在 OpenCVConfig.cmake 中会定义 OpenCV 的库和头文件路径。`OpenCV_LIBS` 和 `OpenCV_INCLUDE_DIRS` 是在 `OpenCVConfig.cmake` 中定义的变量，分别表示 OpenCV 的库文件和头文件的搜索路径。

`find_package` 命令是 CMake 中非常强大的功能，它可以自动处理库的查找和配置，简化了 CMakeLists.txt 的编写，但是需要注意的是，使用 `find_package` 命令时，需要确保库已经正确安装，并且设置 `CMAKE_PREFIX_PATH` 环境变量或 `CMAKE_MODULE_PATH` 变量，以便 CMake 能够找到库的配置文件。

## 其他类型的库

除了静态库和动态库，CMake 还支持其他类型的库，如接口库（Interface Library）、对象库（Object Library）等。接口库用于定义库的公共接口，而对象库则用于将多个源文件编译为一个对象文件。

### 接口库

我现在提个需求展示接口库的使用场景，假设我们有一个好多个动态库和静态库需要链接到多个可执行文件中，我们可以使用接口库来管理这些库的链接和头文件搜索路径。

例如 m_app1 和 m_app2 两个可执行文件都需要链接到 duckdb、OpenCV 动态库和静态库，我们尚且可以每一个 m_app[1,2...] 都写一份 CMakeLists.txt 文件来链接这些库，但是如果有多个可执行文件需要链接同样的库，这样就会导致代码重复，难以维护。

我们可以创建一个接口库来管理这些库的链接和头文件搜索路径，然后在每个可执行文件的 CMakeLists.txt 中引用这个接口库，这样我们的每个目标（这里为可执行文件）就可以共享同样的库配置。

```cmake
cmake_minimum_required(VERSION 3.16)
project(MyProject)

find_package(OpenCV REQUIRED)

# 创建接口库
add_library(my_interface INTERFACE)
# 设置头文件搜索路径
target_include_directories(my_interface INTERFACE
    ${CMAKE_SOURCE_DIR}/libs/duckdb/static-libs-windows-mingw
    ${OpenCV_INCLUDE_DIRS}
    # 如果有其他公共头文件目录
    ${CMAKE_SOURCE_DIR}/common/include
)

# 链接库
target_link_libraries(my_interface INTERFACE
    ${CMAKE_SOURCE_DIR}/libs/duckdb/static-libs-windows-mingw/libduckdb_static.a
    ${OpenCV_LIBS}
)

# 创建可执行文件
add_executable(m_app1 main1.cpp)
add_executable(m_app2 main2.cpp)
# 引用接口库
target_link_libraries(m_app1 PRIVATE my_interface)
target_link_libraries(m_app2 PRIVATE my_interface)
```

### 对象库

对象库（Object Library）是 CMake 对象库（Object Library）是 CMake 中的一种特殊类型的库，它允许你将多个源文件编译为对象文件（.o 或 .obj），而不是生成一个完整的静态库或动态库。对象库的主要优势是可以避免重复编译相同的源文件，提高构建效率，同时避免了创建中间库文件的开销。

在 CMake 3.12 及更高版本中，对象库可以像普通库一样直接链接：

```cmake
# 创建对象库
add_library(CommonObjects OBJECT
    src/database_utils.cpp
    src/string_utils.cpp
    src/file_utils.cpp
    src/logging.cpp
)

# 设置对象库的属性
target_include_directories(CommonObjects
    PUBLIC include          # 使用对象库的目标也能访问这些头文件
    PRIVATE src/internal    # 仅对象库内部使用
)

# 现代方式：直接链接对象库
add_executable(m_app1 main1.cpp app1_specific.cpp)
add_executable(m_app2 main2.cpp app2_specific.cpp)

target_link_libraries(m_app1 PRIVATE CommonObjects)
target_link_libraries(m_app2 PRIVATE CommonObjects)

# 对象库也可以被其他库使用
add_library(MyStaticLib STATIC
    src/static_lib_specific.cpp
)
target_link_libraries(MyStaticLib PRIVATE CommonObjects)
```

## `find_package` 命令

`find_package` 是现代 CMake 中查找和使用外部依赖的主要方式。它可以工作在两种模式下：

### Module 模式

CMake 查找 `Find<PackageName>.cmake` 文件：

```cmake
# CMake 会查找 FindOpenCV.cmake
find_package(OpenCV REQUIRED)

# 使用找到的变量（取决于 Find 模块的定义）
target_include_directories(myapp PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(myapp PRIVATE ${OpenCV_LIBS})
```

### Config 模式（推荐）

CMake 查找 `<PackageName>Config.cmake` 或 `<package-name>-config.cmake` 文件：

```cmake
# CMake 查找 OpenCVConfig.cmake
find_package(OpenCV REQUIRED CONFIG)

# 使用现代目标（推荐）
target_link_libraries(myapp PRIVATE OpenCV::opencv_core OpenCV::opencv_imgproc)
```

### 自定义查找路径

```cmake
# 设置查找路径
list(APPEND CMAKE_PREFIX_PATH "/custom/install/path")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")

find_package(MyCustomLib REQUIRED)
```

我的个人建议是，尽量使用 `find_package` 命令来查找和使用外部库，并且通过 cmake -DCMAKE_PREFIX_PATH=... 命令或者 cmake 预设来设置 `CMAKE_PREFIX_PATH` 变量设置来寻找库，这样可以确保 CMake 能够正确找到库的配置文件，尽量避免直接将库文件路径硬编码到 CMakeLists.txt 中(除非查找路径为当前项目的相对路径)，这样可以提高代码的可移植性和可维护性，同时避免将库文件路径添加的环境变量中，避免多个项目之间的冲突（依赖同一个库不同版本等问题）。

## 依赖管理进阶技巧

### 1. 条件依赖

```cmake
option(ENABLE_FEATURE_X "Enable feature X" ON)

if(ENABLE_FEATURE_X)
    find_package(FeatureXLib REQUIRED)
    target_link_libraries(myapp PRIVATE FeatureXLib::FeatureXLib)
    target_compile_definitions(myapp PRIVATE FEATURE_X_ENABLED)
endif()
```

### 2. 可选依赖

```cmake
find_package(OptionalLib QUIET)
if(OptionalLib_FOUND)
    target_link_libraries(myapp PRIVATE OptionalLib::OptionalLib)
    target_compile_definitions(myapp PRIVATE HAS_OPTIONAL_LIB)
    message(STATUS "Found OptionalLib, enabling enhanced features")
else()
    message(STATUS "OptionalLib not found, using basic functionality")
endif()
```

### 3. 版本控制

```cmake
# 指定最小版本
find_package(Boost 1.70 REQUIRED COMPONENTS system filesystem)

# 指定版本范围（CMake 3.19+）
find_package(SomeLib 2.0...3.0 REQUIRED)

# 精确版本
find_package(ExactLib 1.2.3 EXACT REQUIRED)
```
