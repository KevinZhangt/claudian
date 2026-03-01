# 自定义补丁管理

本 fork 维护以下自定义补丁，会在同步上游时自动重新应用。

## 当前补丁列表

### 1. Shell 环境变量加载修复 (shell-env-fix)

**文件**:
- `src/utils/env.ts`
- `src/core/agent/QueryOptionsBuilder.ts`
- `tests/unit/utils/env.test.ts`

**描述**:
自动加载用户 shell 配置文件 (~/.zshenv, ~/.bashrc) 中的环境变量，确保 AI 执行的命令可以访问 pyenv、nvm、homebrew 等工具。

**关键代码**:
```typescript
// src/utils/env.ts
export function loadShellEnvironment(): Record<string, string>

// src/core/agent/QueryOptionsBuilder.ts
const shellEnv = loadShellEnvironment();
env: {
  ...process.env,
  ...shellEnv,
  ...ctx.customEnv,
  PATH: ctx.enhancedPath,
}
```

**测试覆盖**:
- 8 个新增测试用例
- 测试脚本: `dev/test-shell-env.mjs`, `dev/test-bash-command.mjs`, `dev/test-restricted-env.mjs`

**影响范围**:
- ✅ 不改变上游功能
- ✅ 完全向后兼容
- ✅ 失败时静默降级

---

## 补丁维护指南

### 自动同步流程

1. **检测上游更新**:
   - GitHub Actions 每天自动检查上游 `YishenTu/claudian` 是否有新版本
   - 可以手动触发: Actions → Sync Upstream and Release → Run workflow

2. **合并上游变更**:
   - 自动合并上游的 main 分支
   - 如果有冲突，优先使用上游版本（关键文件除外）

3. **重新应用补丁**:
   - 检查补丁代码是否还存在
   - 如果丢失，发出警告并创建 issue

4. **测试和构建**:
   - 运行所有单元测试
   - 构建 main.js 和 styles.css

5. **发布新版本**:
   - 版本号格式: `<上游版本>_fix` (例如: `1.3.66_fix`)
   - 自动创建 GitHub Release
   - 用户可通过 BRAT 安装更新

### 手动同步步骤

如果自动同步失败，可以手动操作：

```bash
# 1. 添加上游 remote (首次)
git remote add upstream https://github.com/YishenTu/claudian.git

# 2. 获取上游更新
git fetch upstream --tags

# 3. 查看上游最新版本
git describe --tags $(git rev-list --tags --max-count=1 upstream/main)

# 4. 创建备份分支
git checkout -b backup-$(date +%Y%m%d)
git push origin backup-$(date +%Y%m%d)

# 5. 回到 main 分支并合并
git checkout main
git merge upstream/main

# 6. 解决冲突（如果有）
# 保留我们的补丁文件：
#   - src/utils/env.ts (loadShellEnvironment 函数)
#   - src/core/agent/QueryOptionsBuilder.ts (shellEnv 集成)
#   - tests/unit/utils/env.test.ts (测试用例)

# 7. 测试
pnpm install
pnpm run test -- --selectProjects unit
pnpm run build

# 8. 创建新版本
UPSTREAM_VERSION=$(git describe --tags $(git rev-list --tags --max-count=1 upstream/main))
npm version ${UPSTREAM_VERSION}_fix --no-git-tag-version
git add package.json package-lock.json manifest.json
git commit -m "chore: bump version to ${UPSTREAM_VERSION}_fix"
git tag ${UPSTREAM_VERSION}_fix

# 9. 推送
git push origin main
git push origin ${UPSTREAM_VERSION}_fix
```

### 添加新补丁

如果要添加新的自定义补丁：

1. **开发和测试**:
   ```bash
   # 创建特性分支
   git checkout -b feature/my-patch

   # 开发、测试
   pnpm run test
   pnpm run build

   # 提交
   git commit -m "feat: my custom patch"
   ```

2. **更新文档**:
   - 在本文件中添加新补丁的描述
   - 说明补丁的目的、影响范围、测试覆盖

3. **合并到 main**:
   ```bash
   git checkout main
   git merge feature/my-patch
   git push origin main
   ```

4. **更新同步脚本**:
   - 如果新补丁可能在合并时冲突，更新 `.github/workflows/sync-upstream.yml`
   - 添加自动检测和重新应用的逻辑

### 版本号规则

- **上游版本**: `1.3.66`, `1.3.67`, ...
- **我们的版本**: `1.3.66_fix`, `1.3.67_fix`, ...
- **特殊版本**: `1.3.68` (纯上游版本，临时测试用)

### 回滚步骤

如果发现同步后有问题：

```bash
# 1. 查看最近的 tags
git tag -l | tail -5

# 2. 回滚到上一个稳定版本
git reset --hard <previous-tag>

# 3. 强制推送 (谨慎使用)
git push origin main --force
git push origin :refs/tags/<problematic-tag>  # 删除问题 tag
```

---

## 监控和维护

### 自动化检查

- ✅ 每天 10:00 和 22:00 (北京时间) 自动检查上游更新
- ✅ 同步失败时自动创建 issue
- ✅ 可以通过 workflow_dispatch 手动触发

### 手动检查

定期检查以下内容：

1. **Actions 状态**: https://github.com/KevinZhangt/claudian/actions
2. **Issue 列表**: 查看是否有自动创建的同步失败 issue
3. **Release 页面**: 确认版本号和构建产物正确
4. **测试结果**: 确保所有测试通过

### Slack 通知 (可选)

如果设置了 `SLACK_WEBHOOK_URL` secret，会在成功同步时发送通知。

---

## 常见问题

### Q: 同步后补丁丢失怎么办？

A:
1. 检查 Actions 日志中的警告信息
2. 从备份分支或最近的 commit 恢复补丁
3. 手动应用补丁并推送

### Q: 如何临时禁用自动同步？

A:
1. 进入 Actions 页面
2. 选择 "Sync Upstream and Release" workflow
3. 点击右上角的 "..." → Disable workflow

### Q: 版本号冲突怎么办？

A:
使用 `_fix` 后缀避免与上游版本号冲突。如果仍然冲突，可以使用 `_fix2`, `_fix3` 等。

---

## 联系方式

如有问题或建议，请创建 issue 或联系维护者。
