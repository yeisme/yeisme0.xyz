+++
title = "现代 CMake 学习（4）"
date = "2025-07-04T15:35:24+08:00"
description = ""
tags = ["CMake","C++","C"]
categories = ["编程","教程"]
series = []
aliases = []
image = ""
draft = false
+++

# 现代 CMake 学习（4）： 使用 CTest 进行单元测试

随着我们的能力逐渐增强，我们肯定需要参与更多的项目，或者自己创建一些项目。无论是参与还是创建，测试都是必不可少的环节。当我们在学习阶段时，代码量不大，我们可以通过运行程序来验证代码的正确性，可以通过打印日志来检查代码的执行情况。但是当代码量增大时，这种方法就不够用了，如果我们没有测试代码的习惯，那么我们就会陷入一个死循环：每次修改代码后都需要手动运行程序来验证，这样不仅效率低下，而且容易出错，因为我们可能会忘记测试某些功能，或者测试时没有覆盖到所有的情况，逐渐得整个项目就变得难以维护，变成了一个“屎山”。

今天我们就来学习如何使用 CTest 来进行单元测试。CTest 是 CMake 的一部分，它提供了一种简单的方式来运行测试用例，并生成测试报告。CTest 可以与 CMake 项目无缝集成，支持多种测试框架，如 Google Test、Catch2 等。

## CTest 的基本用法

CTest 的基本用法非常简单。我们只需要在 CMakeLists.txt 文件中添加一些指令，就可以启用 CTest 功能。以下是一个简单的示例：

测试配置代码前的 cmake 文件，和下一节要将的打包 cpack 和 install 的代码是一样的。

```cmake
cmake_minimum_required(VERSION 3.25)

project(cmake_pack_and_install VERSION 1.0.0 LANGUAGES CXX)

include(cmake/pack.cmake)

# 构建动态库
add_library(mylib SHARED
    src/mylib.cpp
)

set_target_properties(mylib PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS TRUE)

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

# ## 测试配置

# CTest
enable_testing()

# gtest
find_package(GTest CONFIG REQUIRED)

add_executable(mylib_test tests/mylib_test.cpp)
target_link_libraries(mylib_test PRIVATE GTest::gtest_main mylib)
target_include_directories(mylib_test PRIVATE ${PROJECT_SOURCE_DIR}/include)

add_test(NAME mylib_test
  COMMAND mylib_test
  WORKING_DIRECTORY $<TARGET_FILE_DIR:mylib>
)

```

在这个示例中，我们首先调用 `enable_testing()` 函数来启用 CTest 功能。然后我们添加了一个可执行文件 `my_test`，它包含了我们的测试代码。最后，我们使用 `add_test()` 函数来注册一个测试用例，指定测试的名称和要运行的命令。

当我们使用 CMake 构建项目时，CTest 会自动生成一个测试目标，我们可以使用以下命令来运行所有的测试用例：

假设我们配置目录是 `build`，并完成了编译，可以使用以下命令来运行测试：

```bash
cd build
ctest
# 或者
ctest -C Debug
```

这里有些注意事项：

### 生成器产生的差异

ctest 是否需要 `-C Release` 取决于你的构建系统和生成器类型：

1. **单配置生成器（如 Makefile、Ninja 单配置）**

   - 只会生成一种配置（Debug 或 Release），可执行文件和测试都在同一个目录下。
   - 这时直接运行 `ctest` 就能找到测试，不需要 `-C` 参数。

2. **多配置生成器（如 Visual Studio、Ninja Multi-Config、Xcode）**
   - 会同时生成 Debug、Release 等多个配置，每种配置的可执行文件在不同子目录（如 Debug、Release）。
   - 这时必须用 `ctest -C Release` 或 `ctest -C Debug` 指定你要测试的配置，否则 ctest 默认找 Debug 或找不到测试。

**总结：**

- 单配置生成器：`ctest` 就够了。
- 多配置生成器：必须 `ctest -C <配置名>`。

你的项目用的是 Ninja Multi-Config，所以需要加 `-C Release` 或 `-C Debug`。

### Testing 目录

CTest 会在构建目录下创建一个 `Testing` 目录，里面包含了测试的相关信息和结果。你可以在这个目录下找到测试的日志文件、结果文件等。

## 现代测试

以上代码可以运行测试，但是它并不是现代 CMake 推荐的方式。这种方式的核心问题在于粒度太粗。CTest 只知道它需要运行 my_test 这个程序，至于程序内部有多少个独立的测试用例，哪些成功了，哪些失败了，它一无所知。

