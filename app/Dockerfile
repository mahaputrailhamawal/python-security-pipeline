# Base image
FROM python:3.10-alpine AS build

# Install poetry
RUN pip install poetry

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml poetry.lock /app/

# Project initialization - add --no-root to avoid copying source code
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --no-root

# Copy the rest of the application
COPY . /app/

# Install project with poetry
RUN poetry install --no-interaction --no-ansi

FROM gcr.io/distroless/python3-debian11

# Set working directory in the new stage
WORKDIR /app

# Copy not just the app directory but also python packages
COPY --from=build /usr/local/lib/python3.10/site-packages/ /usr/local/lib/python3.10/site-packages/
COPY --from=build /app /app

# Expose port
EXPOSE 5000

# Set Python path to ensure packages are found
ENV PYTHONPATH=/usr/local/lib/python3.10/site-packages

# Use direct command instead of poetry run
ENTRYPOINT ["python", "/app/app.py"]