+++
title = "使用 CMake Preset 优化构建 llama.cpp"
date = "2025-05-24T18:25:16+08:00"
description = "深入探讨如何通过 CMake User Preset 针对特定硬件环境优化构建 llama.cpp，实现体积精简和性能提升"
tags = ["CMake", "llama.cpp", "CUDA", "构建优化", "本地编译"]
categories = ["编程"]
aliases = []
image = "image.png"
draft = false
+++

# 使用 CMake Preset 优化构建 llama.cpp

## 引言

在如今这个大模型风靡的时代，llama.cpp 凭借其轻量级、支持本地推理的特性，成为了很多开发者的本地开发首选工具。它让许多开发者和爱好者能够在自己的设备上运行强大的语言模型。然而，官方提供的预编译版本，为了照顾到最广泛的硬件兼容性，往往像一个臃肿的“全家桶”，塞满了各种我们可能永远用不到的依赖库。结果就是动辄数百 MB 的体积，并且难以完全释放我们特定硬件的潜力。

你是否也曾看着那 800+MB 的发行包叹气，明知自己的机器用不上其中大部分组件？对于普通用户来说，这是没办法的，但作为一名开发者，我们是不是有更多的选择呢？本文将带你踏上一段优化之旅，通过 CMake User Preset 对 llama.cpp 进行精细的本地化构建，并在此过程中榨干硬件性能。

## 为什么选择本地构建？

### 预编译包的通病：为兼容性妥协

社区版本追求普适性，这固然是优点，但也意味着：

- 需要兼容各种古老或小众的操作系统版本。
- 必须支持琳琅满目的硬件配置。
- 动态库的链接和分发策略偏向保守。

> 可以说 llama.cpp

这种“防御性”的依赖包含，导致了大量在特定用户环境中完全冗余的代码和库。本地构建则让我们卸下这些包袱，轻装上阵。

举个例子，我的目标平台是 RTX 3060 显卡 + Windows 系统 + MSVC 编译器，那么我就只需要针对这个组合进行构建，其他多余的架构和库都可以砍掉。

通过本地构建，我们可以像经验丰富的裁缝一样，精确裁剪每一处依赖，只保留当前环境真正需要的库文件。这对于资源敏感的应用场景，或是希望保持开发环境清爽的开发者来说，至关重要。

### 远不止瘦身这么简单

预编译版本通常采用相对保守的编译选项。本地构建则允许我们“火力全开”，启用针对特定硬件的激进优化选项：

```cmake
# 示例：针对特定 CPU 架构的优化 (MSVC 编译器)
CMAKE_CXX_FLAGS="/O2 /arch:AVX512 /openmp" # /O2 优化等级, 启用 AVX512, OpenMP 支持

# 示例：针对特定 CUDA 架构的优化
CMAKE_CUDA_ARCHITECTURES="86" # 例如 NVIDIA Ada Lovelace 架构
```

具体需要什么优化选项，大家需要根据自己的 CPU 进行选择（自己查考 CPU 相关文档，我的是 11th Gen Intel(R) Core(TM) i5-11260H (12) @ 4.40 GHz，可以启用 AVX512）

## CMake User Preset：定制你的构建流程

> 官方构建参考
> <https://github.com/ggml-org/llama.cpp/blob/master/.github/workflows/build.yml>

CMake Presets (CMakePresets.json 和 CMakeUserPresets.json) 是允许开发者将常用的配置选项、环境变量、缓存变量等固化下来，极大简化了构建配置过程。CMakeUserPresets.json 尤其适合存放本地特定的、不应提交到版本控制的配置。

以下是一个针对特定环境（Windows, MSVC, CUDA 12.x, RTX 30 系列显卡, vcpkg 管理依赖）的 CMakeUserPresets.json 示例：

也不吊着大家了，直接展示案例

