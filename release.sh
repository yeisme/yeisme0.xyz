#!/bin/bash

# 使用方法: sh ./release.sh 25.3.3

# 设置版本号并验证格式
VERSION=$1
if [[ ! $VERSION =~ ^[0-9]{2}\.[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
    echo "错误：版本号格式必须为 YY.M.D (例如 25.3.3)"
    exit 1
fi

# 检查工作目录是否干净
if [[ -n $(git status --porcelain) ]]; then
    echo "错误：存在未提交的更改，请先提交或暂存"
    exit 1
fi

# 创建 Git 标签
echo "创建标签 v$VERSION..."
git tag -a "v${VERSION}" -m "Release version ${VERSION}"

# 推送代码和标签
echo "推送代码和标签到远程仓库..."
git push origin main --follow-tags

echo "创建 GitHub Release..."
gh release create "v${VERSION}" \
    --title "Version ${VERSION}"

echo "✅ 版本 $VERSION 已成功发布！"
echo "🔗 Release 地址: https://github.com/yeisme0/yeisme0.xyz/releases/tag/v${VERSION}"
