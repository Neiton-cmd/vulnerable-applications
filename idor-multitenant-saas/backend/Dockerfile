FROM python:3.12-bookworm

RUN apt-get update && apt-get install -y \
    xvfb \
    cron \
    wget \
    fontconfig \
    libfreetype6 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    && wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && apt-get install -y ./wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && rm wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

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

RUN mkdir -p /var/www/static/reports

COPY crontab /etc/cron.d/vulnshop-cron
RUN chmod 0644 /etc/cron.d/vulnshop-cron

CMD ["sh", "-c", "cron && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
