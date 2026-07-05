from fastapi import APIRouter

# 引入各个子业务模块的 router
from app.api.v1 import items

# 创建一个总的 v1 路由对象
api_router = APIRouter()

# 聚合挂载各个子模块
# prefix 统一规定该模块下的资源前缀，会自动与子模块内部的路径拼接
api_router.include_router(router=items.router)
