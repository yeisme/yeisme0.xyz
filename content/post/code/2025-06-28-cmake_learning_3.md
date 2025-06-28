+++
title = "现代 CMake 学习（3）"
date = "2025-06-28T21:06:12+08:00"
description = ""
tags = ["CMake","C++","C"]
categories = ["编程","教程"]
series = []
aliases = []
image = ""
draft = false
+++

# 现代 CMake 学习（3）：依赖查找的艺术——深入 `find_*` 命令族

## 引言

`find_package` 是现代 CMake 中用于查找和加载外部依赖项（库、框架、工具包）的核心命令。可以说，掌握了 `find_package`，就掌握了 CMake 依赖管理的命脉。它优雅地将使用者与复杂的库查找、路径配置等细节隔离开来。

`find_package` 的主要目的只有一个：**为你的项目找到一个外部依赖，并加载其使用信息**。这些“使用信息”通常包括：

- 需要链接的库文件（.lib, .a, .so, .dll）
- 需要包含的头文件目录
- 需要设置的编译定义或选项
- 该依赖自身所依赖的其他库（传递性依赖）

在现代 CMake 项目中，`find_package` 是一个强大的工具，但它并不是解决所有依赖查找问题的万能钥匙。随着项目规模的扩大和复杂度的增加，我们常常会遇到一些 `find_package` 无法处理的场景——如果有一天，你需要链接的是一个十年前的、没有提供官方 CMake 支持的科学计算库，或者你需要一个特定的命令行工具来辅助编译（代码生成器、代码格式化工具等），这时你就需要深入了解 CMake 的 `find_*` 命令族。

本篇文章将深入探讨 CMake 的 `find_*` 命令族，帮助你理解为什么 `find_package` 是现代 CMake 的核心，以及如何使用 `find_program`、`find_library`、`find_path` 等命令来处理更复杂（更底层）的依赖查找问题。

## 核心原理：CMake 的搜索策略

CMake 并不是凭空找到文件，而是遵循一套严格、可预测的搜索顺序

> **寻找顺序逻辑**（以  `find_package`  为例）

- `PATHS` > `HINTS` > `_DIR 变量` > `CMAKE_PREFIX_PATH` > 注册表 > 系统路径。
- 环境变量优先级低于同名 CMake 变量（如  `-D<PackageName>_DIR`  覆盖环境变量）。

这里看不懂？没关系，我们只为自己需要的功能进行探索，在学习找包阶段，我们只需要知道 CMake 会在一系列预定义的路径中查找所需的文件，并且可以通过设置一些变量来影响搜索路径。

等到需要学习类似排除干扰的高级技巧时，我们再学习如何使用 `CMAKE_FIND_ROOT_PATH`、`CMAKE_FIND_PACKAGE_PREFER_CONFIG`、`NO_DEFAULT_PATH` 等变量来控制搜索行为。

例如通常将包含 `OpenCVConfig.cmake` 的目录加入到环境变量 `CMAKE_PREFIX_PATH` 中，这样 CMake 就可以在这些路径中查找 OpenCV 的配置文件。

以此类推，我们可以为其他库或工具设置类似的环境变量 `PATH` 等变量来添加 CMake 的搜索路径。

## `find_package`

### `find_package` 的两种工作模式

这是理解 `find_package` 的关键。它主要在两种模式下工作，CMake 会根据情况自动选择，你也可以强制指定。

#### 1. Module 模式 (模块模式)

- **工作原理**：CMake 会去寻找一个名为 `Find<PackageName>.cmake` 的文件并执行它。这个文件是一个 CMake 脚本，其任务是“像侦探一样”通过各种手段（如 `find_path`, `find_library`, 检查环境变量、注册表等）来定位库的各个部分。
- **谁来提供**：
  1. CMake 官方会自带很多常用库的 `Find` 模块（如 `FindBoost.cmake`, `FindThreads.cmake`）。
  2. 库的使用者（你）可以自己编写，或者从社区找到。
- **查找路径**：CMake 会在 `CMAKE_MODULE_PATH` 变量指定的目录列表和 CMake 自身的模块安装目录中寻找这个 `Find` 脚本。
- **产出结果**：传统上，`Find` 模块会定义一系列变量，如 `<PackageName>_FOUND`, `<PackageName>_INCLUDE_DIRS`, `<PackageName>_LIBRARIES`。
- **适用场景**：主要用于**兼容那些本身不提供 CMake 支持的、老的或非 CMake 构建的库**。它是一种向后兼容的、万能的“胶水层”。

