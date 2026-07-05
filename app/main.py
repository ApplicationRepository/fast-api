from fastapi import FastAPI

from app.api.v1 import item
from app.core.config import settings

app = FastAPI(title=settings.PROJECT_NAME)

# 包含路由
app.include_router(router=item.router, prefix=settings.API_V1_STR, tags=["item"])

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
