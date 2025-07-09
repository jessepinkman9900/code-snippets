import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp
from pyspark.sql.functions import sha2
from pyspark.sql.functions import concat_ws
import lz4.frame
import msgpack
import json


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
        try:
            decompressed_data = lz4.frame.decompress(binary_content)
            unpacked_data = msgpack.unpackb(decompressed_data, raw=False)
            return unpacked_data
        except Exception as e:
            return [("Error", f"Failed to process file: {e}")]

    def process_file_data(file_data):
        """
        Given file path & binary content, decompress and unpack the MessagePack content
        Returns a dictionary with file path & unpacked data
        """
        file_path, content = file_data
        try:
            # file_path: s3a://hl-mainnet-node-data/explorer_blocks/0/0/500.rmp.lz4
            print(f"INFO Processing file: {file_path}, size: {len(content)} bytes")
            json_data_rdd = decompress_and_unpack_msgpack(content)
            return {"file_path": file_path, "data": json_data_rdd}
        except Exception as e:
            print(f"ERROR Error processing file {file_path}: {str(e)}")
            return None
    
    def map_block_txns(record):
        block_txs = []
        blocks = record.get("data")

        for block in blocks:
            header = block.get("header")
            txs = block.get("txs")
            print(f"INFO Processing file {record.get('file_path')} {header} txns: {len(txs)}")

            for idx, tx in enumerate(txs):
                try:
                    actions = tx.get("actions")
                    if actions and any(action.get("type") == "evmRawTx" for action in actions):
                        continue

                    raw_tx_hash = tx.get("raw_tx_hash")
                    serializable_hash = f"0x{raw_tx_hash}" if isinstance(raw_tx_hash, bytes) else f"{raw_tx_hash}"

                    block_tx = {
                        "file_path": record.get("file_path"),
                        "block_time": header.get("block_time"),
                        "height": header.get("height"),
                        "tx_idx": idx,
                        "actions": json.dumps(tx.get("actions")),
                        "user": tx.get("user"),
                        "raw_tx_hash": serializable_hash,
                        "error": ""
                        if tx.get("error") is None
                        else json.dumps(tx.get("error")),
                    }
                    block_txs.append(block_tx)
                except Exception as e:
                    print(f"ERROR Error map_block_txns processing file {record.get('file_path')}: {str(e)} {record}")
        
        print(f"INFO Processed file {record.get('file_path')} {header} l1 txns: {len(txs)} l1 non-evm txns: {len(block_txs)}")
        return block_txs

    def map_block_headers(record):
        try:
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
        except Exception as e:
            print(f"ERROR Error map_block_headers file {record.get('file_path')}: {str(e)} {record}")
            return []

    def map_flatten_spotSend_tx(tx_record):
        try:
            spotSendActions = []
            if tx_record.get("actions") is None:
                return []
            actions = json.loads(tx_record.get("actions"))
            for idx, action in enumerate(actions):
                if action.get("type") == "spotSend":
                    tx_record["action_index"] = idx
                    tx_record["signature_chain_id"] = action.get("signatureChainId")
                    tx_record["hyperliquid_chain"] = action.get("hyperliquidChain")
                    tx_record["destination"] = action.get("destination")
                    tx_record["token"] = action.get("token")
                    tx_record["amount"] = action.get("amount")
                    tx_record["time"] = action.get("time")
                    spotSendActions.append(tx_record)

            return spotSendActions
        except Exception as e:
            print(f"ERROR Error map_flatten_spotSend_tx file {record.get('file_path')}: {str(e)} {record}")
            return []

    def load_block_headers_into_clickhouse(spotsend_block_header_table, files_rdd):
        """
        Given an RDD of (filePath, unpackedData), load the block headers into ClickHouse
        """
        try:
            block_header_rdd = files_rdd.map(process_file_data).flatMap(map_block_headers)
            block_header_df = spark.createDataFrame(block_header_rdd)
            # Add timestamp column representing processing time
            block_header_df = block_header_df.withColumn(
                "processed_at", current_timestamp()
            )

            # Write data to the table with batch size of 50k
            print(f"INFO Writing block headers to ClickHouse for {block_header_df.count()} rows")
            block_header_df.select(
                "file_path", "block_time", "height", "hash", "proposer", "processed_at"
            ).writeTo(spotsend_block_header_table).append()
        except Exception as e:
            one_of_the_files = files_rdd.take(1)[0][0]
            print(f"ERROR Error creating DataFrame and writing to ClickHouse for block headers one of the files in file_rdd: {one_of_the_files}: {str(e)}")
            raise e

    def load_block_transactions_into_clickhouse(files_rdd):
        """
        Given an RDD of (filePath, unpackedData), load the block transactions into ClickHouse
        """
        try:
            block_tx_rdd = files_rdd.map(process_file_data).flatMap(map_block_txns)
            block_tx_df = spark.createDataFrame(block_tx_rdd)
            block_tx_df = block_tx_df.withColumn("processed_at", current_timestamp())

            # add custom md5 hash
            block_tx_df = block_tx_df.withColumn("height_index_user_actions_concat", concat_ws("-", block_tx_df.height, block_tx_df.tx_idx, block_tx_df.user, block_tx_df.actions))\
                .withColumn("custom_md5", sha2("height_index_user_actions_concat", 256))
            # Add timestamp column representing processing time
            block_tx_df = block_tx_df.withColumn("processed_at", current_timestamp())

            # Write data to the table with batch size of 50k
            print(f"INFO Writing block transactions to ClickHouse for {block_tx_df.count()} rows")
            block_tx_df.select(
                "file_path","block_time","height","tx_idx","actions","user","raw_tx_hash","error","custom_md5","processed_at",
            ).writeTo("clickhouse.test_l1_raw.block_txs").append()
        except Exception as e:
            one_of_the_files = files_rdd.take(1)[0][0]
            print(f"ERROR Error creating DataFrame and writing to ClickHouse for block transactions one of the files in file_rdd: {one_of_the_files}: {str(e)}")
            raise e
    
    def load_block_transactions_spotSend_into_clickhouse(spotsend_block_txn_table, files_rdd):
        try:
            block_tx_rdd = files_rdd.map(process_file_data)\
                .flatMap(map_block_txns)\
                .filter(lambda row: 'spotSend' in row['actions'])\
                .flatMap(map_flatten_spotSend_tx)
            block_tx_df = spark.createDataFrame(block_tx_rdd)
            block_tx_df = block_tx_df.withColumn("processed_at", current_timestamp())

            # add custom md5 hash
            block_tx_df = block_tx_df.withColumn("height_index_user_actions_concat", concat_ws("-", block_tx_df.height, block_tx_df.tx_idx, block_tx_df.user, block_tx_df.actions))\
                .withColumn("custom_md5", sha2("height_index_user_actions_concat", 256))
            # Add timestamp column representing processing time
            block_tx_df = block_tx_df.withColumn("processed_at", current_timestamp())

            # Write data to the table with batch size of 50k
            print(f"INFO Writing block transactions spotSend to ClickHouse for {block_tx_df.count()} rows")
            block_tx_df.select(
                "file_path","block_time","height","tx_idx","actions","user","raw_tx_hash","error","action_index",
                "hyperliquid_chain","signature_chain_id","time","amount","destination","token","custom_md5","processed_at"
            ).writeTo(spotsend_block_txn_table).append()
        except Exception as e:
            one_of_the_files = files_rdd.take(1)[0][0]
            print(f"ERROR Error creating DataFrame and writing to ClickHouse for block transactions one of the files in file_rdd: {one_of_the_files}: {str(e)}")
            raise e
    
    with create_spark_session() as spark:
        folder_paths = get_folder_paths(args.start_block, args.end_block)

        # Load files using binaryFiles which returns an RDD of (filePath, fileContent) pairs
        file_data_rdd = spark.sparkContext.binaryFiles(",".join(folder_paths))

        # process files
        load_block_transactions_spotSend_into_clickhouse(args.spotsend_block_txn_table, file_data_rdd)
        load_block_headers_into_clickhouse(args.spotsend_block_header_table, file_data_rdd)

        return


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--start-block", type=int, required=True)
    parser.add_argument("--end-block", type=int, required=True)
    parser.add_argument("--spotsend-block-header-table", type=str, required=True)
    parser.add_argument("--spotsend-block-txn-table", type=str, required=True)
    args = parser.parse_args()

    index_s3_block_data(args)
