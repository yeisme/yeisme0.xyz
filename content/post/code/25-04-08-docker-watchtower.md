+++
title = "Docker Watchtower 容器自动更新"
date = "2025-04-08T16:39:36+08:00"
description = ""
tags = ["DevOps","云原生","Docker"]
categories = ["编程"]
series = []
aliases = []
image = ""
draft = false
+++

# Docker Watchtower 容器自动更新

在开发和维护基于容器的应用程序时，我们经常需要处理镜像更新的问题。对于个人博客这样的项目，流程通常是：编写内容、推送到 GitHub、通过 GitHub Actions 构建新镜像，然后手动登录服务器执行 docker pull 命令来更新容器。

## 为什么需要自动更新容器？

如果你和我一样经常更新博客，那么你可能会遇到以下问题：

1. 每次内容更新后，都需要 SSH 到服务器上
2. 手动执行 docker pull ghcr.io/yeisme/yeisme0.xyz:latest 拉取最新镜像
3. 停止并删除当前运行的容器
4. 使用新镜像启动新容器
5. 测试确认更新成功

我真的受够了，我想再不解决这个问题，写 blog 的热情都被磨灭了，为了解决这个问题，找一个自动化容器更新的软件就很有必要了

## 为什么选择 Watchtower？是 GitOps 不香吗？

Watchtower 是一个可以自动更新 Docker 容器的应用程序（轮询）。它监视运行中的容器，并在检测到容器镜像有更新时，自动拉取新镜像并使用相同的参数重新启动容器。

当然，GitOps 是一种更现代的方法，它通过 Git 仓库作为单一事实来源来管理基础设施和应用部署。使用 ArgoCD 或 Flux 这样的工具，你可以实现更复杂的部署策略。但是对于我的个人博客这样的小型项目，GitOps 可能有点"杀鸡用牛刀"：

Watchtower 提供了一个简单有效的解决方案，它和 Docker 无缝集成，几乎不需要额外配置，特别适合个人项目。

## docker-compose 案例

```yaml
version: '3'
services:
  blog:
    container_name: my-blog
    image: ghcr.io/yeisme/yeisme0.xyz:latest
    restart: unless-stopped
    ports:
      - '80:80'

  watchtower:
    container_name: watchtower
    image: containrrr/watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_POLL_INTERVAL=21600 # 每 6 小时（21600 秒）检查一次更新
    command: my-blog
```

几点说明：

1. 共有仓库，没有 docker 认证
2. 缺乏一些企业级功能（如高级部署策略和自动回滚），但对于大多数小型项目来说，这些限制并不是问题
3. 没有通知

> 又是制造赛博垃圾的一天
