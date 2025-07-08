+++
title = "现代 CMake 学习（6）：CMake Toolchain"
date = "2025-07-08T17:38:17+08:00"
description = ""
tags = ["CMake","C++","C"]
categories = ["编程","教程"]
series = []
aliases = []
image = ""
draft = false
+++

# 现代 CMake 学习（6）：CMake Toolchain

## 前言

回顾一下 C/C++ 的编译过程，源代码经过预处理、编译、汇编和链接四个阶段，最终生成可执行文件。

在软件开发中，“工具链” (Toolchain) 是指用于构建和编译软件的一整套工具的集合。它通常至少包含以下几个部分：

- **编译器 (Compiler)：** 如 GCC 或 Clang，负责将 C、C++ 等源代码文件转换成机器码（目标文件 `.o`）。
- **链接器 (Linker)：** 如 `ld` `link` `llvm-link`，负责将多个目标文件和库文件链接在一起，生成最终的可执行文件或共享库。
- **标准库 (Standard Library)：** 如 `libc` (C 标准库) 和 `libstdc++` (C++ 标准库)，提供了程序运行所需的基本函数。
- **调试器 (Debugger)：** 如 GDB 或 LLDB，用于调试程序。

当你在一台机器上为这台机器本身编译软件时（例如，在 x86 架构的 Windows 电脑上为 Windows x86 编译程序），这个过程叫做**本地编译 (Native Compilation)**。CMake 会自动检测你系统上安装的工具链（如 Visual Studio, GCC, Clang）并使用它。

然而，当你在一种系统（宿主机，Host）上为另一种不同的系统（目标机，Target）编译软件时，这个过程叫做**交叉编译 (Cross-Compilation)**。

**交叉编译的典型场景：**

- 在 Windows/Linux (x86) 电脑上，为嵌入式 ARM Linux 设备（如树莓派、路由器）编译程序。
- 在 macOS (ARM64) 电脑上，为 Android (ARM64/ARMv7) 手机编译原生库。
- 在 Linux (x86_64) 电脑上，为 Windows (x86_64) 编译可执行文件。

这时，你就不能使用宿主机的本地工具链了，因为它们生成的是宿主机架构的机器码。你需要一套能够生成目标机架构机器码的**交叉编译工具链**。

## CMake Toolchain 文件

CMake 可以通过一个特殊的**工具链文件 (Toolchain File)** 来管理和配置交叉编译。这个文件本质上是一个 CMake 脚本（通常以 `.cmake` 结尾），它的核心作用是**告诉 CMake 关于目标系统的所有信息以及如何使用正确的交叉编译工具**。

当你使用 `cmake` 命令生成构建系统时，通过 `-DCMAKE_TOOLCHAIN_FILE=<path-to-file.cmake>` 参数指定这个文件，CMake 就会进入交叉编译模式，并加载你在该文件中定义的所有设置。

实际上 `cmake toolchain` 文件的内容就是一系列的 CMake 变量设置，这些变量会影响到编译器、链接器、库路径、操作系统信息等。这些变量包括但不限于：

- **系统信息:**
  - `CMAKE_SYSTEM_NAME`：目标系统的名称（如 `Linux`, `Windows`, `Android`）。一旦设置此变量，CMake 就认定正在进行交叉编译。
  - `CMAKE_SYSTEM_PROCESSOR`：目标系统的处理器架构（如 `x86_64`, `arm`, `aarch64`）。
  - `CMAKE_SYSTEM_VERSION`：目标系统的版本。
- **编译器与工具:**
  - `CMAKE_C_COMPILER` / `CMAKE_CXX_COMPILER`：指定 C 和 C++ 编译器的路径或名称。
  - `CMAKE_AR` / `CMAKE_RANLIB` / `CMAKE_STRIP`：指定其他 binutils 工具。
- **编译与链接标志:**
  - `CMAKE_C_FLAGS` / `CMAKE_CXX_FLAGS`：为所有构建类型（Debug, Release 等）设置的 C/C++ 编译选项。
  - `CMAKE_EXE_LINKER_FLAGS`：链接器的选项。
