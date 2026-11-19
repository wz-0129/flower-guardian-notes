# 护花使者 · 数据库笔记

跟着班级项目 [ember-L/flower_guardian](https://github.com/ember-L/flower_guardian) 学的「数据库启动」和「本地后端联调」，整理成自己的笔记放这里。

原项目的代码和文档归原作者，这个仓库只有我自己的笔记。练习时没有往对方仓库提交任何改动。

## 1. 只用 Docker 起数据库

从项目的 `docker-compose.yml` 里读到的事实：

| 项 | 值 |
| --- | --- |
| 服务名 / 容器名 | `postgres` / `flower_guardian_db` |
| 镜像 | `postgres:15-alpine` |
| 端口 | `5432` |
| 数据库 | `flower_guardian` |
| 用户 / 密码 | `flower_user` / `flower_password` |
| 健康检查 | `pg_isready -U flower_user -d flower_guardian` |

```bash
# 只起数据库，不拉后端和前端
docker-compose up -d postgres

# 状态里出现 healthy 才算真的就绪
docker-compose ps postgres

# 出问题时看日志
docker-compose logs -f postgres
```

## 2. 本地后端连这个库

后端跑在宿主机、数据库跑在容器里时，两边都走 `localhost:5432`。

```bash
cd backend
cp .env.example .env
```

把 `backend/.env` 的 `DATABASE_URL` 换成和 compose 一致的值：

```dotenv
DATABASE_URL=postgresql://flower_user:flower_password@localhost:5432/flower_guardian
```

```bash
# 建表并写入种子数据
python -m app.db.seed

# 启动后端
uvicorn app.main:app --reload --port 8000
```

## 3. 两个坑

- **端口别搞错**：不建 `.env` 时，`backend/app/core/config.py` 里的默认连接串是 `localhost:5555`，和 compose 暴露的 `5432` 对不上，接口会直接报数据库连不上。
- **`up -d` 返回不等于能用**：容器刚起来还在初始化，紧接着跑 `python -m app.db.seed` 容易 `connection refused`。等 `docker-compose ps postgres` 显示 `healthy` 再建表。

## 4. 这次练到的 GitHub 流程

`fork` → 建分支 → 改文件 → `commit` → `push` → 开 PR → 等 review。

课上演示用的是老师自己的项目，练习时不往里面留 PR；拆出来的内容放到这个仓库自己维护。
