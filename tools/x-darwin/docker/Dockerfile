FROM node:22-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      jq \
      postgresql-client \
      kafkacat \
    && rm -rf /var/lib/apt/lists/*

COPY update_client_config.sh /tools/update_client_config.sh
COPY read_client_config.sh /tools/read_client_config.sh
COPY read_application.sh /tools/read_application.sh
RUN chmod +x /tools/update_client_config.sh /tools/read_client_config.sh /tools/read_application.sh

ENTRYPOINT ["bash"]