- **查找路径:**
  - `CMAKE_SYSROOT`：指定目标系统的“系统根目录”，编译器将在此目录下查找头文件和库。
  - `CMAKE_FIND_ROOT_PATH`：一个路径列表，CMake 的 `find_*` 命令（如 `find_package`, `find_library`）会优先在这些路径下为目标系统查找文件。

值得注意的是，toolchain 文件也并不总是用于交叉编译。例如 `vcpkg` 等包管理器通常会提供一个 toolchain 文件来配置 CMake，以便正确地找到和使用其管理的库，从而极大地简化了本地编译的依赖管理。

## CMake Toolchain 文件示例

让我们看一个为树莓派（ARMv7 架构，运行 Linux）进行交叉编译的典型 toolchain 文件：

```cmake
# toolchain-rpi.cmake

# 1. 设置目标系统信息
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# 2. 指定交叉编译工具链的路径
# (假设我们的工具链安装在 /opt/raspberrypi-toolchain)
set(TOOLCHAIN_PREFIX /opt/raspberrypi-toolchain/bin/arm-linux-gnueabihf)

# 3. 指定 C 和 C++ 编译器
set(CMAKE_C_COMPILER   ${TOOLCHAIN_PREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}-g++)

# 4. 设置 Sysroot
# Sysroot 指向目标系统的根文件系统，包含了所有头文件和库文件
set(CMAKE_SYSROOT /opt/raspberrypi-toolchain/arm-linux-gnueabihf/sysroot)

# 5. 配置 find_* 命令的查找行为
# 让 CMake 只在 sysroot 中查找库/头文件，而不是在宿主机系统中查找
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
```

这个例子清晰地展示了 toolchain 文件的核心职责：完整地描述目标环境，并精确地指向所使用的工具。

## 安卓 toolchain 文件

接下来我们来详细解读一下这个安卓 NDK 的 toolchain 文件 (android.toolchain.cmake)。这个文件是官方提供的、用于交叉编译安卓原生代码的“范本”，其设计非常完善和复杂，是学习 toolchain 文件的一个绝佳案例。

这个文件是使用 CMake 为安卓平台进行原生代码（C/C++）交叉编译的核心配置文件。当你通过 CMake 构建安卓项目时，你需要通过 `-DCMAKE_TOOLCHAIN_FILE` 参数指向这个文件。它的主要作用是**配置和初始化**整个编译环境，告诉 CMake 如何找到正确的编译器、链接器、库文件以及如何为目标安卓设备设置正确的编译和链接选项。

可以把这个文件理解为一个“翻译官”，它将 CMake 的通用构建指令“翻译”成安卓 NDK 特有的编译指令。

### 核心作用与初始化

#### **防止重复加载**

```cmake
if(ANDROID_NDK_TOOLCHAIN_INCLUDED)
  return()
endif(ANDROID_NDK_TOOLCHAIN_INCLUDED)
set(ANDROID_NDK_TOOLCHAIN_INCLUDED true)
```

这是一个常见的 CMake 写法，确保该文件的内容在一次 CMake 配置过程中只被执行一次，避免因重复包含而导致的变量重复定义或标志重复添加等问题。

#### **兼容旧版 Toolchain 文件**

```cmake
if(_USE_LEGACY_TOOLCHAIN_FILE)
  include("${CMAKE_CURRENT_LIST_DIR}/android-legacy.toolchain.cmake")
  return()
endif()
```

这部分代码是为了保持向后兼容。早期的 NDK 版本中，`toolchain` 文件的行为有所不同。这里通过 `_USE_LEGACY_TOOLCHAIN_FILE` 变量（默认为 `true`）来决定是使用新的逻辑还是加载旧的 `android-legacy.toolchain.cmake` 文件。这确保了依赖旧行为的项目不会在升级 NDK 后立即构建失败。

### 关键变量配置

这部分是 `toolchain` 文件的核心，它负责解析用户传入或自动检测的配置，并将其转换为 CMake 能理解的设置。这些变量通常可以在调用 CMake 时通过 `-D<VARIABLE_NAME>=<VALUE>` 的方式进行设置。

