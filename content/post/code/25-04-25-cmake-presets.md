+++
title = "Cmake 预设"
date = "2025-04-25T15:26:16+08:00"
description = ""
tags = ["C++","CMake"]
categories = ["编程"]
series = []
aliases = ["CMake Presets"]
image = ""
draft = false
+++

# Cmake 预设

## 引言：你不一定了解的现代 cmake 预设

在本篇博客中，我们将：

1. Cmake 预设
  1. 引言：你不一定了解的现代 cmake 预设
  2. 什么是 cmake 预设？
  3. CMake 预设文件的结构
  4. 五种预设类型详解
    1. configurePresets
    2. buildPresets
    3. testPresets
    4. packagePresets
    5. workflowPresets
  5. 用户预设 (CMakeUserPresets.json)
  6. 总结

## 什么是 cmake 预设？

> CMake 预设是 CMake 3.19 引入的功能，用于通过 JSON 文件定义标准或重复的构建设置，如构建目录、生成器和缓存变量。这有助于简化复杂项目的配置管理，特别适合持续集成（CI）构建或频繁的开发环境。
> [cmake-presets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)

随着项目规模的增长，CMake 配置脚本往往会变得越来越庞大、参数越来越多。我们可能需要：

- 在不同构建类型（Debug/Release）之间切换
- 针对不同平台（Windows/Linux/macOS）指定不同的编译器和工具链
- 在本地与 CI 环境中使用各自的配置选项

这些配置在 CMakeLists.txt 文件中，当然也可以，更好的方式当然是抽离出来为一个 module 放在 cmake/ 目录下，但是认真好学、善于观察的你肯定发现了，这样会导致 cmake 文件结构过于冗余，并且导致脚本文件难以管理。CMake 预设正是为了解决这些问题而诞生的。它提供了一种声明式的方式来定义构建配置，使得构建过程更加清晰、可维护和可移植。

CMake 预设帮你把这些配置抽离到 JSON 文件中，只需用 `cmake --preset <name>` 一行命令即可完成相同操作。

接下来，以 https://github.com/yeisme/cmake_template/tree/main/vcpkg_base 为例，讲解 cmake 预设使用，你可以拉取这个 git 项目到本地，使用 VSCode 或者其他 IDE 的 cmake 功能进行测试。

## CMake 预设文件的结构

`CMakePresets.json` 位于项目根目录，用来向团队共享“配置预设”。典型结构如下：

```json
{
  "version": 10,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 19,
    "patch": 0
  },
  "configurePresets": [ /* 配置预设 */ ],
  "buildPresets":     [ /* 构建预设 */ ],
  "testPresets":      [ /* 测试预设 */ ],
  "packagePresets":   [ /* 打包预设 */ ],
  "workflowPresets"   [ /* 工作流预设 */],
}
```

- `version`：预设文件版本号，指定版本 10 或更高版本的预设文件可以添加注释，C 风格。
- `cmakeMinimumRequired`：指定支持预设的最低 CMake 版本。

## 五种预设类型详解

### configurePresets

定义如何调用 `cmake -S . -B <buildDir>`。

字段说明：

- `name` (string)：预设唯一标识，用于 `--preset`。
- `displayName` (string, 可选)：可读名称，帮助识别。
- `description` (string, 可选)：预设用途说明。
- `generator` (string)：CMake 生成器，如 `"Ninja"`、`"Unix Makefiles"`。
- `binaryDir` (string)：构建目录路径。
- `cacheVariables` (object)：等价于命令行 `-D` 选项。
- `inherit` (array, 可选)：继承其他预设，按顺序覆盖，可以多重继承。
- `hidden` (bool, 可选)：是否在 `--list-presets` 时隐藏，通常在 IDE 中也支持是否隐藏。

使用 `cmake --list-presets` 查看所有 configure 预设

{{< figure src="configure1.png" alt="configure1" >}}

> msvc 案例

```json
{
  "name": "msvc-debug-x64",
  "displayName": "MSVC debug x64",
  "generator": "Ninja",
  "inherits": [
      "msvc-base",
      "debug"
  ],
  "vendor": {
      "microsoft.com/VisualStudioSettings/CMake/1.0": {
          "hostOS": [
              "Windows"
          ]
      }
  },
  "hidden": false
},
```

> IDE 支持

{{< figure src="configure2.png" alt="configure2" >}}

### buildPresets

封装 `cmake --build <buildDir>` 调用：

- `name` (string)：预设名。  
- `configurePreset` (string)：关联的 `configurePresets`。  
- `configuration` (string, 可选)：多配置生成器下的配置，如 `"Debug"`。  
- `jobs` (number or string, 可选)：并行级别，等价 `-j`。  
- `install` (bool, 可选)：是否执行 `--target install`。  
- `hidden`、`description` 同前。

示例：

```jsonc
"buildPresets": [
  {
      "name": "clang-release-x64",
      "displayName": "Clang release",
      "configurePreset": "clang-release-x64",
      "hidden": false
  },
]
```

{{< figure src="buildPresets1.png" alt="buildPresets1" >}}

### testPresets

封装调用 `ctest` 及相关参数：

- `name` (string)  
- `configurePreset` (string)  
- `configuration` (string, 可选)  
- `extraArgs` (array, 可选)：指定 ctest 参数，如 `["--output-on-failure"]`。  
- `enableCoverage` (bool, 可选)：是否生成覆盖率报告。

