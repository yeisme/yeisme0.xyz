+++
title = "现代 CMake 学习（8）：现代 CMake 生态集成"
date = "2025-07-19T12:08:20+08:00"
description = ""
tags = ["CMake","C++","C"]
categories = ["编程","教程"]
series = []
aliases = []
image = ""
draft = false
+++

# 现代 CMake 学习（8）：现代 CMake 生态集成

## 前言

C++ 的现代 CMake 生态系统已经发展得非常成熟，提供了许多强大的工具和库来简化构建和管理项目的过程。但是对于初学者来说，集成第三方库和工具依然困难，对于很多人来说，开发一个 opencv 项目，如果没有 CSDN 上老前辈的博客，基本上是无法完成的，这显然极大地降低了大家对 C++ 的学习热情。因此，本文将介绍如何在现代 CMake 项目中集成常用的工具和库，以提高开发效率。

在介绍集成方法之前，我们先来了解一下现代 C++ 生态系统的基本组成部分。

## 现代 C++ 生态系统

1. **语言标准**：C++ 标准（C++11, 14, 17, 20, 23...）是生态的基石。
2. **编译器**：GCC, Clang, MSVC 等是标准的实现者。
3. **构建系统**：CMake 是事实上的跨平台构建系统标准。
4. **包管理器**：vcpkg, Conan 等解决了依赖获取和管理的问题。
5. **第三方库**：海量的开源库构成了生态的血肉。
6. **开发工具**：IDE, 调试器, 静态分析器等提升了开发体验。

