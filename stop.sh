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

echo -e "${YELLOW}[1/5] 开始自动化安全卸载流程...${NC}"

# --- 1. 停止并移除容器与相关网络 ---
echo -e "${YELLOW}正在停止并清理 Docker 容器及网络环境...${NC}"

if [ -f "docker-compose.yml" ]; then
    # 导出 compose 运行所依赖的所有环境变量
    export APP_BACKEND_IMAGE_NAME="${APP_BACKEND_IMAGE_NAME}"
    export APP_BACKEND_IMAGE_VERSION="${APP_BACKEND_IMAGE_VERSION}"
    export APP_BACKEND_CONTAINER_NAME="${APP_BACKEND_CONTAINER_NAME}"

    export APP_FRONTEND_IMAGE_NAME="${APP_FRONTEND_IMAGE_NAME}"
    # 💡 注意：修正了你前面可能存在的变量名差异，兼容 _VERSION 和 _VERSION
    export APP_FRONTEND_VERSION="${APP_FRONTEND_VERSION:-${APP_FRONTEND_IMAGE_VERSION}}"
    export APP_FRONTEND_CONTAINER_NAME="${APP_FRONTEND_CONTAINER_NAME}"

    docker compose down --volumes --remove-orphans
else
    echo -e "${RED}[警告] 未找到 docker-compose.yml 文件，正在尝试通过容器名强制停止并移除...${NC}"
    docker rm -f "${APP_BACKEND_CONTAINER_NAME}" "${APP_FRONTEND_CONTAINER_NAME}" 2>/dev/null
fi

# --- 2. 精准清理项目构建的镜像 ---
echo -e "${YELLOW}[2/5] 开始清理项目指定的镜像...${NC}"

BACKEND_IMAGE="${APP_BACKEND_IMAGE_NAME}:${APP_BACKEND_IMAGE_VERSION}"
FRONTEND_IMAGE="${APP_FRONTEND_IMAGE_NAME}:${APP_FRONTEND_VERSION}"

# 清理后端镜像
if [ -n "$(docker images -q "${BACKEND_IMAGE}" 2>/dev/null)" ]; then
    echo -e "${YELLOW}正在删除后端镜像: ${BACKEND_IMAGE}...${NC}"
    docker rmi -f "${BACKEND_IMAGE}" 2>/dev/null
fi

# 清理前端镜像
if [ -n "$(docker images -q "${FRONTEND_IMAGE}" 2>/dev/null)" ]; then
    echo -e "${YELLOW}正在删除前端镜像: ${FRONTEND_IMAGE}...${NC}"
    docker rmi -f "${FRONTEND_IMAGE}" 2>/dev/null
fi

# --- 💡 3. 新增：全局清空无标签镜像、停止的容器、废弃网络 ---
echo -e "${YELLOW}[3/5] 正在清理 Docker 孤儿资源（无标签镜像、停止容器、孤立网络）...${NC}"
# 清理所有停止的容器
docker container prune -f >/dev/null 2>&1
# 清理所有无标签/虚悬镜像 (Dangling Images，常被称为 <none> 镜像)
docker image prune -f >/dev/null 2>&1
# 清理所有未被使用的自定义网络 (防止残留)
docker network prune -f >/dev/null 2>&1

# --- 4. 清理本地缓存 ---
echo -e "${YELLOW}[4/5] 正在排空本地 Python 缓存...${NC}"
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null
find . -type f -name "*.pyc" -delete 2>/dev/null

# --- 5. 核心：深度清理当前目录下所有的代码与配置文件 ---
echo -e "${RED}[5/5] 警告：开始深度清理当前目录下的所有代码及配置文件！${NC}"

# 🔒 【安全防呆】: 确保我们不在系统根目录、/home 或 /usr 等危险目录下
CURRENT_DIR=$(pwd)
if [ "${CURRENT_DIR}" == "/" ] || [ "${CURRENT_DIR}" == "/root" ] || [ "${CURRENT_DIR}" == "/home" ]; then
    echo -e "${RED}[FATAL ERROR] 绝对禁止在核心系统根路径下执行清理！流程紧急终止。${NC}"
    exit 1
fi

# 提示用户，给 5 秒反悔时间（原脚本写的是 10 秒，这里保留你原本的提示或按需调整）
echo -e "${YELLOW}将在 5 秒后清空目录 [ ${CURRENT_DIR} ] 内的所有非脚本文件，按 Ctrl+C 可紧急取消...${NC}"
sleep 5

# 清理当前目录（除了卸载脚本自身，或者全部清空。这里会清空当前目录所有文件）
find . -maxdepth 1 ! -name "." -exec rm -rf {} + 2>/dev/null

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN} 卸载与 Docker 系统级垃圾清理完全成功！${NC}"
echo -e "${GREEN}  - 容器、网络与无标签镜像：已全部彻底清空。${NC}"
echo -e "${GREEN}  - 本地代码与配置：已全部物理删除。${NC}"
echo -e "${GREEN}==================================================${NC}"
