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

模板里的端口本来就是 `5432`，真正要改的是账号密码——模板写的是 `user` / `password`，compose 里的是 `flower_user` / `flower_password`：

```dotenv
DATABASE_URL=postgresql://flower_user:flower_password@localhost:5432/flower_guardian
```

```bash
# 建表并写入种子数据
python -m app.db.seed

# 启动后端
uvicorn app.main:app --reload --port 8000
```

`seed.py` 是幂等的：表已存在、库里已有植物时，它会打印 `Database already has N plants` 直接返回，不会重复写入。

## 3. 验证和重置

```bash
# 进容器看看表建出来没有
docker-compose exec postgres psql -U flower_user -d flower_guardian -c '\dt'

# 数据乱了想重来（会删掉卷里的数据）
docker-compose down -v
docker-compose up -d postgres
```

## 4. 两个坑

- **端口别搞错**：不建 `.env` 时，`backend/app/core/config.py` 里的默认连接串是 `localhost:5555`，和 compose 暴露的 `5432` 对不上，接口会直接报数据库连不上。
- **`up -d` 返回不等于能用**：容器刚起来还在初始化，紧接着跑 `python -m app.db.seed` 容易 `connection refused`。等 `docker-compose ps postgres` 显示 `healthy` 再建表。

## 5. 一键起库

`db-up.sh` 把上面两步串起来：起容器 → 等 healthy（最多 60 秒）→ 进 `backend/` 跑 seed。放到项目根目录执行：

```bash
./db-up.sh
```

## 6. 这次练到的 GitHub 流程

`fork` → 建分支 → 改文件 → `commit` → `push` → 开 PR → 等 review。

- 原则：往上游交东西只做**新增**，不改对方的现有文件。合并了不会破坏什么，不合并也零副作用。
- 这次的 PR：[ember-L/flower_guardian#4](https://github.com/ember-L/flower_guardian/pull/4)，只新增 `docs/local-dev-setup.md` 和 `scripts/dev-db.sh`，`+143 -0`。
- 前期直接改 README 的 PR（#2、#3）已经关闭并撤回，老师仓库的 `main` 没有任何来自我们的提交。
- 自己的笔记单独放这个仓库维护，和上游 PR 分开。
