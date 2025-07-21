+++
title = "现代 CMake 学习（7）：现代 CMake 语言特性与最佳实践"
date = "2025-07-12T22:32:13+08:00"
description = ""
tags = ["CMake","C++","C"]
categories = ["编程","教程"]
series = []
aliases = []
image = ""
draft = false
+++

# 现代 CMake 学习（7）：现代 CMake 语言特性与最佳实践

## 前言

在前面的章节中，我们已经介绍了现代 CMake 的基本概念和常用功能。本章将深入探讨现代 CMake 的语言特性和最佳实践，帮助你编写更清晰、更高效的 CMake 脚本。

本章目标：提升读者的 CMake "代码品味"，写出更简洁、更灵活、更易于维护的 CMakeLists.txt

## 生成器表达式 (Generator Expressions)

这一小节我们将介绍生成器表达式（Generator Expressions），它们是 CMake 中非常强大的特性，可以在配置阶段动态生成内容。我们可以回想一下，如果你开发的项目，需要跨平台支持不同的操作系统，同时可能需要支持多种编译器，还可能需要支持多个版本的编译器、不同版本的库依赖、不同的条件来选择不同的源文件或编译选项，在不使用生成器表达式的情况下，你可能会写出冗长的条件判断代码(IF, OPTION)，这样不仅难以维护，而且不够灵活。

生成器表达式以 `$<...>` 的形式出现，允许你在 CMakeLists.txt 中根据不同的条件生成不同的内容。在现代 CMake 中，生成器表达式被广泛用于条件编译、目标属性设置等场景。

我们通过一个简单的例子来演示生成器表达式的用法，我们先创建一个静态库 `os_lib`，它根据不同的操作系统选择不同的源文件。

```txt
.
├── CMakeLists.txt
├── include
│   └── lib.h
└── src
    ├── linux_lib.cpp
    ├── main.cpp
    └── windows_lib.cpp
```

```cmake
# Add the OS-specific library
set(OS_LIB_SRC)

if(WIN32)
    set(OS_LIB_SRC src/windows_lib.cpp)
elseif(UNIX)
    set(OS_LIB_SRC src/linux_lib.cpp)
endif()

add_library(os_lib STATIC ${OS_LIB_SRC})
target_compile_definitions(
    os_lib PUBLIC
    COMPILER_ID="${CMAKE_CXX_COMPILER_ID}"
    COMPILER_VERSION="${CMAKE_CXX_COMPILER_VERSION}"
)
target_compile_features(os_lib PUBLIC cxx_std_23)

target_include_directories(os_lib PUBLIC include)

```

os_lib 库根据操作系统选择不同的源文件。windows_lib.cpp 和 linux_lib.cpp 中可以包含一些特定于操作系统的实现，同时他们都包含了公共的头文件 lib.h(对外暴露相同的接口)。

这样，当我们在 Windows 上编译时，os_lib 库将使用 windows_lib.cpp，而在 Linux 上编译时，将使用 linux_lib.cpp。当我们添加一个可执行文件时，我们可以链接这个库：

```cmake
# Add the executable
add_executable(MyExecutable src/main.cpp)

target_link_libraries(MyExecutable os_lib)

target_compile_features(MyExecutable PRIVATE cxx_std_23)

target_compile_options(MyExecutable PRIVATE -Wall -Wextra -pedantic)

```

在这个例子中，我们使用了 `if` 语句来选择源文件，这在小项目中可能还可以接受，但当项目变得复杂时，这种方式会导致 CMakeLists.txt 文件变得冗长且难以维护。同时，在上面的这个项目中，我们通过 `target_compile_options` 为可执行文件添加了一些编译选项，很明显，这些选项在 clang 和 gcc 上是通用的，但在 MSVC 上可能会有不同的选项，更糟糕的是，如果我们系统同时为 release 和 debug 等模式编译，我们可能需要为每个模式都设置不同的编译选项，难道我们需要为每个模式都写一遍 `if` 语句吗？答案是：不需要！我们可以使用生成器表达式来简化这个过程。

我们可以使用生成器表达式来根据不同的条件动态生成内容。下面是使用生成器表达式重写的 CMakeLists.txt：

```cmake
cmake_minimum_required(VERSION 3.30)

project(MyProject)

# Add the OS-specific library
add_library(os_lib STATIC
    $<$<BOOL:${WIN32}>:src/windows_lib.cpp>
    $<$<BOOL:${UNIX}>:src/linux_lib.cpp>
)

target_compile_definitions(
    os_lib PUBLIC
    COMPILER_ID="${CMAKE_CXX_COMPILER_ID}"
    COMPILER_VERSION="${CMAKE_CXX_COMPILER_VERSION}"
)
target_compile_features(os_lib PUBLIC cxx_std_23)

target_include_directories(os_lib PUBLIC include)
```

通过 `$<$<BOOL:${WIN32}>:src/windows_lib.cpp>` 和 `$<$<BOOL:${UNIX}>:src/linux_lib.cpp>`，我们可以根据操作系统选择源文件，而不需要使用 `if` 语句。这样，当我们在不同的操作系统上编译时，CMake 会自动选择正确的源文件。

```cmake
# Add the executable
add_executable(MyExecutable src/main.cpp)

target_link_libraries(MyExecutable os_lib)

target_compile_features(MyExecutable PRIVATE cxx_std_23)

target_compile_options(MyExecutable PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall -Wextra -pedantic>
)

```

