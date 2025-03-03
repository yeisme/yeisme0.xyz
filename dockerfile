###############
# Build Stage #
###############
# 使用固定版本号避免意外更新
FROM yeisme0123/hugo:v1.0 AS builder

# 从环境变量中获取参数
ARG BINDING
ARG PORT

ENV BINDING=${BINDING}
ENV PORT=${PORT}

# 设置工作目录避免路径问题
WORKDIR /src

# 复制项目文件（已通过.dockerignore过滤）
COPY . .

# 执行构建命令
RUN hugo build --minify

# 暴露环境变量中的端口
EXPOSE ${PORT}

ENTRYPOINT ["sh", "-c", "hugo server --bind ${BINDING} --minify --port ${PORT}"]

# 运行命令
# docker build -t my-hugo-app .
# docker run -p 1313:1313 --env-file .env my-hugo-app
