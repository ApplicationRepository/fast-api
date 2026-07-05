from datetime import datetime

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


# 统一的时间戳获取函数
def get_current_timestamp() -> int:
    return int(datetime.now().timestamp())


# 1. 拦截标准 HTTP 异常 (如 404 Not Found, 401 Unauthorized)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "code": exc.status_code,
            "msg": str(exc.detail),
            "data": None,
            "timestamp": get_current_timestamp()
        }
    )


# 2. 拦截 Pydantic 参数校验失败异常 (422 Unprocessable Entity)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = exc.errors()
    error_msg = f"参数错误: {errors[0]['loc'][-1]} {errors[0]['msg']}" if errors else "参数校验失败"

    return JSONResponse(
        status_code=422,
        content={
            "code": 422,
            "msg": error_msg,
            "data": errors,  # 将详细的错误列表返回给前端
            "timestamp": get_current_timestamp()
        }
    )


# 3. 核心：封装一个注册函数，供 main.py 一键调用
def register_exception_handlers(app: FastAPI) -> None:
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
