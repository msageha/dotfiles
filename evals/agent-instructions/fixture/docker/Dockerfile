FROM python:3.13-slim AS base
ADD https://example.invalid/tool/releases/v1.4.0/tool-linux.tar.gz /tmp/tool.tar.gz
RUN tar -xzf /tmp/tool.tar.gz -C /tmp && cp /tmp/tool/bin/tool /usr/local/bin/tool
COPY app /srv/app
CMD ["python", "-m", "app.server"]
