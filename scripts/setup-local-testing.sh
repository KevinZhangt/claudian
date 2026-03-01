#!/bin/bash

# Setup Local Testing Script
# 快速设置本地开发环境

set -e

echo "🚀 Claudian 本地测试环境设置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查是否在项目根目录
if [ ! -f "package.json" ] || [ ! -f "manifest.json" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 选项
echo "请选择 vault 类型:"
echo "  1) 使用现有 vault"
echo "  2) 创建新的测试 vault"
echo ""
read -p "请选择 (1 或 2): " choice

case $choice in
    1)
        read -p "请输入 vault 路径: " VAULT_PATH
        VAULT_PATH="${VAULT_PATH/#\~/$HOME}"  # 展开 ~

        if [ ! -d "$VAULT_PATH" ]; then
            echo "❌ 错误: Vault 目录不存在: $VAULT_PATH"
            exit 1
        fi
        ;;
    2)
        VAULT_PATH="$HOME/ObsidianTest/TestVault"
        echo ""
        echo "📁 创建测试 vault: $VAULT_PATH"
        mkdir -p "$VAULT_PATH"

        # 创建基本的 .obsidian 目录
        mkdir -p "$VAULT_PATH/.obsidian"

        # 创建必要的 Obsidian 配置文件
        cat > "$VAULT_PATH/.obsidian/app.json" <<'APPJSON'
{
  "livePreview": true,
  "alwaysUpdateLinks": true,
  "showFrontmatter": false
}
APPJSON

        cat > "$VAULT_PATH/.obsidian/appearance.json" <<'APPEARJSON'
{
  "theme": "moonstone"
}
APPEARJSON

        cat > "$VAULT_PATH/.obsidian/community-plugins.json" <<'COMMJSON'
["claudian"]
COMMJSON

        cat > "$VAULT_PATH/.obsidian/core-plugins.json" <<'COREJSON'
[
  "file-explorer",
  "global-search",
  "switcher",
  "graph",
  "backlink",
  "outgoing-link",
  "tag-pane",
  "page-preview",
  "daily-notes",
  "templates",
  "note-composer",
  "command-palette",
  "editor-status",
  "markdown-importer",
  "word-count",
  "file-recovery"
]
COREJSON

        cat > "$VAULT_PATH/.obsidian/hotkeys.json" <<'HOTJSON'
{}
HOTJSON

        # 创建一个示例笔记
        cat > "$VAULT_PATH/Welcome.md" <<'MDEOF'
# Welcome to Claudian Test Vault

这是一个用于测试 Claudian 插件的 vault。

## 测试命令

可以在 Claudian 中测试以下命令：

```bash
python --version
node --version
brew --version
which python
echo $PATH
```

## Shell 环境测试

Claudian 的 shell-env-fix 补丁会自动加载：
- ~/.zshenv (zsh)
- ~/.bashrc (bash)

这样 AI 就能访问 pyenv、nvm、homebrew 等工具了。
MDEOF

        echo "✅ 测试 vault 创建成功"
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

# 配置 .env.local
echo ""
echo "📝 配置 .env.local..."
echo "OBSIDIAN_VAULT=$VAULT_PATH" > .env.local
echo "✅ 已配置: $VAULT_PATH"

# 检查依赖
echo ""
echo "📦 检查依赖..."
if [ ! -d "node_modules" ]; then
    echo "⚠️  node_modules 不存在，正在安装..."
    if command -v pnpm > /dev/null; then
        pnpm install
    else
        npm install
    fi
else
    echo "✅ 依赖已安装"
fi

# 创建插件目录
PLUGIN_DIR="$VAULT_PATH/.obsidian/plugins/claudian"
echo ""
echo "📂 准备插件目录..."
mkdir -p "$PLUGIN_DIR"
echo "✅ 插件目录: $PLUGIN_DIR"

# 构建一次
echo ""
echo "🔨 首次构建..."
if command -v pnpm > /dev/null; then
    pnpm run build
else
    npm run build
fi

# 复制文件
echo ""
echo "📋 复制文件到 vault..."
cp main.js manifest.json styles.css "$PLUGIN_DIR/"
echo "✅ 文件已复制"

# 显示下一步
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 设置完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Vault 路径: $VAULT_PATH"
echo "📍 插件路径: $PLUGIN_DIR"
echo ""
echo "🔄 下一步操作:"
echo ""
echo "1️⃣  启动开发模式（自动监听变化）:"
echo "   $ pnpm run dev"
echo ""
echo "2️⃣  打开 Obsidian:"
echo "   - 打开 vault: $VAULT_PATH"
echo "   - 进入: 设置 → 第三方插件"
echo "   - 关闭「安全模式」"
echo "   - 启用「Claudian」插件"
echo ""
echo "3️⃣  开发时重载插件:"
echo "   - Mac: Cmd + R"
echo "   - Windows/Linux: Ctrl + R"
echo "   - 或: Command Palette → Reload app without saving"
echo ""
echo "4️⃣  查看调试信息:"
echo "   - Mac: Cmd + Option + I"
echo "   - Windows/Linux: Ctrl + Shift + I"
echo ""
echo "📚 完整文档: dev/LOCAL_TESTING.md"
echo ""
echo "🎉 祝开发顺利！"
