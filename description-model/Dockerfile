# The model package: one recommendation run (connector/run.py), then it stops.
# The model is git-ignored, so it comes in as a second build folder named "model":
#   docker build -t marikina-market-model --build-context model="<project>/description-model/New Training Model/evaluation/frozen-final-v4" description-model
# Database settings (PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD, PGSSLMODE) are given when it runs, never built in.
FROM python:3.12.10-slim-bookworm
ENV PYTHONUNBUFFERED=1 MODEL_DIR=/model
WORKDIR /connector
COPY requirements-lock.txt .
RUN pip install --no-cache-dir --no-deps --disable-pip-version-check --extra-index-url https://download.pytorch.org/whl/cpu -r requirements-lock.txt
COPY --from=model . /model/evaluation/frozen-final-v4
COPY connector/ .
RUN useradd --create-home --uid 1000 model
USER model
CMD ["python", "-B", "run.py"]
