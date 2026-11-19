#!/usr/bin/env bash
# 起数据库 -> 等健康检查通过 -> 建表写入种子数据
# 用法：放到项目根目录，执行 ./db-up.sh
set -euo pipefail

CONTAINER="flower_guardian_db"
TIMEOUT=60

docker-compose up -d postgres
echo "等待 PostgreSQL 就绪（最多 ${TIMEOUT}s）..."

status=""
elapsed=0
while [ "${elapsed}" -lt "${TIMEOUT}" ]; do
  status=$(docker inspect -f '{{.State.Health.Status}}' "${CONTAINER}" 2>/dev/null || echo "unknown")
  if [ "${status}" = "healthy" ]; then
    echo "数据库已就绪。"
    break
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done

if [ "${status}" != "healthy" ]; then
  echo "数据库在 ${TIMEOUT}s 内没有就绪，看看日志：docker-compose logs postgres" >&2
  exit 1
fi

cd backend
python -m app.db.seed
echo "完成。后端可以直接启动：uvicorn app.main:app --reload --port 8000"
