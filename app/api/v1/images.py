import io
import os
import uuid
from datetime import datetime
from pathlib import Path

from PIL import Image
from fastapi import APIRouter, UploadFile, File, HTTPException

from app.core.configs import settings
from app.schemas.responses import success, ResponseModel

router = APIRouter(prefix="/images", tags=["images"])

# 1. 动态获取当前脚本文件的绝对路径
current_file = Path(__file__).resolve()

# 2. 动态追溯到项目的根目录
# 假设当前脚本位于项目根目录下的 app/api/v1/image.py
# 那么 .parent 是 v1/，.parent.parent 是 api/，.parent.parent.parent 就是项目根目录
# 你也可以使用 parents[X] 数组快捷键：parents[0]=routers/, parents[1]=app/, parents[2]=项目根目录
PROJECT_ROOT = current_file.parents[2]

# 3. 拼接根目录下的 image 文件夹路径
IMAGE_DIR = PROJECT_ROOT / settings.UPLOAD_IMAGE_STORAGE_FLAG

# 4. ⚡️ 安全创建文件夹（等同于 Linux 的 mkdir -p）
# parents=True: 如果上级目录不存在，会连同上级目录一起创建
# exist_ok=True: 如果 image 文件夹已经存在，不会报错，直接跳过
IMAGE_DIR.mkdir(parents=True, exist_ok=True)

# --- 打印结果验证 ---
print(f"当前文件路径: {current_file}")
print(f"动态构建的项目根目录: {PROJECT_ROOT}")
print(f"成功创建/确认的图片存放目录: {IMAGE_DIR}")
print(f"目录是否存在: {IMAGE_DIR.exists()}")


@router.post(path="/compress", response_model=ResponseModel)
async def compress_image(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="只能上传图片文件！")

    # 1. 限制文件大小（流式读取）
    size = 0
    buffer = io.BytesIO()
    while chunk := await file.read(1024 * 1024):
        size += len(chunk)
        if size > settings.MAX_FILE_SIZE:
            raise HTTPException(status_code=413, detail="图片体积过大")
        buffer.write(chunk)
    buffer.seek(0)

    try:
        # 2.动态生成年/月/日相对路径
        # 例如今天会生成：2026/07/05
        date_path = datetime.now().strftime("%Y/%m/%d")

        # 3. 拼接出容器内的绝对保存目录（如: /app/uploads/2026/07/05）
        target_dir = os.path.join(IMAGE_DIR, date_path)

        # 如果该目录不存在，Python 会连同父目录一起全部自动创建（mkdir -p）
        if not os.path.exists(target_dir):
            os.makedirs(target_dir, exist_ok=True)

        # 4. 生成唯一文件名，拼接最终物理绝对路径
        unique_filename = f"{uuid.uuid4().hex}.jpg"
        file_save_path = os.path.join(target_dir, unique_filename)

        # 5. Pillow 内存压制并写入硬盘
        with Image.open(buffer) as img:
            if img.mode in ("RGBA", "P"):
                img = img.convert("RGB")

            if img.width > 3000:
                scale_ratio = 3000 / img.width
                new_size = (3000, int(img.height * scale_ratio))
                img = img.resize(new_size, Image.Resampling.LANCZOS)

            img.save(file_save_path, format="JPEG", quality=70, optimize=True)

        url = f"{settings.IMAGE_URL_PREFIX}/{date_path}/{unique_filename}"

        return success(data={
            "path": f"{file_save_path}",
            "url": url
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"处理失败: {str(e)}")
