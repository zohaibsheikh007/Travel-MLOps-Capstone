FROM apache/airflow:2.10.5-python3.11

# All required wheels are available pre-built; no compiler toolchain needed.
USER airflow
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt
