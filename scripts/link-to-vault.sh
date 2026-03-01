#!/bin/bash

# Link Plugin to Vault
# 创建项目目录到 vault 的软连接

set -e

echo "🔗 Claudian 插件软连接工具"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查是否在项目根目录
if [ ! -f "package.json" ] || [ ! -f "manifest.json" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

PROJECT_DIR="$(pwd)"

# 从 .env.local 读取 vault 路径，或者提示输入
if [ -f ".env.local" ]; then
    VAULT_PATH=$(grep "OBSIDIAN_VAULT=" .env.local | cut -d'=' -f2)
    VAULT_PATH="${VAULT_PATH/#\~/$HOME}"  # 展开 ~
fi

if [ -z "$VAULT_PATH" ]; then
    read -p "请输入 vault 路径: " VAULT_PATH
    VAULT_PATH="${VAULT_PATH/#\~/$HOME}"
fi

if [ ! -d "$VAULT_PATH" ]; then
    echo "❌ 错误: Vault 目录不存在: $VAULT_PATH"
    exit 1
fi

PLUGIN_DIR="$VAULT_PATH/.obsidian/plugins/claudian"

# 检查现有的插件目录
if [ -e "$PLUGIN_DIR" ]; then
    if [ -L "$PLUGIN_DIR" ]; then
        CURRENT_TARGET=$(readlink "$PLUGIN_DIR")
        if [ "$CURRENT_TARGET" = "$PROJECT_DIR" ]; then
            echo "✅ 软连接已存在且正确"
            echo "   $PLUGIN_DIR -> $PROJECT_DIR"
            exit 0
        else
            echo "⚠️  发现软连接指向其他位置:"
            echo "   当前: $PLUGIN_DIR -> $CURRENT_TARGET"
            echo "   期望: $PLUGIN_DIR -> $PROJECT_DIR"
            read -p "是否更新? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
            rm "$PLUGIN_DIR"
        fi
    else
        echo "⚠️  发现插件目录（非软连接）"
        echo "   路径: $PLUGIN_DIR"
        read -p "是否删除并创建软连接? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
        rm -rf "$PLUGIN_DIR"
    fi
fi

# 创建父目录
mkdir -p "$(dirname "$PLUGIN_DIR")"

# 创建软连接
ln -s "$PROJECT_DIR" "$PLUGIN_DIR"

echo ""
echo "✅ 软连接创建成功！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 连接详情:"
echo "   源目录: $PROJECT_DIR"
echo "   目标位置: $PLUGIN_DIR"
echo ""
echo "🔍 验证文件:"
ls -lh "$PLUGIN_DIR"/{main.js,manifest.json,styles.css} 2>/dev/null || {
    echo "⚠️  构建文件不存在，请先构建:"
    echo "   $ pnpm run build"
}
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 使用说明:"
echo ""
echo "使用软连接后:"
echo "  1. 无需 pnpm run dev（构建后自动生效）"
echo "  2. 运行 pnpm run build 构建"
echo "  3. 在 Obsidian 中 Cmd+R 重载插件"
echo ""
echo "开发工作流:"
echo "  $ pnpm run build     # 构建插件"
echo "  # 在 Obsidian 中按 Cmd+R 重载"
echo "  # 重复..."
echo ""
echo "或使用 watch 模式:"
echo "  $ pnpm run dev       # 自动构建（推荐）"
echo "  # 在 Obsidian 中按 Cmd+R 重载"
echo ""
echo "💡 提示: 软连接模式下，esbuild 的自动复制功能无需启用"
echo "   构建后文件直接出现在 vault 中！"
echo ""
