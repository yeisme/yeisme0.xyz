+++
title = "全自动 Hugo 博客容器化实践指南"
date = "2025-03-03T18:13:08+08:00"
description = ""
tags = []
categories = ["编程","DevOps","云原生"]
series = []
aliases = []
image = ""
draft = false
+++

# 全自动 Hugo 博客容器化实践指南

我的 Github 仓库: <https://github.com/yeisme/yeisme0.xyz>

## 3 个文件构建 Hugo 自动打包流程

1. Dockerfile: 自动化了 Hugo 项目的构建和运行过程
2. .github/workflows/docker-publish.yml: 自动打包容器镜像
3. release.sh: 脚本化 Git 上传

## 使用介绍

当我需要在我的服务器上启动我的博客服务时

```bash
docker pull ghcr.io/yeisme/yeisme0.xyz:latest
```

拉取最新镜像，再使用 k8s 等容器编排工具快速部署

## 为什么要使用 Github Action 构建自动化流程？

> 容器化技术的时代优势
> 在云原生与 DevOps 蓬勃发展的今天，容器化（Containerization）已成为现代应用部署的标准。相较于传统部署方式，容器化为个人博客建设带来了革命性优势。

> 跨云移植的无缝体验
> 避免被特定云厂商锁定，迁移成本大大降低！99 元服务器你值得拥有，甚至可以白嫖云厂商免费额度用来开始部署网站。

## 遇到的主要问题

- hugo 官方镜像不支持拓展？我找不到支持拓展的镜像。我需要手动构建一个支持拓展的镜像 yeisme0123/hugo:v1.0

```bash
$ docker run yeisme0123/hugo:v1.0 hugo version
hugo v0.145.0-666444f0a52132f9fec9f71cf25b441cc6a4f355+extended linux/amd64 BuildDate=2025-02-26T15:41:25Z VendorInfo=gohugoio
```
