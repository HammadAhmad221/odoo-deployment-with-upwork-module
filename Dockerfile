FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl git python3 python3-pip python3-venv postgresql-client \
    wkhtmltopdf \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages gdown \
    && gdown "https://drive.google.com/uc?id=1MT9PeAXD_qHNRCaGJUZQ67k0LUOLm3qR" -O /tmp/odoo.deb \
    && apt-get update \
    && apt-get install -y -f /tmp/odoo.deb \
    && rm /tmp/odoo.deb \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 uninstall --break-system-packages -y gdown

# Install custom addon: Upwork Bid Tracker
# ADD on the commits API changes whenever main advances, busting the layer cache below.
ADD https://api.github.com/repos/HammadAhmad221/odoo-upwork-module/commits/main /tmp/addon-rev.json
RUN mkdir -p /mnt/extra-addons \
    && git clone --depth 1 https://github.com/HammadAhmad221/odoo-upwork-module.git /mnt/extra-addons/upwork_bid_tracker \
    && rm -rf /mnt/extra-addons/upwork_bid_tracker/.git \
    && rm -rf /mnt/extra-addons/upwork_bid_tracker/__pycache__ \
    && rm -f /tmp/addon-rev.json \
    && chown -R odoo:odoo /mnt/extra-addons

COPY entrypoint.sh /usr/local/bin/odoo-entrypoint.sh
RUN chmod +x /usr/local/bin/odoo-entrypoint.sh

EXPOSE 8069 8072

CMD ["/usr/local/bin/odoo-entrypoint.sh"]
