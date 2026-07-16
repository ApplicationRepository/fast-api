# 使用官方轻量级 Python 镜像
FROM python:3.12-slim

# 设置工作目录
WORKDIR /workspace

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/workspace

# 动态参数
ARG USER_ID=1000
ARG GROUP_ID=1000

# 安装基础网络调试工具并清理缓存
RUN apt-get update && apt-get install -y --no-install-recommends \
    iputils-ping \
    telnet \
    && rm -rf /var/lib/apt/lists/*

# 先复制并安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# 复制项目代码
COPY ./app ./app

# 创建非 root 安全用户并授权
RUN groupadd -g ${GROUP_ID} -o appgroup && \
    useradd -m -u ${USER_ID} -g appgroup -o appuser && \
    chown -R appuser:appgroup /workspace

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--timeout-keep-alive", "60"]
