FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl python3 python3-pip python3-venv postgresql-client \
    wkhtmltopdf \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages gdown \
    && gdown "https://drive.google.com/uc?id=1MT9PeAXD_qHNRCaGJUZQ67k0LUOLm3qR" -O /tmp/odoo.deb \
    && apt-get update \
    && apt-get install -y -f /tmp/odoo.deb \
    && rm /tmp/odoo.deb \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 uninstall --break-system-packages -y gdown

EXPOSE 8069 8072

CMD ["odoo", "--db_host=db", "--db_port=5432", "--db_user=odoo", "--db_password=StrongPass2024!", "--data-dir=/var/lib/odoo"]
