from datetime import datetime
from typing import Generic, TypeVar, Optional, Any

from pydantic import BaseModel, Field

# 定义泛型变量
T = TypeVar("T")


# 1. 定义一个获取当前时间戳的纯函数
def get_current_timestamp() -> int:
    return int(datetime.now().timestamp())


class ResponseModel(BaseModel, Generic[T]):
    code: int = 200
    msg: str = "success"
    data: Optional[T] = None
    # ➡️ 使用 default_factory 动态调用函数
    # 注意：get_current_timestamp 后面绝对不能加括号 ()，加了括号又变成静态值了！
    timestamp: int = Field(default_factory=get_current_timestamp)

    class Config:
        json_encoders = {
            datetime: lambda v: v.strftime("%Y-%m-%d %H:%M:%S")
        }


# 快捷成功返回工厂函数
def success(data: Any = None, msg: str = "success") -> ResponseModel:
    return ResponseModel(code=200, msg=msg, data=data)


# 快捷失败返回工厂函数
def fail(code: int = 400, msg: str = "fail", data: Any = None) -> ResponseModel:
    return ResponseModel(code=code, msg=msg, data=data)
