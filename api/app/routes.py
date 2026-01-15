from typing import List

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session
from datetime import datetime

import models as models
import schemas as schemas
import dependencies as dependencies
import logging

# OpenTelemetry
from opentelemetry import trace

logger = logging.getLogger(__name__)
tracer = trace.get_tracer(__name__)
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
    with tracer.start_as_current_span("list_tasks") as span:
        logger.debug("Listing tasks")
        tasks = db.query(models.Tasks).order_by(models.Tasks.id).all()
        span.set_attribute("task.count", len(tasks))
        logger.info("Tasks retrieved", extra={"count": len(tasks)})
        return [_task_to_response(t) for t in tasks]


@router.post("", response_model=schemas.TasksResponse, status_code=status.HTTP_201_CREATED)
def create_task(payload: schemas.TasksCreate, db: Session = Depends(dependencies.get_db)):
    with tracer.start_as_current_span("create_task") as span:
        logger.info("Creating new task", extra={"title": payload.title})
        span.set_attribute("task.title", payload.title)
        task = models.Tasks(
            title=payload.title,
            description=payload.description,
            completed=False,
            created_at=datetime.utcnow(),
        )
        db.add(task)
        db.commit()
        db.refresh(task)
        span.set_attribute("task.id", task.id)
        logger.info("Task created", extra={"task_id": task.id})
        return _task_to_response(task)


@router.get("/{task_id}", response_model=schemas.TasksResponse)
def get_task(task_id: int, db: Session = Depends(dependencies.get_db)):
    with tracer.start_as_current_span("get_task") as span:
        logger.debug("Fetching task", extra={"task_id": task_id})
        span.set_attribute("task.id", task_id)
        task = db.query(models.Tasks).filter(models.Tasks.id == task_id).first()
        if not task:
            logger.warning("Task not found", extra={"task_id": task_id})
            span.set_attribute("error", True)
            raise HTTPException(status_code=404, detail="Task not found")
        logger.info("Task retrieved", extra={"task_id": task_id})
        return _task_to_response(task)


@router.put("/{task_id}", response_model=schemas.TasksResponse)
def update_task(task_id: int, payload: schemas.TasksCreate, db: Session = Depends(dependencies.get_db)):
    with tracer.start_as_current_span("update_task") as span:
        logger.debug("Updating task", extra={"task_id": task_id})
        span.set_attribute("task.id", task_id)
        task = db.query(models.Tasks).filter(models.Tasks.id == task_id).first()
        if not task:
            logger.warning("Task not found for update", extra={"task_id": task_id})
            span.set_attribute("error", True)
            raise HTTPException(status_code=404, detail="Task not found")

        task.title = payload.title
        task.description = payload.description
        db.add(task)
        db.commit()
        db.refresh(task)
        logger.info("Task updated", extra={"task_id": task_id})
        return _task_to_response(task)


@router.patch("/{task_id}/complete", response_model=schemas.TasksResponse)
def toggle_complete(task_id: int, db: Session = Depends(dependencies.get_db)):
    with tracer.start_as_current_span("toggle_complete") as span:
        logger.debug("Toggling task complete", extra={"task_id": task_id})
        span.set_attribute("task.id", task_id)
        task = db.query(models.Tasks).filter(models.Tasks.id == task_id).first()
        if not task:
            logger.warning("Task not found for toggle", extra={"task_id": task_id})
            span.set_attribute("error", True)
            raise HTTPException(status_code=404, detail="Task not found")
        task.completed = not bool(task.completed)
        db.add(task)
        db.commit()
        db.refresh(task)
        span.set_attribute("task.completed", task.completed)
        logger.info("Task toggled", extra={"task_id": task_id, "completed": task.completed})
        return _task_to_response(task)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(task_id: int, db: Session = Depends(dependencies.get_db)):
    with tracer.start_as_current_span("delete_task") as span:
        logger.debug("Deleting task", extra={"task_id": task_id})
        span.set_attribute("task.id", task_id)
        task = db.query(models.Tasks).filter(models.Tasks.id == task_id).first()
        if not task:
            logger.warning("Task not found for delete", extra={"task_id": task_id})
            span.set_attribute("error", True)
            raise HTTPException(status_code=404, detail="Task not found")
        db.delete(task)
        db.commit()
        logger.info("Task deleted", extra={"task_id": task_id})