#### **1. `ANDROID_NDK` - NDK 路径**

```cmake
get_filename_component(ANDROID_NDK_EXPECTED_PATH ...)
if(NOT ANDROID_NDK)
  set(CMAKE_ANDROID_NDK "${ANDROID_NDK_EXPECTED_PATH}")
else()
  # ... 允许用户指定自己的 NDK 路径 ...
  set(CMAKE_ANDROID_NDK ${ANDROID_NDK})
endif()
```

- **作用**: 确定 Android NDK 的安装路径。
- **逻辑**:
  - 它首先会根据 `toolchain` 文件自身的位置推断出 NDK 的根目录 (`${CMAKE_CURRENT_LIST_DIR}/../..`)。
  - 如果用户没有通过 `-DANDROID_NDK=<path>` 显式指定路径，就使用推断出的路径。
  - 如果用户指定了路径，则使用用户提供的路径，并给出一个警告（因为这通常是不常见的用法）。
- **最终设置**: `CMAKE_ANDROID_NDK`

#### **2. `ANDROID_ABI` - 目标 ABI**

```cmake
if(NOT CMAKE_ANDROID_ARCH_ABI)
  if(ANDROID_ABI)
    set(CMAKE_ANDROID_ARCH_ABI ${ANDROID_ABI})
  else()
    # ... 根据其他线索推断 ...
    set(CMAKE_ANDROID_ARCH_ABI armeabi-v7a)
  endif()
endif()
```

- **作用**: 指定要为哪种 CPU 架构和指令集进行编译（Application Binary Interface）。常见的值有 `armeabi-v7a`, `arm64-v8a`, `x86`, `x86_64`。
- **逻辑**:
  - 优先使用用户通过 `-DANDROID_ABI=<value>` 设置的值。
  - 如果未指定，它会尝试从其他旧变量（如 `ANDROID_TOOLCHAIN_NAME`）推断，或者默认设置为 `armeabi-v7a`。
- **最终设置**: `CMAKE_ANDROID_ARCH_ABI`

#### **3. `ANDROID_PLATFORM` - 安卓 API 级别**

```cmake
if(ANDROID_NATIVE_API_LEVEL AND NOT ANDROID_PLATFORM)
  # ...
  set(ANDROID_PLATFORM android-${ANDROID_NATIVE_API_LEVEL})
endif()
include(${CMAKE_ANDROID_NDK}/build/cmake/adjust_api_level.cmake)
adjust_api_level("${ANDROID_PLATFORM}" CMAKE_SYSTEM_VERSION)
```

- **作用**: 指定项目支持的最低安卓 API 级别。这决定了你可以链接和使用的原生 API 的版本。例如，`android-21` 对应 Android 5.0。
- **逻辑**:
  - 它会检查 `ANDROID_PLATFORM` 或 `ANDROID_NATIVE_API_LEVEL` 变量。
  - 之后，会调用 `adjust_api_level.cmake` 脚本来验证和调整 API 级别，确保其对于选定的 ABI 是有效的（例如，64 位 ABI 需要至少 API 21）。
- **最终设置**: `CMAKE_SYSTEM_VERSION`

#### **4. `ANDROID_STL` - C++ 标准库**

```cmake
if(NOT DEFINED CMAKE_ANDROID_STL_TYPE AND DEFINED ANDROID_STL)
  set(CMAKE_ANDROID_STL_TYPE ${ANDROID_STL})
endif()

if("${CMAKE_ANDROID_STL_TYPE}" STREQUAL "gnustl_shared" OR ...)
  message(FATAL_ERROR "${CMAKE_ANDROID_STL_TYPE} is no longer supported...")
endif()
```

