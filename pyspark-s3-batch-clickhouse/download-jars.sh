#!/bin/bash

# This script downloads a list of specified JAR files from the Maven Central repository.
# It uses curl with the -O flag, which saves the files in the current directory
# with their original names.

# Set the base URL for Maven Central
BASE_URL="https://repo1.maven.org/maven2"

# Create an array of the JAR files to download
JARS=(
    "com/clickhouse/spark/clickhouse-spark-runtime-3.5_2.12/0.8.0/clickhouse-spark-runtime-3.5_2.12-0.8.0.jar"
    "com/clickhouse/clickhouse-client/0.8.0/clickhouse-client-0.8.0.jar"
    "com/clickhouse/clickhouse-data/0.8.0/clickhouse-data-0.8.0.jar"
    "com/clickhouse/clickhouse-http-client/0.8.0/clickhouse-http-client-0.8.0.jar"
    "org/apache/httpcomponents/client5/httpclient5/5.4.1/httpclient5-5.4.1.jar"
    "org/apache/httpcomponents/core5/httpcore5/5.4.1/httpcore5-5.4.1.jar"
)
# --- Script Start ---

echo "Starting download of JAR files..."
echo "-------------------------------------"

# Loop through the array and download each JAR
for jar_path in "${JARS[@]}"; do
    # Construct the full URL
    URL="${BASE_URL}/${jar_path}"

    # Get the filename from the path
    FILENAME=$(basename "$jar_path")

    echo "Downloading: ${FILENAME}"

    # Use curl to download the file.
    # -O: Save the file with the remote name.
    # -L: Follow redirects, if any.
    # -s: Silent mode (don't show progress meter).
    # -S: Show error message on failure.
    curl -OLsS "$URL"

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo " -> Success."
    else
        echo " -> FAILED. Check the URL or your network connection."
    fi
done

echo "-------------------------------------"
echo "All downloads attempted."