现代 CMake 推荐使用 `gtest_discover_tests` 函数来自动发现和注册 Google Test 测试用例。

```cmake
# CTest
enable_testing()

# gtest
find_package(GTest CONFIG REQUIRED)

add_executable(mylib_test mylib_test.cpp)
target_link_libraries(mylib_test PRIVATE GTest::gtest_main mylib)
target_include_directories(mylib_test PRIVATE ${PROJECT_SOURCE_DIR}/include)

include(GoogleTest)

gtest_discover_tests(mylib_test)
```

```cpp
// tests/mylib_test.cpp
#include <gtest/gtest.h>
#include "mylib.h"

TEST(MylibTest, Add) {
    EXPECT_EQ(mylib_add(2, 3), 5);
    EXPECT_EQ(mylib_add(-1, 1), 0);
}

TEST(MylibTest, Subtract) {
    EXPECT_EQ(mylib_subtract(5, 3), 2);
    EXPECT_EQ(mylib_subtract(0, 1), -1);
}

TEST(MylibTest, Multiply) {
    EXPECT_EQ(mylib_multiply(2, 3), 6);
    EXPECT_EQ(mylib_multiply(-2, 3), -6);
}

TEST(MylibTest, Divide) {
    EXPECT_EQ(mylib_divide(6, 3), 2);
    EXPECT_EQ(mylib_divide(1, 0), 0); // 除零返回0
}

```

这是为什么？有必要使用 `gtest_discover_tests` 吗？如果你在 CMake 中集成 Google Test，是否有必要使用 `include(GoogleTest)` 和 `gtest_discover_tests`？答案是：**是的，当然有必要！**

当然有必要！而且，这不仅是“有必要”，它更是**当前在 CMake 中集成 Google Test 的官方推荐和最佳实践**。

它触及了 CMake 测试实践从“传统”到“现代”演变的核心。让我详细解释一下为什么 `gtest_discover_tests` 如此重要，以及它解决了什么问题。

### 结论先行

**是的，非常有必要使用。** `include(GoogleTest)` 和 `gtest_discover_tests` 是将 Google Test 框架的强大功能与 CTest 测试驱动程序无缝结合的关键“粘合剂”。放弃它，就相当于放弃了现代 CMake 测试工作流带来的一半以上的好处。

### 为什么 `gtest_discover_tests` 不可或缺？

在没有 `gtest_discover_tests` 的时代，我们通常这样做：

```cmake
# 传统方式 (不推荐)
add_executable(mylib_test mylib_test.cpp)
target_link_libraries(mylib_test PRIVATE GTest::gtest_main mylib)

# 将整个测试程序注册为一个 CTest 测试用例
add_test(NAME mylib_test COMMAND mylib_test)
```

这种方式的问题在于，对于 CTest 来说，它只知道一个名为 `mylib_test` 的测试。无论你的 `mylib_test.cpp` 文件里包含了 1 个 `TEST` 还是 100 个 `TEST`，CTest 的视角都是：

> “我运行了 `mylib_test` 这个程序，它返回了 0，所以 `mylib_test` 这个**单一个体**通过了。”

以上面的 `mylib_test.cpp` 为例，假设它包含了四个测试用例：`Add`, `Subtract`, `Multiply`, `Divide`。在传统方式下，CTest 只会显示一个测试结果，如果其中一个测试失败了，你只能看到这个测试没有通过，但是你并不知道具体是哪个测试案例(如 `Add` 或 `Subtract`) 失败了，你还需要针对每个函数手动去查找和调试，这同样需要手动维护测试列表。

而 `gtest_discover_tests(mylib_test)` 则完全改变了这一点。

#### 从“一个测试”到“一组测试”的质变（核心优势）

`gtest_discover_tests` 会在构建时或测试时，通过运行 `mylib_test --gtest_list_tests` 来**自动发现**可执行文件中的**每一个** `TEST`, `TEST_F`, `TEST_P` 宏，并将它们分别注册为独立的 CTest 测试用例。

- **传统方式的 CTest 输出:**

```
1/1 Test #1: mylib_test ........................ Passed
```

- **使用 `gtest_discover_tests` 的 CTest 输出:**

```
1/5 Test #1: MyTestSuite.TestA ............... Passed
2/5 Test #2: MyTestSuite.TestB ............... Passed
3/5 Test #3: AnotherSuite.TestC ..............\*\*\*Failed
4.5 Test #4: AnotherSuite.TestD .............. Passed
5/5 Test #5: ParametricTest/0.TestE .......... Passed
```

