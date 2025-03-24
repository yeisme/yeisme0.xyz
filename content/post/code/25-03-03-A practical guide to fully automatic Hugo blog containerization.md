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

## 介绍

在当今数字化浪潮中，个人博客不仅是展示自我的窗口，更是技术交流与知识分享的重要平台。作为一名技术爱好者，我深知构建一个高效、稳定且易于维护的博客系统的重要性。Hugo，作为一款静态网站生成器，凭借其快速的渲染速度和丰富的扩展性，成为了众多博主的首选。而容器化技术的兴起，为Hugo博客的部署和管理带来了全新的可能。今天，就让我们一同探索全自动 Hugo 博客容器化实践的奥秘。

我的 Github 仓库: <https://github.com/yeisme/yeisme0.xyz>

写博客什么最重要？

## 3 个文件构建 Hugo 自动打包流程

1. Dockerfile: 自动化了 Hugo 项目的构建和运行过程
2. .github/workflows/docker-publish.yml: 自动打包容器镜像
3. release.sh: 脚本化 Git 上传

- Dockerfile

```Dockerfile
###############
# Build Stage #
###############
# 使用固定版本号避免意外更新
FROM yeisme0123/hugo:v1.0 AS builder

# 从环境变量中获取参数
ARG BINDING
ARG PORT=80

ENV BINDING=${BINDING}
ENV PORT=${PORT}

# 设置工作目录避免路径问题
WORKDIR /src

# 复制项目文件（已通过.dockerignore过滤）
COPY . .

# 执行构建命令
RUN hugo build --minify && \
    # 优化：移除不必要的文件
    find public -name '*.map' -delete

###############
# Final Stage #
###############
FROM caddy:2-alpine AS runner

# 添加元数据标签
LABEL maintainer="1304192594@qq.com"
LABEL description="个人博客网站使用Hugo生成"
LABEL version="1.0"

# 设置工作目录
WORKDIR /usr/share/caddy

# 复制简单的 Caddy 配置文件
COPY Caddyfile /etc/caddy/Caddyfile

# 复制构建结果
COPY --from=builder /src/public .

# 暴露端口（注意 Caddy 默认监听端口为 80，可通过环境变量 PORT 修改）
EXPOSE ${PORT}

# 启动命令，使用 Caddyfile 配置启动
ENTRYPOINT ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
```

在构建阶段，我使用自定义的 Hugo 镜像 yeisme0123/hugo:v1.0，这是因为在实践中发现官方 Hugo 镜像不支持拓展，要是有读者知道使用那个镜像，可以评论告诉我。

选择 Caddy 作为静态文件服务器。Caddy 的轻量级和易用性使其成为部署静态网站的理想选择。通过复制构建结果和简单的 Caddy 配置文件，我们能够快速搭建一个高效、稳定的博客服务。Caddyfile只需要最基础的功能。

```
:80 {
    root * /usr/share/caddy
    file_server
    # 健康检查路由
    respond /health "OK"
}
```

---

- GitHub Action

GitHub Action 为我们提供了一个强大的自动化工作流平台。通过配置 .github/workflows/docker-publish.yml 文件，我们能够实现当发布新的 release 时，自动触发构建和推送容器镜像的流程。

在这个工作流中，我们首先检出代码，然后登录到 GitHub Container Registry (GHCR)，最后使用 docker/build-push-action@v5 动作进行镜像的构建和推送。通过设置镜像标签为 latest 和当前提交的 Git 哈希值，我们既能方便地获取最新版本，又能追溯到具体的代码提交。


```yaml
name: Docker Build and Push

on:
  release:
    types:
      - published  # 当发布新的 release 时触发
  workflow_dispatch:
    inputs:
      custom_tag:
        description: '自定义镜像标签 (留空则使用默认)'
        required: false
        default: 'manual'
      skip_push:
        description: '跳过推送镜像'
        required: false
        default: 'false'

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: |
            ghcr.io/${{ github.repository_owner }}/yeisme0.xyz:latest
            ghcr.io/${{ github.repository_owner }}/yeisme0.xyz:${{ github.sha }}

```



## 使用介绍

当我需要在我的服务器上启动我的博客服务时

```bash
docker pull ghcr.io/yeisme/yeisme0.xyz:latest
```

拉取最新镜像，再使用 k8s 等容器编排工具快速部署

然后，可以使用 k8s 等容器编排工具进行快速部署。这种容器化的方式，不仅使得部署过程变得简单高效，而且能够轻松实现服务的扩展和迁移。
222
## 为什么要使用 Github Action 构建自动化流程？

> 容器化技术的时代优势
> 在云原生与 DevOps 蓬勃发展的今天，容器化已成为现代应用部署的标准。相较于传统部署方式，容器化为个人博客建设带来了革命性优势。
> 容器化技术能够将应用及其依赖打包成一个标准化的单元，确保在不同环境中的行为一致性。这意味着，无论是在本地开发环境、测试环境还是生产服务器，博客都能以相同的方式运行，避免了“在我的机器上可以运行”的尴尬。

> 跨云移植的无缝体验
>  跨云移植的无缝体验 采用容器化部署，能够避免被特定云厂商锁定，大大降低迁移成本。如今，许多云厂商都提供了免费额度或低价服务器，如 99 元服务器，甚至可以通过申请免费额度来开始部署网站。这种灵活性使得我们能够根据自身需求和预算，自由选择和切换云服务提供商。

## 遇到的主要问题

- hugo 官方镜像不支持拓展？我找不到支持拓展的镜像。我需要手动构建一个支持拓展的镜像 yeisme0123/hugo:v1.0

```bash
$ docker run yeisme0123/hugo:v1.0 hugo version
hugo v0.145.0-666444f0a52132f9fec9f71cf25b441cc6a4f355+extended linux/amd64 BuildDate=2025-02-26T15:41:25Z VendorInfo=gohugoio
```