- **作用**: 选择要链接的 C++ 标准库实现。
- **逻辑**:
  - 允许用户通过 `-DANDROID_STL=<value>` 来指定。
  - **重要的变更**: 从 NDK r18 开始，`gnustl`, `gabi++`, `stlport` 等旧的 C++ 运行时已被移除。该脚本会明确检查这些已被废弃的库，如果用户尝试使用，将直接报错并提示迁移到 `c++_shared` 或 `c++_static`（即 LLVM 的 libc++）。
- **最终设置**: `CMAKE_ANDROID_STL_TYPE`

### 编译环境与工具链设置

在确定了核心配置后，文件会接着设置具体的编译器、标志等。

#### **设置系统信息和工具链**

```cmake
set(CMAKE_SYSTEM_NAME Android)
set(ANDROID_TOOLCHAIN clang)
# ...
set(ANDROID_TOOLCHAIN_ROOT "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/${ANDROID_HOST_TAG}")
set(CMAKE_SYSROOT "${ANDROID_TOOLCHAIN_ROOT}/sysroot")
```

- **`CMAKE_SYSTEM_NAME`**: 明确告诉 CMake 正在为 `Android` 系统进行交叉编译。这是 CMake 交叉编译机制的核心变量。
- **`ANDROID_TOOLCHAIN`**: 强制使用 `clang`。文件中明确指出 GCC 不再被支持。
- **`ANDROID_TOOLCHAIN_ROOT`**: 根据当前开发机系统（Linux, aacOS, Windows）设置 LLVM/Clang 工具链所在的路径。
- **`CMAKE_SYSROOT`**: 设置 sysroot 路径。**Sysroot 是一个至关重要的概念**，它指向一个目录，其中包含了目标系统的头文件和库文件。编译器和链接器会在此目录下查找所需的原生 API 库（如 `liblog.so`, `libandroid.so` 等）和头文件。

#### **设置编译器和启动器**

```cmake
if(ANDROID_CCACHE)
  set(CMAKE_C_COMPILER_LAUNCHER   "${ANDROID_CCACHE}")
  set(CMAKE_CXX_COMPILER_LAUNCHER "${ANDROID_CCACHE}")
endif()
```

这里支持使用 `ccache` 来缓存编译结果，从而大幅提升重复构建的速度。如果设置了 `ANDROID_CCACHE` 变量，它将被用作编译器启动器。

#### **处理 C++ 特性**

```cmake
if(ANDROID_CPP_FEATURES)
  # ...
  if(${feature} STREQUAL "rtti")
    set(CMAKE_ANDROID_RTTI TRUE)
  endif()
  if(${feature} STREQUAL "exceptions")
    set(CMAKE_ANDROID_EXCEPTIONS TRUE)
  endif()
  # ...
endif()
```

- **作用**: 控制是否启用 RTTI (Run-Time Type Information) 和 C++ 异常。
- **逻辑**: 解析 `ANDROID_CPP_FEATURES` 变量（例如 `-DANDROID_CPP_FEATURES="rtti exceptions"`），并设置对应的 CMake 变量 (`CMAKE_ANDROID_RTTI`, `CMAKE_ANDROID_EXCEPTIONS`)。默认情况下，为了性能和代码大小，这些特性可能是禁用的。

#### **PIE (Position-Independent Executable)**

```cmake
if(NOT DEFINED CMAKE_POSITION_INDEPENDENT_CODE)
  # ...
  set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
endif()
```

- **作用**: 控制是否生成位置无关的可执行文件。
- **逻辑**: 从 Android L (API 21) 开始，系统要求所有的可执行文件都必须是 PIE 的，以增强安全性（利用了 ASLR 技术）。因此，这里默认将 `CMAKE_POSITION_INDEPENDENT_CODE` 设置为 `TRUE`。同时也提供了 `ANDROID_PIE` 变量让用户可以手动关闭它（比如在构建静态可执行文件等特殊场景）。

## 不一定需要 toolchain 文件

## 使用 mingw-w64 交叉编译 Windows x64 应用

- 安装 mingw-w64 工具链：

```bash
sudo apt install mingw-w64
```