#### 2. Config 模式 (配置模式)

- **工作原理**：CMake 会去寻找由**库作者提供**的两个关键文件：`<PackageName>Config.cmake` (或 `<package-name>-config.cmake`) 和可选的 `<PackageName>ConfigVersion.cmake`。这些文件不是搜索脚本，而是库作者在安装库时生成的“**官方使用说明书**”。
- **谁来提供**：**库的作者**。在库的 `CMakeLists.txt` 中，作者使用 `install(EXPORT ...)` 命令来自动生成这些配置文件。
- **查找路径**：CMake 会在 `CMAKE_PREFIX_PATH` 变量指定的目录列表以及一些系统默认路径中寻找这些 `Config` 文件。
- **产出结果**：**导入的目标 (Imported Targets)**。这是现代 CMake 的黄金标准。例如 `PackageName::PackageName` 或 `PackageName::Component`。这些目标封装了关于库的所有使用信息。
- **适用场景**：**所有使用 CMake 构建并正确安装的现代库**。这是**首选的、更可靠的、更强大的模式**。

**CMake 如何选择模式？** 默认情况下，CMake 会优先尝试 `Config` 模式。如果找不到对应的 `Config.cmake` 文件，它会自动回退到 `Module` 模式，去寻找 `Find<PackageName>.cmake` 文件。你也可以通过 `find_package(<PackageName> CONFIG)` 或 `find_package(<PackageName> MODULE)` 来强制指定模式。

### 解析

```cmake
find_package(<PackageName>
             [version] [EXACT]
             [QUIET]
             [REQUIRED]
             [COMPONENTS [component...]]
             [OPTIONAL_COMPONENTS [component...]]
             ...
)
```

- `<PackageName>`: 你要查找的包的名称，例如 `Boost`, `Qt5`, `OpenCV`。它**大小写敏感**。
- `[version]`: 你期望的最低版本号，例如 `3.14`。如果找到的版本低于此版本，则认为查找失败。
- `EXACT`: 要求版本必须与 `[version]` 精确匹配。
- `REQUIRED`: **非常重要**。如果设置了此参数，当 `find_package` 找不到包时，它会立即停止配置并报错。如果没有设置，它只会静默失败，你可以通过检查 `<PackageName>_FOUND` 变量来后续处理。在不使用 `REQUIRED` 的情况下，可以结合 `if`、`option` 等命令来处理查找结果，并进行条件编译或链接。
- `QUIET`: 禁止打印查找过程中的状态信息。即使查找失败也不会打印错误消息（除非设置了 `REQUIRED`）。
- `COMPONENTS`: 用于指定你需要库中的哪些组件。例如，`find_package(Qt5 REQUIRED COMPONENTS Core Gui Widgets)`。只有当所有指定的组件都被找到时，查找才算成功，对于大型库（如 Qt、Boost）尤其有用。

在 Config 模式下，库会提供导入的目标。你只需要链接这些目标，CMake 会自动处理好头文件、库文件、编译定义和传递性依赖。

```cmake
# 现代方式
find_package(Boost 1.70.0 REQUIRED COMPONENTS system filesystem)

add_executable(my_app main.cpp)

# 只需要链接导入的目标，所有信息（include、link等）都被封装好了
target_link_libraries(my_app PRIVATE Boost::system Boost::filesystem)
```

### CMake 的搜索路径详解

“为什么 `find_package` 找不到我的库？”是 CMake 新手最常问的问题。答案就在于搜索路径。

- **对于 Module 模式 (`Find<...>.cmake`)**：
  1. `CMAKE_MODULE_PATH`：一个由分号分隔的目录列表，你可以将自己写的或下载的 `Find` 模块放在这里。
  2. CMake 安装目录下的 `Modules` 文件夹：这里存放了 CMake 自带的所有 `Find` 模块。
- **对于 Config 模式 (`...Config.cmake`)**：
  1. **`CMAKE_PREFIX_PATH`**：**最重要的变量**。一个由分号分隔的目录列表，指向库的**安装根目录**。例如，如果你把库安装在 `/opt/my_lib`，那么这个目录下应该有 `lib/cmake/my_lib/my_libConfig.cmake` 这样的结构。你在配置项目时，通过 `-DCMAKE_PREFIX_PATH=/opt/my_lib` 告诉 CMake 去这里找。
  2. 环境变量：如 `<PackageName>_DIR`，或 Windows 上的 `PATH`。
  3. 系统预定义路径：如 `/usr/local/`, `/usr/`, `/opt/` (Linux), `C:/Program Files/` (Windows)。

