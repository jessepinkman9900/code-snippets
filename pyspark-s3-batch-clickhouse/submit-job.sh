#!/bin/bash

# check for env variables
if [ -z "$AWS_EMR_S3_BUCKET" ] || [ -z "$AWS_EMR_JOB_NAME" ] || [ -z "$AWS_EMR_SERVERLESS_APPLICATION_ID" ] || [ -z "$AWS_EMR_SERVERLESS_EXECUTION_ROLE_ARN" ] || [ -z "$CLICKHOUSE_HOST" ] || [ -z "$CLICKHOUSE_HTTP_PORT" ] || [ -z "$CLICKHOUSE_USER" ] || [ -z "$CLICKHOUSE_PASSWORD" ] || [ -z "$CLICKHOUSE_DATABASE" ] || [ -z "$START_BLOCK" ] || [ -z "$END_BLOCK" ]; then
    echo "Error: One or more environment variables are not set."
    exit 1
fi

# utils
format_number() {
    local result=$(bc -l <<< "scale=3; $1 / 1000000")
    result=$(echo $result | sed 's/\.000$//;s/0*$//;s/\.$//;')
    echo "${result}m"
}
start_prefix=$(format_number $START_BLOCK)
end_prefix=$(format_number $END_BLOCK)

# copy target folder to s3
echo "Copying target folder to s3..."
aws s3 cp target s3://"$AWS_EMR_S3_BUCKET"/"$AWS_EMR_JOB_NAME"/target --recursive --profile "$AWS_PROFILE"
echo "Target folder copied to s3."

# submit job
echo "Submitting job..."
aws emr-serverless start-job-run \
    --name "$AWS_EMR_JOB_NAME-$start_prefix-$end_prefix" \
    --application-id $AWS_EMR_SERVERLESS_APPLICATION_ID \
    --execution-role-arn $AWS_EMR_SERVERLESS_EXECUTION_ROLE_ARN \
    --execution-timeout-minutes 240 \
    --job-driver '{
      "sparkSubmit": {
        "entryPoint": "s3://'$AWS_EMR_S3_BUCKET'/'$AWS_EMR_JOB_NAME'/target/s3-block-data-indexer.py",
        "entryPointArguments": ["--start-block", "'$START_BLOCK'", "--end-block", "'$END_BLOCK'", "--spotsend-block-header-table", "'$SPOTSEND_BLOCK_HEADER_TABLE'", "--spotsend-block-txn-table", "'$SPOTSEND_BLOCK_TXN_TABLE'"],
        "sparkSubmitParameters": "--conf spark.archives=s3://'$AWS_EMR_S3_BUCKET'/'$AWS_EMR_JOB_NAME'/target/pyspark_venv.tar.gz#environment --conf spark.jars=s3://'$AWS_EMR_S3_BUCKET'/'$AWS_EMR_JOB_NAME'/target/jars/clickhouse-spark-runtime-3.5_2.12-0.8.0.jar,s3://'$AWS_EMR_S3_BUCKET'/'$AWS_EMR_JOB_NAME'/target/jars/clickhouse-client-0.8.0.jar,s3://'$AWS_EMR_S3_BUCKET'/'$AWS_EMR_JOB_NAME'/target/jars/clickhouse-data-0.8.0.jar,s3://'$AWS_EMR_S3_BUCKET'/'$AWS_EMR_JOB_NAME'/target/jars/clickhouse-http-client-0.8.0.jar,s3://'$AWS_EMR_S3_BUCKET'/'$AWS_EMR_JOB_NAME'/target/jars/httpclient5-5.4.1.jar,s3://'$AWS_EMR_S3_BUCKET'/'$AWS_EMR_JOB_NAME'/target/jars/httpcore5-5.4.1.jar --conf spark.emr-serverless.driverEnv.PYSPARK_DRIVER_PYTHON=./environment/bin/python --conf spark.emr-serverless.driverEnv.PYSPARK_PYTHON=./environment/bin/python --conf spark.executorEnv.PYSPARK_PYTHON=./environment/bin/python --conf spark.driverEnv.PYSPARK_PYTHON=./environment/bin/python --conf spark.hadoop.fs.s3a.requester.pays.enabled=true --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem --conf spark.sql.catalog.clickhouse=com.clickhouse.spark.ClickHouseCatalog --conf spark.sql.catalog.clickhouse.host='$CLICKHOUSE_HOST' --conf spark.sql.catalog.clickhouse.protocol='https' --conf spark.sql.catalog.clickhouse.http_port='$CLICKHOUSE_HTTP_PORT' --conf spark.sql.catalog.clickhouse.user='$CLICKHOUSE_USER' --conf spark.sql.catalog.clickhouse.password='$CLICKHOUSE_PASSWORD' --conf spark.sql.catalog.clickhouse.database='$CLICKHOUSE_DATABASE' --conf spark.sql.catalog.clickhouse.option.ssl=true --conf spark.sql.catalog.clickhouse.option.ssl_mode=NONE --conf spark.clickhouse.write.format=json --conf spark.clickhouse.write.batchSize='$CLICKHOUSE_WRITE_BATCH_SIZE' --conf spark.driver.cores=2 --conf spark.driver.memory=4G --conf spark.executor.cores=2 --conf spark.executor.memory=4G --conf spark.executor.instances=6"
      }
    }'
