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
