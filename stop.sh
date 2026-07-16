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

echo -e "${YELLOW}[1/4] 开始自动化安全卸载流程...${NC}"

# --- 1. 停止并移除容器与相关网络 ---
echo -e "${YELLOW}正在停止并清理 Docker 容器及网络环境...${NC}"

if [ -f "docker-compose.yml" ]; then
    # 导出 compose 运行所依赖的所有环境变量
    export APP_BACKEND_IMAGE_NAME="${APP_BACKEND_IMAGE_NAME}"
    export APP_BACKEND_IMAGE_VERSION="${APP_BACKEND_IMAGE_VERSION}"
    export APP_BACKEND_CONTAINER_NAME="${APP_BACKEND_CONTAINER_NAME}"

    export APP_FRONTEND_IMAGE_NAME="${APP_FRONTEND_IMAGE_NAME}"
    export APP_FRONTEND_VERSION="${APP_FRONTEND_VERSION}"
    export APP_FRONTEND_CONTAINER_NAME="${APP_FRONTEND_CONTAINER_NAME}"

    docker compose down
else
    echo -e "${RED}[警告] 未找到 docker-compose.yml 文件，正在尝试通过容器名强制停止并移除...${NC}"
    docker rm -f "${APP_BACKEND_CONTAINER_NAME}" "${APP_FRONTEND_CONTAINER_NAME}" 2>/dev/null
fi

# --- 2. 精准清理项目构建的镜像 ---
echo -e "${YELLOW}[2/4] 开始清理项目指定的镜像...${NC}"

BACKEND_IMAGE="${APP_BACKEND_IMAGE_NAME}:${APP_BACKEND_IMAGE_VERSION}"
FRONTEND_IMAGE="${APP_FRONTEND_IMAGE_NAME}:${APP_FRONTEND_VERSION}"

# 清理后端镜像
if [ -n "$(docker images -q "${BACKEND_IMAGE}" 2>/dev/null)" ]; then
    echo -e "${YELLOW}正在删除后端镜像: ${BACKEND_IMAGE}...${NC}"
    docker rmi "${BACKEND_IMAGE}"
else
    echo -e "${GREEN}未发现本地后端镜像 ${BACKEND_IMAGE}，跳过清理。${NC}"
fi

# 清理前端镜像
if [ -n "$(docker images -q "${FRONTEND_IMAGE}" 2>/dev/null)" ]; then
    echo -e "${YELLOW}正在删除前端镜像: ${FRONTEND_IMAGE}...${NC}"
    docker rmi "${FRONTEND_IMAGE}"
else
    echo -e "${GREEN}未发现本地前端镜像 ${FRONTEND_IMAGE}，跳过清理。${NC}"
fi

# --- 3. 清理本地缓存 ---
echo -e "${YELLOW}[3/4] 正在排空本地 Python 缓存...${NC}"
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null
find . -type f -name "*.pyc" -delete 2>/dev/null

# --- 4. 核心新增：深度清理当前目录下所有的代码与配置文件 ---
echo -e "${RED}[4/4] 警告：开始深度清理当前目录下的所有代码及配置文件！${NC}"

# 🔒 【安全防呆】: 确保我们不在系统根目录、/home 或 /usr 等危险目录下
CURRENT_DIR=$(pwd)
if [ "${CURRENT_DIR}" == "/" ] || [ "${CURRENT_DIR}" == "/root" ] || [ "${CURRENT_DIR}" == "/home" ]; then
    echo -e "${RED}[FATAL ERROR] 绝对禁止在核心系统根路径下执行清理！流程紧急终止。${NC}"
    exit 1
fi

# 提示用户，给 3 秒反悔时间
echo -e "${YELLOW}将在 3 秒后清空目录 [ ${CURRENT_DIR} ] 内的所有非脚本文件，按 Ctrl+C 可紧急取消...${NC}"
sleep 3

# 清理当前目录（排除本卸载脚本自身，防止执行到一半中断报错）
# 这里会删除：app/ 目录、dist/ 目录、nginx.conf、.env、docker-compose.yml 等所有代码和配置
# 仅保留本脚本本身，待运行结束后你可以手动删除当前空文件夹
find . -maxdepth 1 ! -name "uninstall.sh" ! -name "." -exec rm -rf {} + 2>/dev/null

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN} 卸载与清理完全成功！${NC}"
echo -e "${GREEN}  - 容器与网络：已全部销毁。${NC}"
echo -e "${GREEN}  - 镜像文件：已彻底从 Docker 移除。${NC}"
echo -e "${GREEN}  - 本地代码与配置：已全部物理删除。${NC}"
echo -e "${YELLOW}  提示：当前目录仅剩 [ uninstall.sh ]，你可以通过 cd .. && rm -rf ${CURRENT_DIR##*/} 安全删除该空文件夹。${NC}"
echo -e "${GREEN}==================================================${NC}"
