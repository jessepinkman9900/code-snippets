# from: https://github.com/Mooncake-Labs/pg_mooncake/blob/main/Dockerfile
FROM postgres:17 AS base

FROM base AS build

RUN apt update \
 && apt install -y \
    cmake \
    curl \
    git \
    g++ \
    liblz4-dev \
    pkg-config \
    postgresql-server-dev-17 \
 && rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs | sh -s -- -y

ENV PATH="/root/.cargo/bin:$PATH"

RUN cargo install --locked cargo-pgrx@0.15.0 \
 && cargo pgrx init --pg17=$(which pg_config)

COPY . /pgrx_data_retention

RUN cd /pgrx_data_retention \
 && PG_VERSION=pg17 \
 && cargo pgrx package


FROM base

COPY --from=build /pgrx_data_retention/target/release/pgrx_data_retention-pg17/ /

RUN cat >> /usr/share/postgresql/postgresql.conf.sample <<EOF
shared_preload_libraries = 'pgrx_data_retention'
wal_level = logical
EOF

ENV RUST_BACKTRACE="1"