实际上，CTest 会将每个测试用例注册为独立的测试，这样你就可以清晰地看到每个测试用例的执行结果。

```bash
[ctest]     Start 1: MylibTest.Add
[ctest]     Start 2: MylibTest.Subtract
[ctest]     Start 3: MylibTest.Multiply
[ctest]     Start 4: MylibTest.Divide
[ctest] 1/4 Test #1: MylibTest.Add ....................   Passed    0.46 sec
[ctest] 2/4 Test #3: MylibTest.Multiply ...............   Passed    0.23 sec
[ctest] 3/4 Test #2: MylibTest.Subtract ...............   Passed    0.35 sec
[ctest] 4/4 Test #4: MylibTest.Divide .................   Passed    0.13 sec
```

这种**测试粒度**的提升是革命性的。你可以清晰地看到哪个具体的测试用例失败了，而不是仅仅知道“程序出错了”。

#### 启用所有高级 CTest 功能

只有当每个测试用例都被独立注册后，CTest 的高级功能才能发挥作用。

- **并行测试 (`ctest -j<N>`)**: CTest 可以同时运行多个独立的测试用例，极大地缩短了大型项目的测试时间。如果只有一个测试，这个功能完全无效。
- **测试筛选 (`ctest -R <regex>` 或 `-E <regex>`)**: 你可以根据正则表达式运行特定的测试用例。例如，`ctest -R MyTestSuite` 只会运行 `MyTestSuite` 中的测试。
- **测试标签 (`ctest -L <label>`)**: 你可以为某些测试（比如 "slow", "network"）打上标签，并选择性地运行它们。
- **失败后重跑 (`ctest --rerun-failed`)**: CTest 会记录上次失败的测试用例，并只重新运行它们。

所有这些高效的功能，都建立在 `gtest_discover_tests` 提供的精细化测试列表之上。

#### 极大地提升了可维护性

想象一下，你新写了一个测试函数：

```cpp
// 在 mylib_test.cpp 中新增
TEST(NewFeatureTest, HandlesBasicCase) {
    // ...
}
```

- **使用 `gtest_discover_tests`**: 你**不需要对 `CMakeLists.txt` 做任何修改**。只需重新编译，`gtest_discover_tests` 就会自动发现这个新的测试。
- **不使用它**: 你将不得不手动维护一个测试列表，这在实际项目中是不可想象的。

这种“一次配置，永远有效”的特性，将测试的编写与构建系统的配置完全解耦。

#### 更好的 IDE 集成

现代 IDE（如 CLion、VS Code with CMake Tools）能够与 CTest 深度集成。它们会调用 `ctest --show-only=json-v1` 来获取测试列表，并在 UI 中以树状结构展示出来。这同样依赖于 `gtest_discover_tests` 发现并注册的每一个独立测试。

> vscode 中要安装: fredericbonnet.cmake-test-adapter 这个插件。

{{< figure src="image.png" alt="cmake_4" >}}

### `include(GoogleTest)` 是什么？

`include(GoogleTest)` 这个命令本身的作用是加载 CMake 自带的 `GoogleTest` 模块。这个模块提供了 `gtest_discover_tests` 等便利函数。所以，它们是相辅相成的。

目前这是一个官方支持的 cmake 模块，包含了 Google Test 的集成支持。它提供了许多有用的函数和宏来简化 Google Test 的使用。每次安装 CMake 时，都会自动包含这个模块。

## 如何获取并链接 Google Test？

我们刚才提到了 find_package(GTest ...)。这个命令要求 Google Test 已经被安装在系统上，并且能被 CMake 找到。这对于个人开发可能还好，但对于团队协作和持续集成（CI）来说，这会带来环境依赖问题——每个开发者和每台构建服务器都需要手动安装好 GTest。

现代 CMake 提供了更优雅的解决方案：FetchContent 模块。它可以在配置阶段自动下载、配置并构建依赖项，使你的项目变得自包含（self-contained）。

```cmake
# --- 推荐：使用 FetchContent 管理 GTest 依赖 ---
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
  # 或者使用 Git 仓库
  # GIT_REPOSITORY https://github.com/google/googletest.git
  # GIT_TAG        release-1.14.0
)

# FetchContent_MakeAvailable 会下载并调用 add_subdirectory(googletest)
# 这使得 GTest::gtest_main 等目标在我们的项目中可用
FetchContent_MakeAvailable(googletest)
```

