#!/usr/bin/env bash
# 等 GitHub Actions 构建完 → 下载 ysm.dll → 打进 JAR 并校验。
# 用法：bash /home/admin/NS/ci-repo/fetch-and-pack.sh
set -euo pipefail

REPO="EVFBV/ysm-native-build"
WORKFLOW="build-windows.yml"
WORK=/home/admin/NS
STAGE="$WORK/.nettest/ci-dll"

echo "=== 1) 查找最近的运行 ==="
run_json=$(gh run list --repo "$REPO" --workflow "$WORKFLOW" --limit 1 \
    --json databaseId,status,conclusion,createdAt,url 2>/dev/null || true)
if [ -z "$run_json" ] || [ "$run_json" = "[]" ]; then
    echo "还没有任何运行记录。请先在仓库里触发工作流："
    echo "  https://github.com/$REPO/actions/workflows/$WORKFLOW"
    exit 1
fi
run_id=$(echo "$run_json" | python3 -c "import json,sys; d=json.load(sys.stdin)[0]; print(d['databaseId'])")
echo "$run_json" | python3 -c "
import json,sys
d=json.load(sys.stdin)[0]
print('  run id   :', d['databaseId'])
print('  status   :', d['status'], '/', d.get('conclusion'))
print('  createdAt:', d['createdAt'])
print('  url      :', d['url'])
"

echo
echo "=== 2) 等待完成（若仍在运行） ==="
gh run watch "$run_id" --repo "$REPO" --exit-status --interval 30 >/dev/null 2>&1 || true
conclusion=$(gh run view "$run_id" --repo "$REPO" --json conclusion --jq '.conclusion')
echo "  conclusion = $conclusion"
if [ "$conclusion" != "success" ]; then
    echo "构建未成功。先下载日志看原因："
    rm -rf "$STAGE-logs"; mkdir -p "$STAGE-logs"
    gh run download "$run_id" --repo "$REPO" -n build-logs -D "$STAGE-logs" 2>/dev/null || true
    ls -la "$STAGE-logs" 2>/dev/null || true
    echo "日志目录：$STAGE-logs"
    exit 1
fi

echo
echo "=== 3) 下载 ysm.dll ==="
rm -rf "$STAGE"; mkdir -p "$STAGE"
gh run download "$run_id" --repo "$REPO" -n ysm-windows-dll -D "$STAGE"
find "$STAGE" -name "ysm.dll" -exec ls -la {} \;
dll=$(find "$STAGE" -name "ysm.dll" | head -1)
if [ -z "$dll" ]; then echo "未在 artifact 中找到 ysm.dll"; exit 1; fi
cp "$dll" "$WORK/ysm.dll"
sha256sum "$WORK/ysm.dll"

echo
echo "=== 4) 打进 JAR ==="
bash "$WORK/pack-windows-jar.sh" "$WORK/ysm.dll"
