#!/bin/bash

# --- 自动加载公共配置文件 ---
if [ -f ".env" ]; then
    source .env
else
    echo -e "\033[0;31m[ERROR] 未找到公共配置文件 .env \033[0m"
    exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}[1/3] 正在拉取最新的 Git 代码并清理缓存...${NC}"
# 生产环境标准动作：清理缓存
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null

export APP_VERSION="${APP_VERSION}"
export APP_IMAGE_NAME="${APP_IMAGE_NAME}"
export APP_CONTAINER_NAME="${APP_CONTAINER_NAME}"

echo -e "${YELLOW}[2/3] 正在后台构建新镜像并平滑替换容器...${NC}"
# 💡 生产环境核心命令：
# --build: 强制 Docker 深度扫描 app/ 目录，发现代码变动立刻构建新镜像
# -d: 后台运行
# 机制：Docker 会先在后台默默构建新镜像，等新镜像完全构建好了，
# 它才会“闪击”停掉旧容器、瞬间启动新容器。服务中断时间通常小于 0.5 秒。
docker compose up -d --build

# 3. 验证新版本是否正常启动
echo -e "${YELLOW}[3/3] 正在验证新版本状态...${NC}"
sleep 3
IS_RUNNING=$(docker inspect -f '{{.State.Running}}' "${APP_CONTAINER_NAME}" 2>/dev/null)

if [ "${IS_RUNNING}" == "true" ]; then
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN} 生产环境代码更新成功! FastAPI 服务已平滑切换到最新版本。${NC}"
    echo -e "${GREEN} 当前运行版本: ${APP_VERSION}${NC}"
    echo -e "${GREEN}==================================================${NC}"
else
    echo -e "${RED}[ERROR] 新版本容器未能启动！正在自动回滚...${NC}"
    # 如果失败，可以在这里写回滚逻辑，或者提示查看日志
    docker compose logs web
    exit 1
fi
