# Builder
FROM ubuntu:latest
WORKDIR /app
# Install additional packages.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y jq curl

COPY ./entrypoint.sh .
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
