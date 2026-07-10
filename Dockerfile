# 使用官方轻量级 Python 镜像
FROM python:3.12-slim

# 设置工作目录
WORKDIR /workspace

# 设置环境变量
# PYTHONDONTWRITEBYTECODE: 禁止 Python 写入 .pyc 文件
# PYTHONUNBUFFERED: 保证日志实时输出，不被缓存
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/workspace

# 动态参数：允许在构建时传入宿主机的真实 UID 和 GID
# 默认值设为 1000（Linux 第一个普通用户的默认值，通常能直接对齐你的 root 或普通用户）
ARG USER_ID=1000
ARG GROUP_ID=1000

# 安装依赖
COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade -r requirements.txt

# 复制项目代码
COPY ./app ./app

# 创建一个非 root 用户，并将其 UID/GID 与宿主机显式对齐
# 这样容器内的 appuser 读写挂载目录时，宿主机就会认为是合法的本地用户在操作
RUN groupadd -g ${GROUP_ID} appgroup &&  \
    useradd -m -u ${USER_ID} -g appgroup appuser &&  \
    chown -R appuser:appgroup /workspace

# 切换到非 root 安全用户
USER appuser

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000","--timeout-keep-alive","60"]
