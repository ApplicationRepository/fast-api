#!/bin/bash

# --- 核心：自动加载公共配置文件 ---
if [ -f ".env" ]; then
    source .env
else
    echo -e "\033[0;31m[ERROR] 未找到公共配置文件 .env，请先创建它！\033[0m"
    exit 1
fi

# 正确的 ANSI 颜色控制符
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}[1/4] 开始自动化部署流程，版本号: ${APP_VERSION}...${NC}"

# --- 1. 环境清理 ---
echo -e "${YELLOW}正在清理本地 Python 缓存...${NC}"
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null
find . -type f -name "*.pyc" -delete 2>/dev/null

# --- 2. 动态导出变量并使用 Docker Compose 构建 ---
echo -e "${YELLOW}[2/4] 正在使用 Docker Compose 进行构建...${NC}"

# 将从 .env 中读取到的变量导出给外部环境（供 docker-compose 引用）
export APP_VERSION="${APP_VERSION}"
export APP_IMAGE_NAME="${APP_IMAGE_NAME}"
export APP_CONTAINER_NAME="${APP_CONTAINER_NAME}"

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
sleep 3

# 检查容器是否处于运行（running）状态
IS_RUNNING=$(docker inspect -f '{{.State.Running}}' "${APP_CONTAINER_NAME}" 2>/dev/null)

if [ "${IS_RUNNING}" == "true" ]; then
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN} 部署成功! FastAPI 服务已在后台运行。${NC}"
    echo -e "${GREEN} 镜像名称: ${APP_IMAGE_NAME}:${APP_VERSION}${NC}"
    echo -e "${GREEN} 访问地址: http://localhost:8000/docs${NC}"
    echo -e "${GREEN}==================================================${NC}"
else
    echo -e "${RED}[ERROR] 容器（${APP_CONTAINER_NAME}）未能成功运行！${NC}"
    echo -e "${YELLOW}请手动执行以下命令查看具体的 Python 报错日志：${NC}"
    echo -e "${GREEN}docker compose logs web${NC}"
    exit 1
fi
