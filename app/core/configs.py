from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI Standard Production API"
    API_V1_STR: str = "/api/v1"
    # 设置最大允许上传 100MB，防止恶意大文件灌死服务器
    MAX_FILE_SIZE: int = 100 * 1024 * 1024
    UPLOAD_IMAGE_STORAGE_FLAG: str = "image"
    IMAGE_URL_PREFIX: str = "https://localhost:8080/image"

    class Config:
        case_sensitive = True


settings = Settings()
