FROM node:12
LABEL "repository"=""
LABEL "maintainer"="Zulbukharov"

RUN apt-get update && \
apt-get -y upgrade && \
apt-get install -y git curl

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

