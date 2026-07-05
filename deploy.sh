#!/bin/bash

# --- 配置区域 ---
VERSION="v1.0.0"
IMAGE_NAME="fast_api_app"
CONTAINER_NAME="fast_api_app"

# 正确的 ANSI 颜色控制符
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${YELLOW}[1/4] 开始自动化部署流程，版本号: ${VERSION}...${NC}"

# --- 1. 环境清理 ---
echo -e "${YELLOW}正在清理本地 Python 缓存...${NC}"
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null
find . -type f -name "*.pyc" -delete 2>/dev/null

# --- 2. 动态更新 Docker Compose 变量并构建 ---
echo -e "${YELLOW}[2/4] 正在使用 Docker Compose 进行构建...${NC}"

# 显式导出干净的环境变量
export APP_VERSION="${VERSION}"
export APP_IMAGE_NAME="${IMAGE_NAME}"
export APP_CONTAINER_NAME="${CONTAINER_NAME}"

# 执行构建并后台启动
docker compose up -d --build

# 检查 docker compose 命令本身的退出状态码
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[3/4] Docker 构建指令发送成功！${NC}"
else
    echo -e "${RED}[ERROR] 构建或启动失败，请检查上方日志！${NC}"
    exit 1
fi

# --- 3. 验证部署状态 ---
echo -e "${YELLOW}[4/4] 正在验证服务状态...${NC}"
sleep 3 # 给容器 3 秒的内部初始化启动时间

# 检查容器是否处于运行（running）状态
IS_RUNNING=$(docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}" 2>/dev/null)

if [ "${IS_RUNNING}" == "true" ]; then
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN} 部署成功! FastAPI 服务已在后台运行。${NC}"
    echo -e "${GREEN} 镜像名称: ${IMAGE_NAME}:${VERSION}${NC}"
    echo -e "${GREEN} 访问地址: http://localhost:8000/docs${NC}"
    echo -e "${GREEN}==================================================${NC}"
else
    echo -e "${RED}[ERROR] 容器（${CONTAINER_NAME}）未能成功运行！${NC}"
    echo -e "${YELLOW}请手动执行以下命令查看具体的 Python 报错日志：${NC}"
    echo -e "${GREEN}docker compose logs web${NC}"
    exit 1
fi
