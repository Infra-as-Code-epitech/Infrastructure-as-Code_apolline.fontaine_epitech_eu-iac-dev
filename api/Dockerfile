FROM python:3.11-slim

USER root

RUN groupadd -r appuser && useradd -r -g appuser -u 1001 appuser

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN apt-get update && apt-get install -y curl

COPY ./app /app

RUN chown -R appuser:appuser /app
USER appuser

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