在这个版本中，我们使用了生成器表达式来选择源文件和编译选项。`$<$<BOOL:${WIN32}>:src/windows_lib.cpp>` 表示如果 `WIN32` 为真，则使用 `src/windows_lib.cpp`，否则不使用。类似地，`$<$<CXX_COMPILER_ID:MSVC>:/W4>` 表示如果编译器是 MSVC，则使用 `/W4` 编译选项，否则使用 `-Wall -Wextra -pedantic`。

我们继续完善一些这个 demo

```cpp
// include/lib.h
#pragma once

void print_message();

```

```cpp
// src/linux_lib.cpp
#include "lib.h"

#include <print>

static const char *linux_message = "Hello from Linux!";

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

void print_message()
{
    std::print("{} with {} {}\n", linux_message, STR(COMPILER_ID), STR(COMPILER_VERSION));
}

```

```cpp
// src/windows_lib.cpp
#include "lib.h"

#include <print>

static const char *windows_message = "Hello from Windows!";

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

void print_message()
{
    std::print("{} with {} {}\n", windows_message, STR(COMPILER_ID), STR(COMPILER_VERSION));
}

```

当我们在 Windows 上使用 clang 编译并运行时，输出将类似于：

```txt
Hello from Windows! with "Clang" "20.1.5"
```

msvc 编译时输出将类似于：

```
Hello from Windows! with "MSVC" "19.44.35211.0"
```

当我们在 Linux 上使用 gcc 编译并运行时，输出将类似于：

```txt
Hello from Linux! with "GNU" "13.2.0"
```

## 深入 PUBLIC/PRIVATE/INTERFACE：

在现代 CMake 中，`target_link_libraries`, `target_include_directories`, `target_compile_definitions` 等命令都接受 `PUBLIC`, `PRIVATE`, `INTERFACE` 关键字。这三个关键字是现代 CMake 的精髓所在，它们定义了目标（target）属性的**传递性**和**可见性**，是构建模块化、可维护项目的基石。

让我们用一个形象的比喻来理解：将你的库 `libA` 想象成一个产品。

- **`PRIVATE`**: **内部实现细节**。这些是你制造产品时需要的工具和零件（如内部使用的日志库、私有头文件），但客户（使用你库的 `my_app`）完全不需要知道，也不应该接触到。
- **`INTERFACE`**: **用户手册**。这是你提供给客户的、关于如何使用你的产品的所有信息（如公共头文件目录、需要定义的宏）。`INTERFACE` 属性只影响使用者，不影响库本身的构建。这对于头文件库（header-only）尤其重要。
- **`PUBLIC`**: **既是内部零件，也是用户手册的一部分**。这是最常见的情况。例如，`libA.h` 这个头文件，`libA` 自己编译时需要 `include` 它，而 `my_app` 使用 `libA` 时也需要 `include` 它。

通常构建一个库时，我们会使用 `target_include_directories`、`target_compile_definitions` 和 `target_link_libraries` 等命令来设置目标的属性和依赖关系。这时，为了让使用该库的其他目标能够正确地获取这些属性，我们需要指定它们的可见性为 PUBLIC。

通常构建一个可执行文件时，为了避免让其他目标获取到不必要的属性，我们可以将其设置为 PRIVATE。

而 INTERFACE 则用于定义一个纯粹的接口库，它不包含任何实际的源代码，只提供头文件和编译选项供其他目标使用。

当我们设计一个 INTERFACE 库时，我们可以使用 INTERFACE 关键字来设置其属性，这些属性将被传递给所有依赖该库的目标。我们可以将 INTERFACE 库视为一个只包含头文件和编译选项的库，它不需要编译任何源代码，`target_include_directories` 等命令必须使用 INTERFACE 关键字。

```cmake
add_library(my_interface INTERFACE)
target_include_directories(my_interface INTERFACE include)
target_compile_definitions(my_interface INTERFACE MY_INTERFACE_DEFINE)
```

| 关键字    | 对目标自身的影响 | 对使用者的影响 | 典型用例                                                                               |
| --------- | ---------------- | -------------- | -------------------------------------------------------------------------------------- |
| PRIVATE   | 是               | 否             | 内部实现细节：私有头文件、仅用于内部的链接库（如测试框架、日志库）、实现所需的宏定义。 |
| INTERFACE | 否               | 是             | 定义纯接口：头文件库、传递给使用者的编译选项或宏定义、传递依赖关系。                   |
| PUBLIC    | 是               | 是             | 公共 API：定义库公开接口的头文件、使用者也需要链接的库。                               |

## 结论与最佳实践总结

掌握现代 CMake 的语言特性，本质上是从命令式编程思维转向声明式编程思维。你不再是告诉 CMake “一步一步怎么做”，而是向它声明“我的目标需要什么”。

1. **优先使用生成器表达式**：对于任何依赖于平台、编译器、构建配置的逻辑，请用生成器表达式（`$<...>`）代替 `if()` 语句。这会让你的脚本更简洁、更强大，并且能正确处理多配置生成器。
2. **精确使用 `PUBLIC`/`PRIVATE`/`INTERFACE`**：这是现代 CMake 的核心。时刻思考一个问题：“这个属性（头文件、宏、链接库）是我的实现细节（`PRIVATE`），还是需要暴露给用户的接口（`INTERFACE`），或者是两者皆是（`PUBLIC`）？”
3. **目标导向（Target-centric）**：始终围绕目标（`add_library`, `add_executable`）来组织你的命令。使用 `target_*` 系列命令，而不是 `include_directories()`, `link_libraries()` 等修改全局目录的旧命令。
4. **将你的 CMakeLists.txt 视为项目的“API 文档”**：一个写得好的 `CMakeLists.txt`，能清晰地揭示项目内各个模块的依赖关系和公共接口，其本身就是一种项目文档。
