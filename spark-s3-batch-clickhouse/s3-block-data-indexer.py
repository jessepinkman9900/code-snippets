import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp

logger = logging.getLogger(__name__)


def get_file_paths(start_block: int, end_block: int):
    a_size = 100_000_000
    b_size = 100_000
    c_size = 100
    file_paths = []
    for block in range(start_block, end_block + c_size, c_size):
        a = block // a_size * a_size
        b = block // b_size * b_size
        c = block // c_size * c_size
        file_paths.append(
            f"s3://hl-mainnet-node-data/explorer_blocks/{a}/{b}/{c}.rmp.lz4"
        )
    return file_paths


def index_s3_block_data(args):
    def get_folder_paths(start_block: int, end_block: int):
        a_size = 100_000_000
        b_size = 100_000
        c_size = 100
        file_paths = []
        for block in range(start_block, end_block + c_size, c_size):
            dir_block = block - 1 if block > 0 else 0
            a = ((dir_block) // a_size) * a_size
            b = ((dir_block) // b_size) * b_size
            # c = ((block) // c_size) * c_size
            file_paths.append(f"s3a://hl-mainnet-node-data/explorer_blocks/{a}/{b}/")
        return set(file_paths)

    def create_spark_session():
        spark = SparkSession.builder.appName(
            "Hyperliquid L1 - S3 Block Data Indexer"
        ).getOrCreate()
        return spark

    def decompress_and_unpack_msgpack(binary_content):
        import lz4.frame
        import msgpack

        """
        Decompresses LZ4 data and then unpacks the MessagePack content.
        This function is designed to be used in a PySpark UDF.
        """
        try:
            decompressed_data = lz4.frame.decompress(binary_content)
            unpacked_data = msgpack.unpackb(decompressed_data, raw=False)
            return unpacked_data
        except Exception as e:
            # It's good practice to handle potential errors in UDFs
            return [("Error", f"Failed to process file: {e}")]

    def process_file_data(file_data):
        """
        Given file path & binary content, decompress and unpack the MessagePack content
        Returns a dictionary with file path & unpacked data
        """
        file_path, content = file_data
        try:
            # Here you can process the binary content
            # For now, just log the file info
            print(f"Processing file: {file_path}, size: {len(content)} bytes")
            json_data_rdd = decompress_and_unpack_msgpack(content)
            print(f"Decompressed and unpacked data: {json_data_rdd}")
            # s3a://hl-mainnet-node-data/explorer_blocks/0/0/500.rmp.lz4
            return {"file_path": file_path, "data": json_data_rdd}
        except Exception as e:
            print(f"Error processing file {file_path}: {str(e)}")
            return None

    def load_block_headers_into_clickhouse(files_rdd):
        """
        Given an RDD of (filePath, unpackedData), load the block headers into ClickHouse
        """

        def map_block_headers(record):
            block_headers = []
            blocks = record.get("data")

            for block in blocks:
                header = block.get("header")

                block_header = {
                    "file_path": record.get("file_path"),
                    "block_time": header.get("block_time"),
                    "height": header.get("height"),
                    "hash": header.get("hash"),
                    "proposer": header.get("proposer"),
                }
                block_headers.append(block_header)

            return block_headers

        block_header_rdd = files_rdd.map(process_file_data).flatMap(map_block_headers)
        block_header_df = spark.createDataFrame(block_header_rdd)
        # Add timestamp column representing processing time
        block_header_df = block_header_df.withColumn(
            "processed_at", current_timestamp()
        )

        # Write data to the table with batch size of 50k
        block_header_df.select(
            "file_path", "block_time", "height", "hash", "proposer", "processed_at"
        ).writeTo("clickhouse.test_l1_raw.block_headers").append()

    def load_block_transactions_into_clickhouse(files_rdd):
        """
        Given an RDD of (filePath, unpackedData), load the block transactions into ClickHouse
        """

        def map_block_txns(record):
            import json

            block_txs = []
            blocks = record.get("data")

            for block in blocks:
                header = block.get("header")
                txs = block.get("txs")

                for tx in txs:
                    block_tx = {
                        "file_path": record.get("file_path"),
                        "block_time": header.get("block_time"),
                        "height": header.get("height"),
                        "actions": json.dumps(tx.get("actions")),
                        "user": tx.get("user"),
                        "raw_tx_hash": tx.get("raw_tx_hash"),
                        "error": ""
                        if tx.get("error") is None
                        else json.dumps(tx.get("error")),
                    }
                    block_txs.append(block_tx)

            return block_txs

        block_tx_rdd = files_rdd.map(process_file_data).flatMap(map_block_txns)
        block_tx_df = spark.createDataFrame(block_tx_rdd)
        # Add timestamp column representing processing time
        block_tx_df = block_tx_df.withColumn("processed_at", current_timestamp())

        # Write data to the table with batch size of 50k
        block_tx_df.select(
            "file_path",
            "block_time",
            "height",
            "actions",
            "user",
            "raw_tx_hash",
            "error",
            "processed_at",
        ).writeTo("clickhouse.test_l1_raw.block_txns").append()

    with create_spark_session() as spark:
        folder_paths = get_folder_paths(args.start_block, args.end_block)

        # Load files using binaryFiles which returns an RDD of (filePath, fileContent) pairs
        file_data_rdd = spark.sparkContext.binaryFiles(",".join(folder_paths))

        # process files
        load_block_headers_into_clickhouse(file_data_rdd)
        load_block_transactions_into_clickhouse(file_data_rdd)

        return


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--start-block", type=int, required=True)
    parser.add_argument("--end-block", type=int, required=True)
    args = parser.parse_args()

    index_s3_block_data(args)
