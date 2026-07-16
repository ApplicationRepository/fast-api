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

echo -e "${YELLOW}[1/3] 正在清理 Python 缓存...${NC}"
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null

# --- 💡 核心优化：检测 root 并安全降级，规避 GID 0 冲突 ---
DETECTED_UID=$(id -u)
DETECTED_GID=$(id -g)

if [ "${DETECTED_UID}" -eq 0 ]; then
    # 如果宿主机是 root，将容器内用户降级为标准的 1000 组
    export CURRENT_UID=1000
    export CURRENT_GID=1000
    echo -e "${YELLOW}-> 检测到宿主机为 root 用户，已安全降级容器内权限至 UID=1000, GID=1000${NC}"
else
    export CURRENT_UID=${DETECTED_UID}
    export CURRENT_GID=${DETECTED_GID}
    echo -e "${GREEN}-> 已绑定宿主机权限: UID=${CURRENT_UID}, GID=${CURRENT_GID}${NC}"
fi

echo -e "${YELLOW}[2/3] 正在后台构建新镜像并平滑替换容器...${NC}"
docker compose up -d --build

# 💡 核心新增：检查 docker compose 命令是否成功执行
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Docker 镜像构建或容器启动失败！终止后续验证。${NC}"
    exit 1
fi

# --- 3. 验证新版本是否正常启动 ---
echo -e "${YELLOW}[3/3] 正在验证前端与后端服务状态...${NC}"
sleep 3

# 对齐真实的容器名称
REAL_BACKEND_CONTAINER="${APP_BACKEND_CONTAINER_NAME}-${APP_BACKEND_CONTAINER_VERSION}"
REAL_FRONTEND_CONTAINER="${APP_FRONTEND_CONTAINER_NAME}-${APP_FRONTEND_CONTAINER_VERSION}"

BACKEND_RUNNING=$(docker inspect -f '{{.State.Running}}' "${REAL_BACKEND_CONTAINER}" 2>/dev/null)
FRONTEND_RUNNING=$(docker inspect -f '{{.State.Running}}' "${REAL_FRONTEND_CONTAINER}" 2>/dev/null)

if [ "${BACKEND_RUNNING}" == "true" ] && [ "${FRONTEND_RUNNING}" == "true" ]; then
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}  生产环境代码更新成功! 前后端服务已平滑切换。${NC}"
    echo -e "${GREEN}  后端容器 [${REAL_BACKEND_CONTAINER}] 已启动。${NC}"
    echo -e "${GREEN}  前端容器 [${REAL_FRONTEND_CONTAINER}] 已启动。${NC}"
    echo -e "${GREEN}==================================================${NC}"
else
    echo -e "${RED}[ERROR] 服务未能完全启动！${NC}"
    if [ "${BACKEND_RUNNING}" != "true" ]; then
        echo -e "${RED}[- 异常 -] 后端容器 [${REAL_BACKEND_CONTAINER}] 未启动，正在打印最近日志...${NC}"
        docker compose logs backend | tail -n 20
    fi
    if [ "${FRONTEND_RUNNING}" != "true" ]; then
        echo -e "${RED}[- 异常 -] 前端容器 [${REAL_FRONTEND_CONTAINER}] 未启动，正在打印最近日志...${NC}"
        docker compose logs frontend | tail -n 20
    fi
    exit 1
fi