这几部分相辅相成，共同推动着 C++ 语言的发展。通过 [cppreference 的编译器支持情况](https://en.cppreference.com/w/cpp/compiler_support) 可知，主流编译器对 C++20 的支持已相当完善，对 C++23 的支持也日趋成熟。这意味着开发者可以更大胆地使用现代 C++ 特性。

当我需要一个第三方库时，通常会先在 [Awesome C++](https://github.com/fffaraz/awesome-cpp) 上查找合适的库。找到心仪的库后，下一步就是如何将它无缝地集成到自己的项目中。现代 CMake 提供了多种方式来完成这项工作。

## 方法一：Git 子模块 (Submodules)

Git 子模块是 Git 提供的一种管理依赖库的方式，可以将第三方库作为子模块添加到自己的项目中。这样可以确保项目在不同环境下的一致性，同时也方便了对第三方库的更新和管理。

实际上，社区中有很多优秀的 C++ 项目都使用了 Git 子模块来管理依赖，这也不难理解，因为 Git 子模块可以将外部库的版本锁定在特定的提交上，从而避免因外部库更新而导致的兼容性问题。例如，[Telegram Desktop](https://github.com/telegramdesktop/tdesktop/) 就使用了 Git 子模块来管理依赖库。

```txt
[submodule "Telegram/ThirdParty/GSL"]
	path = Telegram/ThirdParty/GSL
	url = https://github.com/Microsoft/GSL.git
[submodule "Telegram/ThirdParty/xxHash"]
	path = Telegram/ThirdParty/xxHash
	url = https://github.com/Cyan4973/xxHash.git
···
```

在 CMake 中使用子模块，通常的模式是在主项目的 CMakeLists.txt 中使用 add_subdirectory() 命令将子模块的目录添加进来，就好像它是你项目本身的一部分。

```cmake
# 将子模块添加到构建中
# 假设你已经通过 git submodule add <url> external/fmt 将 fmt 添加为子模块
add_subdirectory(external/fmt)

# ...
add_executable(MyApp main.cpp)

# 现在你可以像链接自己的库一样链接它
target_link_libraries(MyApp PRIVATE fmt::fmt)
```

这种方式的重点在于 Git 的使用，具体可以参考官方文档或相关教程，推荐 [菜鸟教程：git submodule 命令](https://www.runoob.com/git/git-submodule.html)。

| 优点                                                                | 缺点                                                                               |
| ------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| 版本锁定精确：依赖版本被父仓库的提交历史严格控制。                  | 学习成本：需要掌握额外的 Git 子模块命令 (submodule update --init --recursive 等)。 |
| 离线友好：git clone --recurse-submodules 后即可在无网络环境下构建。 | 处理嵌套依赖困难：如果子模块还有子模块，管理会变得复杂。                           |
| 对非 CMake 项目友好：可以集成任何类型的 Git 仓库。                  | 不处理构建系统集成：依然需要你手动编写 add_subdirectory 等 CMake 代码。            |

## 方法二：CMake FetchContent 模块

为了让依赖管理在 CMake 层面更加“原生”，CMake 3.11+ 引入了 `FetchContent` 模块。这是一个非常强大的工具，可以在 **CMake 配置阶段 (configure time)** 从远端下载、配置并集成第三方库。

`FetchContent` 的工作流程通常是三步曲：

1.  `FetchContent_Declare`：声明一个依赖项，指定它的 Git 仓库地址和确切的标签或提交哈希。
2.  `FetchContent_MakeAvailable`：这是关键一步，它会检查依赖是否已被获取，如果没有，则下载它，并自动调用 `add_subdirectory()` 将其添加到你的项目中。
3.  `target_link_libraries`：像链接普通子项目一样链接到这个依赖。

让我们以集成著名的格式化库 `{fmt}` 为例：

**`CMakeLists.txt`**

```cmake
cmake_minimum_required(VERSION 3.14)
project(FetchContentExample LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 包含 FetchContent 模块
include(FetchContent)

# 1. 声明 fmt 库
FetchContent_Declare(
  fmt
  GIT_REPOSITORY https://github.com/fmtlib/fmt.git
  GIT_TAG        10.2.1 # 总是锁定到具体的 tag 或 commit hash
)

# 2. 使 fmt 可用（下载并添加到项目中）
FetchContent_MakeAvailable(fmt)

# 创建你自己的可执行文件
add_executable(MyApp src/main.cpp)

# 3. 链接到 fmt 库
# FetchContent_MakeAvailable 会让 fmt 的 target (fmt::fmt) 在我们项目中可见
target_link_libraries(MyApp PRIVATE fmt::fmt)
```

**`src/main.cpp`**

```cpp
#include <fmt/core.h>

int main() {
    fmt::print("Hello from {}\\n", "FetchContent");
    return 0;
}
```

当你运行 `cmake ..` 时，CMake 会自动克隆 `fmt` 仓库的 `10.2.1` 版本到你的构建目录下，并配置好一切。

| 优点                                                                          | 缺点                                                                    |
| :---------------------------------------------------------------------------- | :---------------------------------------------------------------------- |
| **CMake 原生**：无需额外的 Git 命令，整个过程由 CMake 控制，CICD 集成更简单。 | **配置阶段下载**：每次清理配置重新生成时都需要下载，拖慢配置速度。      |
| **语法简洁**：三步曲模式清晰易懂。                                            | **污染构建目录**：源码和构建产物都下载到 `_deps` 目录中，显得有些杂乱。 |
| **自动处理嵌套依赖**：如果依赖本身也使用 `FetchContent`，可以很好地协同工作。 | **无二进制缓存**：每次都会从源码编译，无法利用预编译好的二进制文件。    |

> 优缺点分析感觉不明显，实际上我最不能接受的是每次都要从源码编译，无法利用预编译好的二进制文件，这意味着每次都要花费时间去编译依赖库，尤其是大型库如 Boost 或 OpenCV，这会显著拖慢构建速度。

## 方法三：包管理器 (Package Managers) - 现代化的黄金标准

对于中大型项目或任何需要处理复杂、多层级依赖的项目来说，**包管理器是当之无愧的最佳实践**。它们将依赖管理提升到了一个新的层次，解决了源码编译慢、依赖冲突和平台差异等诸多痛点。

最主流的两个 C++ 包管理器是 `vcpkg` 和 `Conan`。

### 使用 vcpkg 的清单模式

vcpkg 是微软推出的 C++ 包管理器，以其易用性和与 Visual Studio、CMake 的无缝集成而广受欢迎。其现代化的使用方式是**清单模式 (Manifest Mode)**。

在这种模式下，你在项目根目录创建一个 `vcpkg.json` 文件来声明依赖，CMake 会自动找到并使用它们。

**1. 创建 `vcpkg.json`**

```json
{
  "$schema": "https://raw.githubusercontent.com/microsoft/vcpkg-tool/main/docs/vcpkg.schema.json",
  "name": "my-project",
  "version": "0.1.0",
  "dependencies": ["fmt"]
}
```

这个文件告诉 vcpkg：“我的项目需要 `fmt` 库”。

**2. 编写 `CMakeLists.txt`**
CMake 脚本现在变得异常简洁：

```cmake
cmake_minimum_required(VERSION 3.18)
project(VcpkgExample LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 使用 find_package 查找由 vcpkg 提供的包
# vcpkg 会自动处理下载、编译和查找路径
find_package(fmt CONFIG REQUIRED)

add_executable(MyApp src/main.cpp)

# 直接链接，就像它已经被安装在系统上一样
target_link_libraries(MyApp PRIVATE fmt::fmt)
```

**3. 配置与构建**
关键在于，你需要在配置 CMake 时，通过 `CMAKE_TOOLCHAIN_FILE` 参数指向 vcpkg 的集成脚本。

```bash
# vcpkg a. 克隆 vcpkg
git clone https://github.com/microsoft/vcpkg.git
# vcpkg b. （Windows）运行引导脚本
./vcpkg/bootstrap-vcpkg.bat
# vcpkg c. （Linux/macOS）运行引导脚本
./vcpkg/bootstrap-vcpkg.sh

# CMake 配置，<path-to-vcpkg> 是你克隆 vcpkg 的路径
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake

# 构建
cmake --build build
```

vcpkg 会为每个成功编译的库（以特定的版本、配置和平台为标识）创建一份二进制缓存。当另一个完全独立的项目请求完全相同的库时，vcpkg 会直接复用这份缓存，而不是重新编译。

### 使用 vcpkg 的经典模式

如果你不想使用清单模式，vcpkg 也支持经典模式（Classic Mode），这种方式需要手动安装依赖库。

```bash
vcpkg install fmt
```

然后在 CMake 中使用 `find_package` 查找已安装的库：

```cmake
cmake_minimum_required(VERSION 3.18)
project(VcpkgClassicExample LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# 使用 find_package 查找已安装的包
find_package(fmt CONFIG REQUIRED)
add_executable(MyApp src/main.cpp)
# 链接到 fmt 库
target_link_libraries(MyApp PRIVATE fmt::fmt)
```

```bash
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake
cmake --build build
```

经典模块类似于全局安装的 pip 包，所有项目都可以共享已安装的库。清单模式则更像是每个项目都有自己的虚拟环境，避免了版本冲突。

### vcpkg 的清单模式 vs 经典模式

目前阶段，vcpkg 的清单模式是推荐的使用方式，因为它提供了更好的隔离性和可重复性，大家也不用担心每次使用清单模式时都要重新编译依赖库，vcpkg 会自动处理二进制缓存，如果你之前已经编译过相同版本的库，vcpkg 会直接复用缓存，甚至会直接使用之前编译好的二进制文件。

第一次使用 vcpkg 的清单模式时，可能会需要一些时间来下载和编译依赖库，但之后的构建速度会非常快，因为它会复用之前的编译结果。

```bash
[cmake] -- Found Boost: C:/Users/yeisme/code/language_dev/shell_dev/personal_project/cmake_template/folly_template/build/vcpkg_installed/x64-windows/share/boost/BoostConfig.cmake (found version "1.88.0") found components: context filesystem program_options regex system thread
[cmake] -- Found folly: C:/Users/yeisme/code/language_dev/shell_dev/personal_project/cmake_template/folly_template/build/vcpkg_installed/x64-windows
[cmake] -- Configuring done (3883.1s)
[cmake] -- Generating done (0.5s)
```

在 Windows 上，如果要舒服地使用 vcpkg，建议使用 msvc 工具链，除了因为它与 Visual Studio 集成得非常好，提供了更好的调试体验和编译速度，还因为 ports 中 x64-windows 的包通常是针对 msvc 工具链设计的，其他工具链可能会遇到一些兼容性问题。

> 提示：在使用 vcpkg 时，建议使用 `vcpkg integrate install` 命令将 vcpkg 与 Visual Studio 集成，这样可以在 Visual Studio 中直接使用 vcpkg 安装的库。

官方支持的 ports/folly 在 Windows 平台上仅支持 msvc 工具链，因此在使用 vcpkg 安装 folly 时，必须指定 msvc 工具链，如果你希望使用其他工具链，你需要自己编写支持 clang 或 gcc 的 ports。

在 cmake 中，可以通常，环境变量或者 CMake 变量进行 vcpkg 三元组配置

- 环境变量: set VCPKG_TARGET_TRIPLET=x64-mingw-dynamic
- CMake 参数: -DVCPKG_TARGET_TRIPLET=x64-mingw-dynamic

如果你希望用 Clang 配合 MinGW 的库，你需要确保你的 Clang 是为 MinGW 环境配置的，并将工具链文件中的 `CMAKE_CXX_COMPILER` 指向它。

vcpkg 相比于 git 子模块和 FetchContent 模块，有什么优势？

除了上述的二进制缓存和依赖管理优势外，我认为 vcpkg 的最大优势在于它的生态系统和社区支持。vcpkg 拥有一个庞大的库集合，几乎涵盖了所有常用的 C++ 库，并且这些库能够经过社区的验证，确保它们的稳定性和兼容性，在 GitHub 上提交 issue 时，通常会得到快速响应和处理，而且 vcpkg 的文档也非常完善，提供了详细的使用指南和示例。更重要的是，vcpkg 社区维护的 ports 库中，通常有补丁和配置选项来解决特定平台或编译器的问题，这使得在不同环境下使用同一库变得更加容易，我们不再需要手动处理各种平台和编译器的兼容性问题。

举个例子，folly 库在 Windows 上的支持并不完善，但 vcpkg 社区提供 folly 的 ports，确保了在 Windows 上使用 folly 时的兼容性和稳定性。在 [vcpkg Browse Package](https://vcpkg.io/en/packages) 上，可能搜索到 folly 支持的各个平台和工具链，以及 features、version 等更详细的信息。

```txt
(windows & x64 & !uwp & !mingw) | (!windows & !android & (x64 | arm64))
```

```cmake
C:\Users\yeisme\lib\vcpkg\ports\folly [master ≡]> ls

    Directory: C:\Users\yeisme\lib\vcpkg\ports\folly

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            2025/6/2     0:33           1165 disable-uninitialized-resize-on-new-stl.patch
-a---            2025/6/2     0:33            498 fix-absolute-dir.patch
-a---            2025/6/2     0:33           7268 fix-deps.patch
-a---            2025/6/2     0:33            358 fix-unistd-include.patch
-a---            2025/6/2     0:33           2611 portfile.cmake
-a---            2025/6/2     0:33           2141 vcpkg.json
```

再举个例子，OpenCV 库的社区编译版本通常不支持 cuda feature，但 vcpkg 社区提供的 OpenCV ports 通常会包含对 cuda 的支持，并且提供了详细的配置选项来启用或禁用特定功能。

```bash
vcpkg install opencv4[core,cuda] --recurse
```

如果我们需要手动处理这些库的编译和配置，可能需要花费大量时间来解决各种依赖问题和兼容性问题，而 vcpkg 则可以自动处理这些问题，让我们专注于业务逻辑的开发。

```txt
<path-to-vcpkg>/
├── packages/
│   └── fmt_x64-windows/  <-- 这就是 fmt 在 x64-windows 配置下的二进制缓存
│       ├── include/      <-- 头文件
│       ├── lib/          <-- 静态库 (.lib)
│       ├── share/        <-- CMake 配置文件 (fmt-config.cmake)
│       └── ...
├── ports/                <-- 存放所有库的“配方”
├── buildtrees/           <-- 存放构建时的临时文件
└── installed/            <-- 存放经典模式下安装的库

```

### conan

Conan 是另一个流行的 C++ 包管理器，由 JFrog 公司（以 Artifactory 闻名）支持。它以其无与伦比的**灵活性、强大的二进制包管理能力和对复杂构建场景的精细控制**而著称。Conan 不仅仅是一个工具，更是一个完整的依赖管理框架。

相比 vcpkg 的“一体化”和“自动化”哲学，Conan 给了开发者更多的控制权。它支持多种构建系统，包括 CMake、Makefile、Meson 等。

> Conan 的核心理念

1. **二进制优先 (Binary-First)**：Conan 的首要目标是分发和复用**预编译好的二进制包**。它会根据你的操作系统、架构、编译器和配置（这些被称为 "profile"）生成一个唯一的包 ID。如果远程仓库有匹配的二进制包，Conan 会直接下载使用，极大地节约了编译时间。只有在找不到匹配的二进制包时，它才会从源码编译（`--build=missing`）。
2. **配置与环境分离**：通过**Profiles** 的概念，Conan 将“构建环境”（如 CI 服务器上的 Linux+GCC）和“目标环境”（如要部署的 ARM 嵌入式设备）清晰地分离开来，这使得交叉编译变得异常简单。
3. **Python 驱动的“配方”**：Conan 的包定义文件 (`conanfile.py`) 是一个 Python 脚本，这赋予了它极高的可编程性和灵活性，可以处理非常复杂的构建逻辑。对于简单场景，可以使用更简洁的 `conanfile.txt`。

> Conan 的工作流 (以 CMake 为例)

Conan 与 CMake 的集成工作流分为清晰的两步：

1. **依赖解析 (Conan)**：运行 `conan install` 命令。Conan 会读取你的依赖描述文件，下载或构建依赖，并生成用于 CMake 集成的文件（如工具链文件和包查找文件）。
2. **项目构建 (CMake)**：运行 `cmake` 命令，通过 `-DCMAKE_TOOLCHAIN_FILE` 指向 Conan 生成的工具链文件，然后正常编译项目。
   相比 vcpkg，conan 拥有更强大的命令行工具，并且支持二进制包的上传和下载。

内置模板包括 `cmake_lib`、`cmake_exe`、`header_lib` 等，适用于不同类型的项目。

```bash
  template              Template name, either a predefined built-in or a user-provided one. Available built-in templates: basic, cmake_lib, cmake_exe,
                        header_lib, meson_lib, meson_exe, msbuild_lib, msbuild_exe, bazel_lib, bazel_exe, autotools_lib, autotools_exe,
                        local_recipes_index, workspace. E.g. 'conan new cmake_lib -d name=hello -d version=0.1'. You can define your own templates too
                        by inputting an absolute path as your template, or a path relative to your conan home folder.
```

conan 的工作流与 vcpkg 类似，但它提供了更强大的命令行工具，并且支持二进制包的上传和下载。

| 特性        | Conan                                              | vcpkg                                   |
| ----------- | -------------------------------------------------- | --------------------------------------- |
| 核心哲学    | 二进制优先、去中心化、高度灵活                     | 源码优先、中心化、易于上手              |
| 学习曲线    | 较陡 (Profiles, Python 配方)                       | 较平缓 (清单模式非常直观)               |
| 二进制管理  | 极强，核心功能                                     | 较弱 (有二进制缓存，但不是核心)         |
| 企业/私有库 | 极佳 (易于搭建私有 remote)                         | 较复杂 (需要自定义 registry)            |
| 交叉编译    | 极佳 (通过 Profiles 精细控制)                      | 支持，但不如 Conan 灵活，且配置较为繁琐 |
| IDE 集成    | 有插件 (VS, CLion)，但通常需手动运行 conan install | 无缝 (VS, VS Code 插件自动处理)         |
| 工作流      | 两步式 (conan install + cmake)                     | 一体化 (清单模式下 cmake 自动触发)      |

这两个包管理器各有千秋，选择哪个取决于你的项目需求和团队习惯。就目前而言，vcpkg 生态系统更为成熟，社区支持更广泛，而且还有微软的官方支持，而 Conan 则在灵活性和二进制管理上有独到之处，各有各的优势。

## 其它

除了上述的包管理器，现代 C++ 生态系统中还有一些其他包管理器或者构建工具，例如 xmake、bazel、meson 等。

这次我些不熟悉，就不展开了，感兴趣的同学可以自行查阅相关资料。

## 总结

- **对于新项目或任何严肃的项目，请优先选择包管理器**。`vcpkg` 的清单模式是现代 C++ 项目管理的黄金标准，它能为你节省大量的时间和精力。
- **对于非常小的项目、快速原型或仅依赖头文件库的情况**，`FetchContent` 是一个非常方便、无需额外工具的轻量级选择。
- **当你需要对依赖的源码进行频繁修改和贡献，或者依赖库本身不提供 CMake 支持时**，`Git Submodule` 仍然是一个可靠的传统方案。
