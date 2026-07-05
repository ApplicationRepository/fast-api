from datetime import datetime

from fastapi import APIRouter

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
