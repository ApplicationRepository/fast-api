from fastapi import FastAPI

from app.api.v1.api import api_router
from app.core.configs import settings
from app.core.exceptions import register_exception_handlers

app = FastAPI(title=settings.PROJECT_NAME)
register_exception_handlers(app=app)

# 包含路由
app.include_router(router=api_router, prefix=settings.API_V1_STR)

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app="app.main:app", host="127.0.0.1", port=8000, reload=True)
