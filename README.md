# ysm-native-build

在 **GitHub 托管的 Windows runner** 上构建 YSM 的 native 库（`ysm.dll`），
产物用于打进模组 JAR，使玩家在 Windows 10 上开箱即用（无需任何额外配置）。

- 构建对象：公开仓库 [`YesSteveModel/YesSteveModel-Native`](https://github.com/YesSteveModel/YesSteveModel-Native)
- 本仓库**不包含任何私有源码**，只有一个 CI 工作流
- 产物：`ysm-windows-dll`（artifact，内含 `ysm.dll`）与 `build-logs`（构建日志）

## 工作流文件位置

GitHub 只识别 `.github/workflows/` 下的文件。本仓库的 `workflow/build-windows.yml`
是同一份内容的副本，便于在网页端复制到正确位置：

1. 打开 <https://github.com/EVFBV/ysm-native-build/new/main/.github/workflows>
2. 文件名填 `build-windows.yml`
3. 把 `workflow/build-windows.yml` 的内容整段粘贴进去，提交

提交后 Actions 会自动开始构建（也可在 Actions 页面点 “Run workflow” 手动触发）。