**解决找不到问题的首要步骤**：确认你的库是否正确安装，然后通过 `-DCMAKE_PREFIX_PATH=/path/to/library/install/root` 来明确告诉 CMake 在哪里寻找。

> 当你有大量的依赖时，使用 `CMAKE_PREFIX_PATH` 是非常有用的。你除了可以在 CMake 命令行中设置它，还可以在你的 `CMakeLists.txt` 中设置默认值。

```cmake
# 在 CMakeLists.txt 中设置默认的 CMAKE_PREFIX_PATH
set(CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/external_libs" CACHE PATH "Path to external libraries")
```

在命令行使用 `cmake -DCMAKE_PREFIX_PATH=/path/to/libs` 可以覆盖这个默认值。

## 其他命令详解

### `find_program`：寻找可执行文件

`find_program` 用于查找系统中的可执行文件。

```cmake
find_program(<VAR> NAMES name1 [name2...])
```

这有什么用？当你需要在 CMake 中使用某个命令行工具（如 `clang-format`、`clang-tidy` 等）时，可以使用 `find_program` 来查找该工具的路径。

例如，查找 `clang-format` 并格式化源代码：

```cmake
find_program(CLANG_FORMAT clang-format)
if(CLANG_FORMAT)
    message(STATUS "Found clang-format: ${CLANG_FORMAT}")
    add_custom_target(format
        COMMAND ${CLANG_FORMAT} -i ${CMAKE_SOURCE_DIR}/src/*.cpp
        COMMENT "Formatting source files with clang-format"
    )
else()
    message(FATAL_ERROR "clang-format not found")
endif()
```

这里的 `CLANG_FORMAT` 变量将被设置为 `clang-format` 的路径，如果找不到该工具，CMake 将抛出错误(`FATAL_ERROR`)。

`find_program` 通常需要结合其它 cmake 命令使用，如 `if`、`message` 等来处理查找结果，并使用 `add_custom_target`、`add_custom_command` 等命令来执行查找结果。

对比直接在 bash、makefile 中使用 `which` 命令查找可执行文件，CMake 的 `find_program` 提供了更好的跨平台支持和集成，在 Windows 上通常使用 `where` 命令查找可执行文件，而在 Linux 和 macOS 上使用 `which` 命令，这就是 CMake 为了跨平台而提供的统一接口(不得不说，这是真的繁琐)。

### `find_library` & `find_path`：寻找库和头文件

`find_library` 和 `find_path` 分别用于查找库文件和头文件。

---

```
    Directory: C:\Users\yeisme\lib\vcpkg\packages\arrow_x64-windows

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----           2025/6/15     1:32                bin
d----           2025/6/15     1:32                debug
d----           2025/6/15     1:32                include
d----           2025/6/15     1:32                lib
d----           2025/6/15     1:32                share
-a---           2025/6/15     1:32             46 BUILD_INFO
-a---           2025/6/15     1:32           1511 CONTROL
```

假如我们需要链接 arrow 库，并且知道它的头文件和库文件的名称，我们可以使用以下命令：

```cmake
find_library(ARROW_LIB NAMES arrow PATHS "C:/Users/yeisme/lib/vcpkg/packages/arrow_x64-windows/lib")
find_path(ARROW_INCLUDE_DIR NAMES arrow/api.h PATHS "C:/Users/yeisme/lib/vcpkg/packages/arrow_x64-windows/include")
```

这将查找名为 `arrow` 的库文件和头文件，并将它们的路径存储在 `ARROW_LIB` 和 `ARROW_INCLUDE_DIR` 变量中。

之后，我们可以使用这些变量来链接库和设置头文件搜索路径：

```cmake
if(ARROW_LIB AND ARROW_INCLUDE_DIR)
    message(STATUS "Found Arrow library: ${ARROW_LIB}")
    message(STATUS "Found Arrow include directory: ${ARROW_INCLUDE_DIR}")
    add_library(arrow_shared SHARED IMPORTED)
    set_target_properties(arrow_shared PROPERTIES
        IMPORTED_LOCATION ${ARROW_LIB}
        INTERFACE_INCLUDE_DIRECTORIES ${ARROW_INCLUDE_DIR}
    )
else()
    message(FATAL_ERROR "Arrow library or include directory not found")
endif()
```

