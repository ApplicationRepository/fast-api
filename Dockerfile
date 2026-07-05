# 使用官方轻量级 Python 镜像
FROM python:3.12-slim

# 设置工作目录
WORKDIR /workspace

# 设置环境变量
# PYTHONDONTWRITEBYTECODE: 禁止 Python 写入 .pyc 文件
# PYTHONUNBUFFERED: 保证日志实时输出，不被缓存
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 安装依赖
COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade -r requirements.txt

# 复制项目代码
COPY ./app ./app

# 创建一个非 root 用户并切换，提升安全性
RUN useradd -m appuser && chown -R appuser:appuser /workspace
USER appuser

# 暴露端口
EXPOSE 8000

# 启动命令（生产环境建议限制 workers 数量或交由 gunicorn 管理）
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
