#!/bin/bash

# Sync Upstream Script
# 手动同步上游 YishenTu/claudian 仓库的脚本

set -e

UPSTREAM_REPO="https://github.com/YishenTu/claudian.git"
UPSTREAM_REMOTE="upstream"

echo "🔄 Claudian Fork 同步工具"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查是否在 git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ 错误: 当前目录不是 git 仓库"
    exit 1
fi

# 检查工作目录是否干净
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  警告: 工作目录有未提交的变更"
    echo "请先提交或 stash 你的变更"
    git status --short
    exit 1
fi

# 添加上游 remote (如果不存在)
if ! git remote | grep -q "^${UPSTREAM_REMOTE}$"; then
    echo "➕ 添加上游 remote: $UPSTREAM_REPO"
    git remote add $UPSTREAM_REMOTE $UPSTREAM_REPO
else
    echo "✓ 上游 remote 已存在"
fi

# 获取上游更新
echo ""
echo "📥 获取上游更新..."
git fetch $UPSTREAM_REMOTE --tags

# 获取上游最新 tag
UPSTREAM_TAG=$(git describe --tags $(git rev-list --tags --max-count=1 $UPSTREAM_REMOTE/main) 2>/dev/null)
if [ -z "$UPSTREAM_TAG" ]; then
    echo "❌ 错误: 无法获取上游最新版本"
    exit 1
fi

# 获取本地最新 tag (排除 _fix 后缀)
LOCAL_TAG=$(git tag -l | grep -v "_fix" | grep -v "shell-env" | sort -V | tail -1)

echo ""
echo "📊 版本信息:"
echo "   上游最新版本: $UPSTREAM_TAG"
echo "   本地最新版本: $LOCAL_TAG"
echo ""

# 检查是否需要更新
if [ "$UPSTREAM_TAG" = "$LOCAL_TAG" ]; then
    echo "✅ 已是最新版本，无需同步"
    exit 0
fi

# 确认是否继续
read -p "是否继续同步? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 取消同步"
    exit 0
fi

# 创建备份分支
BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
echo ""
echo "💾 创建备份分支: $BACKUP_BRANCH"
git checkout -b $BACKUP_BRANCH
git push origin $BACKUP_BRANCH

# 回到 main 分支
git checkout main

# 合并上游变更
echo ""
echo "🔀 合并上游 main 分支..."
if git merge $UPSTREAM_REMOTE/main --no-edit; then
    echo "✅ 成功合并上游变更"
else
    echo "⚠️  检测到合并冲突"
    echo ""
    echo "冲突文件:"
    git status --short | grep "^UU"
    echo ""
    echo "请手动解决冲突后运行:"
    echo "  git add <resolved-files>"
    echo "  git commit"
    echo "  然后重新运行本脚本"
    exit 1
fi

# 检查补丁是否还存在
echo ""
echo "🔍 检查自定义补丁..."
if grep -q "loadShellEnvironment" src/utils/env.ts; then
    echo "✅ Shell-env-fix 补丁存在"
else
    echo "⚠️  警告: Shell-env-fix 补丁可能丢失"
    echo "请检查 src/utils/env.ts 文件"
fi

# 安装依赖
echo ""
echo "📦 安装依赖..."
if command -v pnpm > /dev/null; then
    pnpm install
elif command -v npm > /dev/null; then
    npm install
else
    echo "❌ 错误: 未找到 npm 或 pnpm"
    exit 1
fi

# 运行测试
echo ""
echo "🧪 运行测试..."
if command -v pnpm > /dev/null; then
    pnpm run test -- --selectProjects unit || echo "⚠️  警告: 部分测试失败"
else
    npm run test -- --selectProjects unit || echo "⚠️  警告: 部分测试失败"
fi

# 构建
echo ""
echo "🔨 构建项目..."
if command -v pnpm > /dev/null; then
    pnpm run build
else
    npm run build
fi

# 创建新版本
NEW_TAG="${UPSTREAM_TAG}_fix"
echo ""
echo "🏷️  创建新版本: $NEW_TAG"

# 更新版本号
if command -v pnpm > /dev/null; then
    npm version $NEW_TAG --no-git-tag-version
else
    npm version $NEW_TAG --no-git-tag-version
fi

git add package.json package-lock.json manifest.json
git commit -m "chore: bump version to $NEW_TAG (synced from upstream $UPSTREAM_TAG)"

# 创建 tag
git tag $NEW_TAG

# 显示变更
echo ""
echo "📝 变更摘要:"
git log --oneline ${LOCAL_TAG}..HEAD | head -10

# 确认推送
echo ""
read -p "是否推送到远程? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 未推送到远程"
    echo ""
    echo "稍后可以手动推送:"
    echo "  git push origin main"
    echo "  git push origin $NEW_TAG"
    exit 0
fi

# 推送
echo ""
echo "⬆️  推送到远程..."
git push origin main
git push origin $NEW_TAG

echo ""
echo "✅ 同步完成！"
echo ""
echo "📦 新版本: $NEW_TAG"
echo "🔗 Actions: https://github.com/KevinZhangt/claudian/actions"
echo "🔗 Release: https://github.com/KevinZhangt/claudian/releases/tag/$NEW_TAG"
echo ""
echo "GitHub Actions 将在几分钟后构建并发布新版本"