上面的代码首先检查是否找到了 `ARROW_LIB` 和 `ARROW_INCLUDE_DIR`，如果找到了，就创建一个名为 `arrow_shared` 的共享库，并设置其属性。如果没有找到，则抛出错误。

`IMPORTED_LOCATION ` 属性指定了库文件的位置，而 `INTERFACE_INCLUDE_DIRECTORIES` 属性指定了头文件的搜索路径。

实际上，`find_library` 和 `find_path` 的使用方式与 `find_program` 类似，只是它们查找的对象不同，但是由于现代 CMake 的 `find_package` 命令已经封装了这些查找逻辑，因此在大多数情况下，我们只需要使用 `find_package` 即可。

### `find_file`：寻找特定文件

`find_file` 用于查找特定的文件，通常用于查找配置文件或其他非库文件。

```cmake
find_file(<VAR> NAMES name1 [name2...] PATHS path1 [path2...])
```

例如，如果你需要查找一个名为 `config.json` 的配置文件，可以使用以下命令：

```cmake
find_file(CONFIG_FILE NAMES config.json PATHS "${CMAKE_SOURCE_DIR}/config")
if(CONFIG_FILE)
    message(STATUS "Found config file: ${CONFIG_FILE}")
else()
    message(FATAL_ERROR "Config file not found")
endif()
```

这里的 `CONFIG_FILE` 变量将被设置为 `config.json` 的路径，如果找不到该文件，CMake 将抛出错误。

## 现代 CMake 实践的核心: export vs import

毫无疑问，现代 CMake 极力推荐库的作者通过 install(EXPORT ...) 导出自己的目标，生成 PackageConfig.cmake 文件。这样作为用户的我们就可以通过 `find_package` 直接使用这些目标，而不需要关心具体的实现细节。

`Find<Package>.cmake` 模块是一种兼容旧库或非 CMake 项目的必要补充手段，而不是首选。

下面我将从“理念”、“责任方”和“实践”三个角度深入剖析，为什么导出是更优的方式。

### 核心理念的差异：“我告诉你怎么用” vs “我帮你到处找”

- **`Export` (Config 模式):** 这种模式的理念是“**我，作为库的作者，最清楚如何正确地使用我。**”

  - 在库的构建和安装过程中，作者通过 `install(EXPORT ...)` 命令，将关于目标（Target）的所有信息——包括库文件位置、头文件目录、编译定义、以及对其他库的传递性依赖——都**精确地记录**在一个或多个 `.cmake` 文件中（如 `SDL2Config.cmake`, `SDL2Targets.cmake`）。
  - 这个导出的配置就像是库自带的“**使用说明书**”。

- **`FindSDL2.cmake` (Module 模式):** 这种模式的理念是“**你，作为库的使用者，告诉我库大概在哪，我来帮你四处寻找和拼凑。**”
  - `Find` 模块本质上是一个启发式（heuristic）的搜索脚本。它使用 `find_path` 寻找头文件、`find_library` 寻找库文件，然后将这些零散的路径拼凑成 `_INCLUDE_DIRS` 和 `_LIBRARIES` 这样的变量。
  - 这个过程充满了**猜测和不确定性**，因为它无法 100% 确定找到的头文件和库文件就是匹配的一对。

### 责任方的转变：从使用者到作者

这是两者最根本的区别，也是为什么导出是“现代”做法的原因。

| 特性/方面      | `Find<Package>.cmake` (Module 模式)                                      | `PackageConfig.cmake` (Export 模式)                                      |
| -------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| **责任方**     | **库的使用者**（或 CMake/社区提供通用脚本）                              | **库的作者**                                                             |
| **工作原理**   | **搜索和猜测**（Heuristics）                                             | **加载和声明**（Manifest）                                               |
| **可靠性**     | **较低**。可能因系统环境不同而失败。                                     | **极高**。作者直接提供了正确的信息。                                     |
| **信息完整性** | **有限**。通常只提供头文件和库路径。                                     | **完整**。包含传递依赖、编译选项、导入目标等所有信息。                   |
| **维护性**     | **困难**。当库更新了目录结构，`Find`脚本就可能失效。                     | **简单**。库作者在更新库的同时，会更新导出逻辑。                         |
| **使用方式**   | `find_package(SDL2)` <br> `target_link_libraries(... ${SDL2_LIBRARIES})` | `find_package(SDL2 CONFIG)` <br> `target_link_libraries(... SDL2::SDL2)` |
