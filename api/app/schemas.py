from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class TasksCreate(BaseModel):
    title: str
    description: Optional[str] = None

class TasksResponse(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    completed: bool
    created_at: datetime