示例：

```jsonc
"testPresets": [
  {
    "name": "test-debug",
    "configurePreset": "debug",
    "configuration": "Debug",
    "extraArgs": ["--output-on-failure"]
  }
]
```

{{< figure src="testPresets1.png" alt="testPresets1" >}}

### packagePresets

> 暂时缺少测试，缺图。

从 schema version 6 开始支持，用于封装打包（CPack 或 cmake --build --target package）。

主要字段：

- `name` (string)：预设标识，用于 `cpack --preset`。  
- `displayName` / `description`：可读名称与说明。  
- `hidden`：隐藏预设，不可直接调用，可供继承。  
- `inherits`：继承其他 package 预设。  
- `condition`：可选条件对象，用于动态启用。  
- `vendor`：自定义厂商字段，不被 CMake 解释。  
- `environment`：环境变量映射，可引用 `$env{}`。  
- `configurePreset`：关联配置预设，用于推断 `binaryDir`。  
- `inheritConfigureEnvironment`：是否继承配置预设的环境，默认 `true`。  
- `generators`：CPack 打包格式数组，如 `["TGZ","ZIP"]`。  
- `configurations`：多配置下的构建类型数组。  
- `variables`：传给 CPack 的 `-D` 变量映射。  
- `configFile`：CPack 配置文件路径。  
- `output`：输出控制对象，包含：
  - `debug` / `verbose` (bool)  
  - `packageName` / `packageVersion` / `packageDirectory` / `vendorName`

示例：

```jsonc
"packagePresets": [
  {
    "name": "package-debug",
    "displayName": "Debug Package",
    "description": "生成 Debug 版本的 TGZ 和 ZIP 包",
    "configurePreset": "debug",
    "inheritConfigureEnvironment": true,
    "generators": ["TGZ", "ZIP"],
    "variables": {
      "CPACK_PACKAGE_CONTACT": "dev@example.com"
    },
    "configFile": "${sourceDir}/CPackConfig.cmake",
    "output": {
      "verbose": true,
      "packageDirectory": "${sourceDir}/dist",
      "packageName": "MyApp-${CMAKE_PROJECT_VERSION}"
    }
  }
]
```

### workflowPresets

workflowPresets 是 CMake 3.20 版本引入的功能，它将多个预设（配置、构建、测试、包）组合成一个工作流。可用于 CI/IDE 中统一工作流。

```jsonc
"workflowPresets": [
    {
        "name": "clang-dev-x64-workflow",
        "displayName": "clang dev x64 workflow",
        "steps": [
            {
                "type": "configure",
                "name": "clang-debug-x64"
            },
            {
                "type": "build",
                "name": "clang-debug-x64"
            },
            {
                "type": "test",
                "name": "clang-debug-x64-test"
            }
        ]
    },
    {
        "name": "clang-release-x64-workflow",
        "displayName": "clang release x64 workflow",
        "steps": [
            {
                "type": "configure",
                "name": "clang-release-x64"
            },
            {
                "type": "build",
                "name": "clang-release-x64"
            },
            {
                "type": "test",
                "name": "clang-release-x64-test"
            }
        ]
    }
]
```

```bash
$ cmake --workflow --list-presets
Available workflow presets:

  "clang-dev-x64-workflow"     - clang dev x64 workflow
  "clang-release-x64-workflow" - clang release x64 workflow
```

## 用户预设 (CMakeUserPresets.json)

除了 CMakePresets.json，CMake 还支持 CMakeUserPresets.json 文件。这个文件与 CMakePresets.json 具有相同的结构，但它位于项目的构建目录中。CMakeUserPresets.json 的主要目的是允许用户定义本地特定的预设，这些预设不会提交到版本控制系统，因此不会影响团队的其他成员。

用户预设可以覆盖或扩展 CMakePresets.json 中定义的预设。如果 CMakeUserPresets.json 中存在与 CMakePresets.json 中同名的预设，则用户预设的定义会优先使用。

## 总结

在 vcpkg_base 示例仓库中引入 CMake 预设之后，我们的实践心得如下：

- 快速上手：  
  利用团队共享的 `CMakePresets.json`，新成员无需记忆繁琐命令，只需执行 `cmake --preset` 即可完成 configure 和 build，极大降低了项目入门门槛，使用 IDE 进一步降低门槛。

- 灵活继承与覆盖：  
  通过 `inherits` 将公共设置提取到基础预设，并在不同平台或环境的子预设中覆盖少量字段，实现 DRY（Don't Repeat Yourself）原则。

- 团队/个人分离：  
  把共享预设放在受控的 `CMakePresets.json` 中，而把个人实验性或临时性预设放在 `CMakeUserPresets.json` 并加入 `.gitignore`，既保证团队一致性，又方便个人调试。

- CI 流程简化：  
  在 GitHub Actions 等 CI 平台上，只需调用：  
  ```bash
  cmake --preset release
  cmake --build --preset build-release
  ctest --preset test-debug
  cpack --preset package-debug
  ```  
  替代复杂的命令行拼接，脚本更简洁、可读性更高。

- 常见坑及建议：  
  预设文件中的 version 要高于 10才能添加注释，不然会报错。
