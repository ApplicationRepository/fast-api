#!/bin/bash

# --- 核心：自动加载公共配置文件 ---
if [ -f ".env" ]; then
    source .env
else
    echo -e "\033[0;31m[ERROR] 未找到公共配置文件 .env，无法继续卸载！\033[0m"
    exit 1
fi

# 正确的 ANSI 颜色控制符
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}[1/3] 开始自动化安全卸载流程...${NC}"

# --- 1. 停止并移除容器与相关网络 ---
echo -e "${YELLOW}正在停止并清理 Docker 容器及网络环境...${NC}"

if [ -f "docker-compose.yml" ]; then
    # 导出变量，确保 docker compose 识别到相同的服务名称进行卸载
    export APP_VERSION="${APP_VERSION}"
    export APP_IMAGE_NAME="${APP_IMAGE_NAME}"
    export APP_CONTAINER_NAME="${APP_CONTAINER_NAME}"

    docker compose down
else
    echo -e "${RED}[警告] 未找到 docker-compose.yml 文件，正在尝试通过容器名强制移除...${NC}"
    docker rm -f "${APP_CONTAINER_NAME}" 2>/dev/null
fi

# --- 2. 精准清理项目构建的镜像 ---
echo -e "${YELLOW}[2/3] 开始清理项目指定镜像...${NC}"
TARGET_IMAGE="${APP_IMAGE_NAME}:${APP_VERSION}"

# 检查该镜像是否存在，存在则删除
if [ -n "$(docker images -q "${TARGET_IMAGE}" 2>/dev/null)" ]; then
    echo -e "${YELLOW}正在删除镜像: ${TARGET_IMAGE}...${NC}"
    docker rmi "${TARGET_IMAGE}"
else
    echo -e "${GREEN}未发现本地镜像 ${TARGET_IMAGE}，跳过清理。${NC}"
fi

# --- 3. 环境收尾：清理本地 Python 缓存 ---
echo -e "${YELLOW}[3/3] 正在排空本地 Python 缓存...${NC}"
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null
find . -type f -name "*.pyc" -delete 2>/dev/null

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN} 卸载完成！${NC}"
echo -e "${GREEN}  - 容器 '${APP_CONTAINER_NAME}' 已安全停止并销毁。${NC}"
echo -e "${GREEN}  - 镜像 '${TARGET_IMAGE}' 已从本地彻底移除。${NC}"
echo -e "${GREEN}  - 本地缓存文件已全部清理干净。${NC}"
echo -e "${GREEN}==================================================${NC}"
