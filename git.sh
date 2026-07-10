#!/bin/bash

# 字体颜色定义
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${YELLOW}==================================================${NC}"
# 获取当前时间（2026年）
echo -e "${YELLOW} 🚀 开始执行自动化流水线: 强制更新代码 并 部署${NC}"
echo -e "${YELLOW} 当前时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${YELLOW}==================================================${NC}"

# --- 1. 执行 Git 强制更新机制 ---
echo -e "\n${YELLOW}[步骤 1/3] 正在从 GitHub 强制抓取最新数据...${NC}"
git fetch --all
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] git fetch 失败，请检查服务器网络或 SSH 密钥权限！${NC}"
    exit 1
fi

echo -e "${YELLOW}[步骤 2/3] 正在无情覆盖本地代码，强制对齐远端 main 分支...${NC}"
# 这里的 main 可以根据你的分支名改成 master
git reset --hard origin/main
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] git reset 失败，未能成功对齐分支！${NC}"
    exit 1
fi

# 清理未追踪的野生文件（排除 .env 保护名单）
git clean -fd

echo -e "${GREEN}[SUCCESS] Git 代码强制更新完成！${NC}"


# --- 2. 检查并调度执行 deploy.sh ---
echo -e "\n${YELLOW}[步骤 3/3] 正在触发部署脚本 deploy.sh...${NC}"

if [ -f "./deploy.sh" ]; then
    # 确保 deploy.sh 拥有可执行权限
    chmod +x ./deploy.sh

    # ➡️ 核心：直接调用并执行部署脚本
    ./deploy.sh

    # 检查部署脚本的最终退出状态
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}==================================================${NC}"
        echo -e "${GREEN} 🎉 恭喜！全套自动化更新与部署流程顺利圆满完成！${NC}"
        echo -e "${GREEN}==================================================${NC}"
    else
        echo -e "\n${RED}[ERROR] 部署脚本 deploy.sh 在执行过程中出错，请检查容器日志。${NC}"
        exit 1
    fi
else
    echo -e "${RED}[ERROR] 未在当前目录下找到部署脚本 deploy.sh！${NC}"
    exit 1
fi