```cmake
# windows-x64-toolchain.cmake

# 目标系统名称
set(CMAKE_SYSTEM_NAME Windows)

# 指定 C 和 C++ 的交叉编译器
set(CMAKE_C_COMPILER   x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)

# 指定 Windows 资源编译器 (用于处理图标、版本信息等)
set(CMAKE_RC_COMPILER  x86_64-w64-mingw32-windres)

# 设置目标环境（可选，但推荐）
set(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
```

MinGW-w64 的设计理念是 **“自成一体的工具链” (Self-Contained Toolchain)**。当你通过 `apt`、`dnf` 或其他包管理器在 Linux 上安装 MinGW-w64 时，它不仅仅是安装了几个编译器程序（如 `x86_64-w64-mingw32-gcc`），而是创建了一个完整的、专为 Windows 目标服务的目录结构。

我们以在 Ubuntu 上安装 `mingw-w64` 为例，它的文件通常安装在类似这样的路径下：

```
yeisme@yeisme:/usr/x86_64-w64-mingw32$ ls
bin  include  lib
```

## 使用 zig cc 交叉编译

Zig 是一种现代系统编程语言，其附带的工具链 zig cc 将交叉编译的简易性提升到了一个全新的高度。zig cc 本质上是 Clang 的一个封装，但它内置了多种主流平台的标准库和头文件，并极大地简化了目标平台的指定。

Zig 的交叉编译非常简单，因为它不需要像传统的 CMake 工具链文件那样复杂的配置。你只需要指定目标平台和架构即可。

```bash
zig cc -target x86_64-windows-gnu -o my_program.exe my_program.c
```

当然我们也可以使用 CMake 来配置 zig cc 作为交叉编译工具链。下面是一个简单的 CMake toolchain 文件示例：

```cmake
# ./zig-toolchain.cmake
set(CMAKE_C_COMPILER "zig")
set(CMAKE_CXX_COMPILER "zig")

set(CMAKE_C_FLAGS_INIT "cc -target x86_64-windows-gnu")
set(CMAKE_CXX_FLAGS_INIT "c++ -target x86_64-windows-gnu")
```

```bash
cmake -B build -G Ninja -S . -D CMAKE_TOOLCHAIN_FILE=zig-toolchain.cmake
```

## cosmopolitan

Cosmopolitan 是一个旨在让 C/C++ 代码可以在多种平台上无缝运行的项目。它通过将 POSIX API 和 Windows API 统一到一个单一的代码库中，允许开发者编写一次代码，然后编译成适用于 Linux、Windows、macOS 等多个平台的可执行文件。

Cosmopolitan 的核心思想是**“一次编写，到处运行”**，它通过提供一个统一的 API 层来实现这一点。这样，开发者可以使用熟悉的 POSIX 风格的系统调用，同时又能在 Windows 上运行。

这不是虚拟机或容器，而是将代码转换为可以在不同操作系统上运行的二进制文件。

> 链接放这，大家有兴趣了解更多可以访问 [Cosmopolitan GitHub](https://github.com/jart/cosmopolitan)。

## 总结

`CMAKE_TOOLCHAIN_FILE` 是 CMake 的一个变量，用于指定交叉编译所需的工具链文件路径。通过这个文件，开发者可以灵活地配置目标平台的编译器、系统根路径、库路径等信息，从而实现跨平台构建。
在现代 CMake 中，工具链文件的使用变得越来越普遍，尤其是在需要交叉编译的场景下。通过正确配置工具链文件，可以大大简化跨平台开发的复杂性。

在使用 CMake 预设时，工具链文件的配置也可以通过预设来简化。例如，可以在 `CMakePresets.json` 中定义一个预设，指定 `CMAKE_TOOLCHAIN_FILE` 的路径，这样在使用 `cmake --preset <preset-name>` 时就会自动加载相应的工具链文件，极大地简化了命令行参数的复杂性。

```json
{
  "version": 3,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 19,
    "patch": 0
  },
  "configurePresets": [
    {
      "name": "android",
      "hidden": false,
      "generator": "Ninja",
      "toolchainFile": "$env{ANDROID_NDK}/android.toolchain.cmake",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      }
    }
  ]
}
```
