#!/usr/bin/env bash
# SSH 授权就绪后：推送工作流 → 触发构建 → 打印运行地址。
# 用法：bash /home/admin/NS/ci-repo/push-and-run.sh
set -euo pipefail

REPO="EVFBV/ysm-native-build"
REPO_DIR=/home/admin/NS/ci-repo
KEY=/home/admin/NS/.ssh-ci/id_ed25519
export GIT_SSH_COMMAND="ssh -i $KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

echo "=== 1) 测试 SSH 授权 ==="
if ! ssh -i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "SSH 尚未授权成功。请确认公钥已添加到 https://github.com/settings/ssh/new"
    ssh -i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | head -3 || true
    exit 1
fi
echo "  SSH 授权 OK"

echo
echo "=== 2) 推送工作流到 .github/workflows/ ==="
cd "$REPO_DIR"
mkdir -p .github/workflows
cp workflow/build-windows.yml .github/workflows/build-windows.yml
git add .github/workflows/build-windows.yml
git -c user.email="216367116+EVFBV@users.noreply.github.com" -c user.name="EVFBV" \
    commit -q -m "ci: 添加 Windows native 构建工作流（SSH 推送，绕过 OAuth workflow scope 限制）" || echo "  （无改动可提交）"
git remote set-url origin "git@github.com:$REPO.git"
git push -u origin main
echo "  推送完成"

echo
echo "=== 3) 触发构建 ==="
# push 到 main 已由 workflow 的 on.push 触发；这里再显式触发一次以保证运行
sleep 5
gh workflow run build-windows.yml --repo "$REPO" 2>/dev/null || echo "  （push 已触发，无需手动触发）"

echo
echo "=== 4) 等待运行出现 ==="
for i in $(seq 1 20); do
    run=$(gh run list --repo "$REPO" --workflow build-windows.yml --limit 1 \
          --json databaseId,status,createdAt,url 2>/dev/null || echo "[]")
    if [ "$run" != "[]" ] && [ -n "$run" ]; then
        echo "$run" | python3 -c "
import json,sys
d=json.load(sys.stdin)[0]
print('  run id :', d['databaseId'])
print('  status :', d['status'])
print('  url    :', d['url'])
"
        break
    fi
    sleep 10
done

echo
echo "构建已在云端开始（windows-latest runner，约 40-90 分钟）。"
echo "完成后运行： bash /home/admin/NS/ci-repo/fetch-and-pack.sh"
