from typing import List

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session
from datetime import datetime

import models as models
import schemas as schemas
import dependencies as dependencies

router = APIRouter(prefix="/tasks", tags=["tasks"])


def _task_to_response(task: models.Tasks) -> schemas.TasksResponse:
    return schemas.TasksResponse(
        id=task.id,
        title=task.title,
        description=task.description,
        completed=task.completed,
        created_at=task.created_at,
    )


@router.get("", response_model=List[schemas.TasksResponse])
def list_tasks(db: Session = Depends(dependencies.get_db)):
    tasks = db.query(models.Tasks).order_by(models.Tasks.id).all()
    return [_task_to_response(t) for t in tasks]


@router.post("", response_model=schemas.TasksResponse, status_code=status.HTTP_201_CREATED)
def create_task(payload: schemas.TasksCreate, db: Session = Depends(dependencies.get_db)):
    task = models.Tasks(
        title=payload.title,
        description=payload.description,
        completed=False,
        created_at=datetime.utcnow(),
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return _task_to_response(task)


@router.get("/{task_id}", response_model=schemas.TasksResponse)
def get_task(task_id: int, db: Session = Depends(dependencies.get_db)):
    task = db.query(models.Tasks).filter(models.Tasks.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return _task_to_response(task)


@router.put("/{task_id}", response_model=schemas.TasksResponse)
def update_task(task_id: int, payload: schemas.TasksCreate, db: Session = Depends(dependencies.get_db)):
    task = db.query(models.Tasks).filter(models.Tasks.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    task.title = payload.title
    task.description = payload.description
    db.add(task)
    db.commit()
    db.refresh(task)
    return _task_to_response(task)


@router.patch("/{task_id}/complete", response_model=schemas.TasksResponse)
def toggle_complete(task_id: int, db: Session = Depends(dependencies.get_db)):
    task = db.query(models.Tasks).filter(models.Tasks.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    task.completed = not bool(task.completed)
    db.add(task)
    db.commit()
    db.refresh(task)
    return _task_to_response(task)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(task_id: int, db: Session = Depends(dependencies.get_db)):
    task = db.query(models.Tasks).filter(models.Tasks.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()