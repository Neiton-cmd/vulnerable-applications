FROM python:3.12-bookworm

RUN useradd -m -s /bin/bash jonny && \
    mkdir -p /home/jonny/.ssh && \
    chmod 700 /home/jonny/.ssh && \
    chown jonny:jonny /home/jonny/.ssh

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# jonny's SSH key — used by the report upload job (scp to backup.omni.htb)
COPY secrets/jonny_id_rsa /home/jonny/.ssh/id_rsa
RUN chmod 600 /home/jonny/.ssh/id_rsa && \
    chown jonny:jonny /home/jonny/.ssh/id_rsa

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
