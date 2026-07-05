from datetime import datetime

from fastapi import APIRouter

from app.schema.item import Item, ItemCreate

router = APIRouter(prefix="/item", tags=["item"])


@router.get("/", response_model=list[Item])
def read_items():
    return [{"id": 1, "title": "Item 1", "description": "A great item"}]


@router.post("/", response_model=Item)
def create_item(item: ItemCreate):
    return {"id": 2, **item.model_dump()}


@router.get("/time")
def get_current_time():
    # 方式一：直接获取系统本地时间（因为我们在 docker-compose 中挂载了 /etc/localtime，这里拿到的就是北京时间）
    local_time = datetime.now()

    return {
        "local_time_str": local_time.strftime("%Y-%m-%d %H:%M:%S"),  # 格式化本地时间
    }