使用 FetchContent 时，CMake 会在配置阶段下载 GTest 的源代码并编译它，这可能会增加配置时间，但它确保了每次构建都使用相同版本的 GTest，避免了版本不一致的问题。

不过除了直接使用 FetchContent 之外，你也可以使用 vcpkg 或 Conan 等包管理工具来管理 GTest 依赖，这些工具可以更好地处理跨平台和版本兼容性问题，并且在多依赖的项目中表现更好。

## 其他测试框架

除了 Google Test，CMake 还支持其他测试框架，比如 Catch2 和 Boost.Test。你可以根据项目需求选择合适的测试框架，并通过相应的 CMake 配置进行集成。

CMake 对 Catch2 也有非常好的支持

其现代化的集成方式和 GTest 非常相似，但实现机制略有不同。CMake 本身并没有一个像 GoogleTest 那样内置的 FindCatch2.cmake 模块。但不用担心，因为 Catch2 自身提供了世界一流的 CMake 集成支持。当你通过现代 CMake 的方式（如 FetchContent）获取 Catch2 后，它会自带一系列 CMake 脚本，其中就包括了实现测试自动发现的核心功能。

与 Google Test 类似，Catch2 也提供了 `catch_discover_tests` 函数来自动发现测试用例。以下是一个简单的示例：

```cpp
#define CATCH_CONFIG_MAIN
#include "mylib.h"
#include <catch2/catch_test_macros.hpp>

TEST_CASE("Add", "[mylib]")
{
    REQUIRE(mylib_add(2, 3) == 5);
    REQUIRE(mylib_add(-1, 1) == 0);
}

TEST_CASE("Subtract", "[mylib]")
{
    REQUIRE(mylib_subtract(5, 3) == 2);
    REQUIRE(mylib_subtract(0, 1) == -1);
}

TEST_CASE("Multiply", "[mylib]")
{
    REQUIRE(mylib_multiply(2, 3) == 6);
    REQUIRE(mylib_multiply(-2, 3) == -6);
}

TEST_CASE("Divide", "[mylib]")
{
    REQUIRE(mylib_divide(6, 3) == 2);
    REQUIRE(mylib_divide(1, 0) == 0); // 除零返回0
}

```

### 总结：构建专业、可靠的 C++ 项目

回顾我们这一章的旅程，我们从为何需要自动化测试的讨论出发，最终抵达了一套完整、现代且高效的 C++ 测试工作流。这不仅仅是学习几个新的 CMake 命令，更是开发理念上的一次重要升级。

**我们掌握的核心要点可以归结为以下几点：**

1. **从`add_test`到测试发现的飞跃**：现代 CMake 测试的核心在于**测试发现**机制，通过 `gtest_discover_tests` (GTest) 或 `catch_discover_tests` (Catch2)，将每一个独立的测试用例（`TEST` 或 `TEST_CASE`）自动注册到 CTest，实现了精细化的管理。
2. **CTest 的真正威力**：只有在实现了测试发现后，CTest 作为测试驱动程序的能力才被完全释放。我们现在可以轻松地：
   - 通过 `ctest -R <regex>` 按名称运行特定测试。
   - 通过 `ctest -L <label>` 按标签筛选测试。
   - 通过 `ctest -j<N>` 并行执行测试以缩短时间。
   - 通过 `ctest --rerun-failed` 仅重跑失败的用例，极大提升调试效率。
3. **现代化的依赖管理**：我们深入探讨了处理像 GTest 和 Catch2 这类外部依赖的两种主流方案，它们各有优势：
   - **`FetchContent`**：将依赖作为项目构建的一部分，实现了项目的完全自包含。这对于开源库和需要极高移植性的项目是绝佳选择，保证了“克隆即可构建”的体验。
   - **`vcpkg`**：作为 C++ 包管理器，它将依赖的获取与编译过程同项目本身解耦。通过 `vcpkg.json` 清单和工具链，它能让 `CMakeLists.txt` 保持惊人的简洁，并利用二进制缓存加速本地开发，尤其适合团队内部的应用程序开发。
**最终，我们的目标是构建一个自动化、可靠且易于维护的质量保障体系。** 无论你选择 GTest 还是 Catch2，采用 `FetchContent` 还是 `vcpkg`，现代 CMake 都为我们提供了将这一切无缝整合的强大工具。
