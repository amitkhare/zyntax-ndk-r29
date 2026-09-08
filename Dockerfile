FROM debian:bookworm-slim@sha256:7b140f374b289a7c2befc338f42ebe6441b7ea838a042bbd5acbfca6ec875818

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build pkg-config ca-certificates curl git \
    python3 unzip xz-utils patch bison libpcre2-dev && \
    apt-get clean
WORKDIR /work
ENTRYPOINT ["bash"]
