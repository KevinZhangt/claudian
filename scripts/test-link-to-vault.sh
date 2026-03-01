#!/bin/bash

# 测试软连接：将 Claudian 插件链接到指定测试 vault
# 测试路径: /Users/kevin/ObsidianTest/TestVault

set -e

TEST_VAULT="/Users/kevin/ObsidianTest/TestVault"
PROJECT_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Claudian 软连接测试脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 步骤 1: 检查项目根目录
echo "步骤 1/5: 检查项目根目录"
if [ ! -f "$PROJECT_DIR/package.json" ] || [ ! -f "$PROJECT_DIR/manifest.json" ]; then
    echo "❌ 错误: 未在项目根目录找到 package.json/manifest.json"
    echo "   当前: $PROJECT_DIR"
    exit 1
fi
echo "   ✅ 项目目录: $PROJECT_DIR"
echo ""

# 步骤 2: 检查/创建测试 vault 目录
echo "步骤 2/5: 检查测试 vault 目录"
if [ ! -d "$TEST_VAULT" ]; then
    echo "   创建测试 vault: $TEST_VAULT"
    mkdir -p "$TEST_VAULT"
fi
echo "   ✅ 测试 vault: $TEST_VAULT"
echo ""

PLUGIN_DIR="$TEST_VAULT/.obsidian/plugins/claudian"

# 步骤 3: 处理已有插件目录
echo "步骤 3/5: 处理已有插件目录"
if [ -e "$PLUGIN_DIR" ]; then
    if [ -L "$PLUGIN_DIR" ]; then
        CURRENT_TARGET=$(readlink "$PLUGIN_DIR")
        if [ "$CURRENT_TARGET" = "$PROJECT_DIR" ]; then
            echo "   ✅ 软连接已存在且指向当前项目，跳过创建"
        else
            echo "   移除旧软连接: $PLUGIN_DIR -> $CURRENT_TARGET"
            rm "$PLUGIN_DIR"
        fi
    else
        echo "   移除已有插件目录（非软连接）: $PLUGIN_DIR"
        rm -rf "$PLUGIN_DIR"
    fi
else
    echo "   无现有插件目录，将新建"
fi
echo ""

# 步骤 4: 创建软连接
echo "步骤 4/5: 创建软连接"
if [ ! -L "$PLUGIN_DIR" ] || [ "$(readlink "$PLUGIN_DIR")" != "$PROJECT_DIR" ]; then
    mkdir -p "$(dirname "$PLUGIN_DIR")"
    ln -s "$PROJECT_DIR" "$PLUGIN_DIR"
    echo "   ✅ 已创建: $PLUGIN_DIR -> $PROJECT_DIR"
else
    echo "   ✅ 软连接已就绪"
fi
echo ""

# 步骤 5: 验证
echo "步骤 5/5: 验证"
echo "   连接: $(readlink "$PLUGIN_DIR")"
if [ -f "$PLUGIN_DIR/main.js" ] && [ -f "$PLUGIN_DIR/manifest.json" ]; then
    echo "   ✅ main.js, manifest.json 存在"
    ls -lh "$PLUGIN_DIR"/main.js "$PLUGIN_DIR"/manifest.json 2>/dev/null | sed 's/^/      /'
else
    echo "   ⚠️  构建文件缺失，请先执行: pnpm run build"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 测试软连接完成"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "测试步骤摘要:"
echo "  1. 在 Obsidian 中打开 vault: $TEST_VAULT"
echo "  2. 设置 -> 社区插件 -> 关闭安全模式 -> 启用 Claudian"
echo "  3. 开发时: pnpm run build 或 pnpm run dev，再在 Obsidian 中 Cmd+R 重载"
echo ""
