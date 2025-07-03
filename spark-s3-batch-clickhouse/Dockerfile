# Dockerfile to create pyspark venv zip
# Use Amazon Linux 2023 with Python 3.11
FROM --platform=linux/amd64 amazonlinux:2023 AS base

# Install Python 3.11 and required build dependencies
RUN yum install -y python3.11

# Set up virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python3.11 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install lz4 msgpack pyspark==3.5.5 venv-pack==0.2.0

# Package the virtual environment
RUN mkdir /output && venv-pack -o /output/pyspark_venv.tar.gz

# Final stage to export the archive
FROM scratch AS export
COPY --from=base /output/pyspark_venv.tar.gz /
