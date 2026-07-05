from datetime import datetime

from fastapi import APIRouter
from pydantic import BaseModel

from app.schemas.responses import success, ResponseModel

router = APIRouter(prefix="/items", tags=["items"])


@router.get(path="/list", response_model=ResponseModel)
def item_list():
    data = [
        {
            "id": 1,
            "title": "Item 1",
            "description": "A great item"
        },
        {
            "id": 2,
            "title": "Item 2",
            "description": "A great item"
        }
    ]
    return success(data=data)


@router.get(path="/current-time", response_model=ResponseModel)
def current_time():
    local_time = datetime.now()
    return success(data={
        "now": local_time.strftime("%Y-%m-%d %H:%M:%S")
    })


class ItemCreate(BaseModel):
    title: str
    description: str


@router.post(path="/", response_model=ResponseModel)
def create_item(item: ItemCreate):
    # 4. 组装成包含 ID 的完整字典（准备返回给前端）
    inserted_data = {
        "id": 3,
        "title": item.title,
        "description": item.description
    }

    return success(data=inserted_data)
