###############
# Build Stage #
###############
# 使用固定版本号避免意外更新
FROM yeisme0123/hugo:v1.0 AS builder

# 参数化构建配置，提高灵活性
ENV PORT=1313

# 设置工作目录避免路径问题
WORKDIR /src

# 复制项目文件（已通过.dockerignore过滤）
COPY . .

# 执行构建命令
RUN hugo build --minify

# 暴露环境变量中的端口
EXPOSE ${PORT}

ENTRYPOINT ["sh", "-c", "hugo server --bind 0.0.0.0 --minify --port ${PORT}"]