```json
{
  "version": 4,
  "configurePresets": [
    {
      "name": "vcpkg-x64-windows",
      "hidden": false,
      "environment": {
        "CURL_ROOT": "C:/Users/yeisme/scoop/apps/vcpkg/current/installed/x64-windows",
        "CURL_LIBRARY": "C:/Users/yeisme/scoop/apps/vcpkg/current/installed/x64-windows/lib/libcurl.lib",
        "GGML_CUDA_FORCE_MMQ": "1",
        "GGML_CUDA_FORCE_CUBLAS": "1"
      },
      "cacheVariables": {
        "CMAKE_TOOLCHAIN_FILE": "$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake",
        "LLAMA_CUDA": "ON",
        "CMAKE_CUDA_ARCHITECTURES": "80",
        "CMAKE_C_COMPILER": "cl",
        "CMAKE_CXX_COMPILER": "cl",
        "LLAMA_CURL": "ON",
        "CMAKE_CXX_FLAGS": "/wd4267 /wd4244 /GL /O2 /Ob2 /DNDEBUG /favor:INTEL64 /arch:AVX2",
        "CMAKE_EXE_LINKER_FLAGS": "/LTCG /OPT:REF /OPT:ICF",
        "CURL_ROOT": "$env{CURL_ROOT}",
        "CURL_LIBRARY": "$env{CURL_LIBRARY}",
        "GGML_CUDA_FORCE_MMQ": "ON",
        "GGML_CUDA_FORCE_CUBLAS": "ON",
        "LLAMA_NATIVE": "ON",
        "GGML_CUDA": "ON",
        "LLAMA_METAL": "OFF",
        "LLAMA_BUILD_TESTS": "OFF",
        "LLAMA_BUILD_EXAMPLES": "ON",
        "LLAMA_BUILD_SERVER": "ON",
        "BUILD_SHARED_LIBS": "ON",
        "LLAMA_RPC": "ON",
        "CMAKE_INTERPROCEDURAL_OPTIMIZATION": "ON"
      },
      "inherits": ["x64-windows-msvc-debug"],
      "generator": "Ninja Multi-Config"
    }
  ],
  "buildPresets": [
    {
      "name": "vcpkg-x64-windows-Release",
      "hidden": false,
      "configurePreset": "vcpkg-x64-windows",
      "configuration": "Release"
    }
  ]
}
```

## 配置解析

### 编译器优化选项详解

在上面的配置中，我们使用了一系列激进的编译器优化选项，让我们逐一分析：

```cmake
CMAKE_CXX_FLAGS="/wd4267 /wd4244 /GL /O2 /Ob2 /DNDEBUG /favor:INTEL64 /arch:AVX2"
CMAKE_EXE_LINKER_FLAGS="/LTCG /OPT:REF /OPT:ICF"
```

- `/GL`: 启用全程序优化 (Whole Program Optimization)
- `/O2`: 最大化速度优化
- `/Ob2`: 内联函数展开
- `/DNDEBUG`: 禁用调试断言，减少运行时检查
- `/favor:INTEL64`: 针对 64 位 Intel 处理器优化
- `/arch:AVX2`: 启用 AVX2 指令集
- `/LTCG`: 链接时代码生成
- `/OPT:REF`: 移除未引用的函数和数据
- `/OPT:ICF`: 启用相同 COMDAT 折叠

### CUDA 特定优化

```cmake
CMAKE_CUDA_ARCHITECTURES="80"  # RTX 30 系列对应 Ampere 架构
GGML_CUDA_FORCE_MMQ="ON"       # 强制使用矩阵乘法量化
GGML_CUDA_FORCE_CUBLAS="ON"    # 强制使用 cuBLAS
```

这里的架构代码对应关系：

- `75`: RTX 20 系列 (Turing)
- `80`: RTX 30 系列 (Ampere)
- `89`: RTX 40 系列 (Ada Lovelace)

## 构建实战

### 执行构建

```powershell
# 克隆仓库
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp

# 创建 CMakeUserPresets.json 文件
# (将上面的配置保存到文件中)

# 配置构建
cmake --preset vcpkg-x64-windows

# 开始构建
cmake --build --preset vcpkg-x64-windows-Release
```

## 总结

通过 CMake User Preset 进行本地化构建，我们不仅能大幅削减 llama.cpp 的体积，更能根据自己的硬件环境进行深度优化，榨干每一分性能。这不仅仅是一次编译配置的调整，更是一种理解软件构建、拥抱开源定制精神的实践。 （太尬了，编不下去了）😢
