package com.code_snipperts.postgres_stream_using_logical_replication.config;

import io.debezium.embedded.Connect;
import io.debezium.engine.DebeziumEngine;
import io.debezium.engine.RecordChangeEvent;
import io.debezium.engine.format.ChangeEventFormat;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.connect.json.JsonConverter;
import org.apache.kafka.connect.json.JsonConverterConfig;
import org.apache.kafka.connect.source.SourceRecord;
import org.apache.kafka.connect.storage.ConverterConfig;
import org.apache.kafka.connect.storage.ConverterType;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.KafkaTemplate;

@Configuration
@Slf4j
public class DebeziumConfig {
  private final ExecutorService executor;
  private final DebeziumEngine<RecordChangeEvent<SourceRecord>> debeziumEngine;
  private final ApplicationConfig applicationConfig;
  private final KafkaTemplate<String, String> kafkaTemplate;

  public DebeziumConfig(
      ApplicationConfig applicationConfig, KafkaTemplate<String, String> kafkaTemplate) {
    this.applicationConfig = applicationConfig;
    this.kafkaTemplate = kafkaTemplate;
    this.executor = Executors.newSingleThreadExecutor();
    Properties props = new Properties();

    // Connector configuration
    props.setProperty("name", "postgres-connector");
    props.setProperty("connector.class", "io.debezium.connector.postgresql.PostgresConnector");

    // Offset storage configuration - using Kafka for offset storage
    props.setProperty("offset.storage", "org.apache.kafka.connect.storage.KafkaOffsetBackingStore");
    props.setProperty(
        "offset.storage.topic", applicationConfig.getKafka().getOffset_storage_topic());
    props.setProperty(
        "offset.storage.partitions",
        String.valueOf(applicationConfig.getKafka().getOffset_storage_partitions()));
    props.setProperty(
        "offset.storage.replication.factor",
        String.valueOf(applicationConfig.getKafka().getOffset_storage_replication_factor()));
    props.setProperty(
        "offset.flush.interval.ms",
        String.valueOf(
            applicationConfig.getPostgres().getReplication().getOffset_flush_interval_ms()));

    // Kafka broker configuration for offset storage
    props.setProperty(
        "offset.storage.kafka.bootstrap.servers",
        applicationConfig.getKafka().getBootstrap_servers());
    // Set the bootstrap.servers property directly for the offset storage
    props.setProperty("bootstrap.servers", applicationConfig.getKafka().getBootstrap_servers());
    // Configure the offset storage topic
    props.setProperty(
        "offset.storage.kafka.topic", applicationConfig.getKafka().getOffset_storage_topic());
    // Ensure the topic is created if it doesn't exist
    props.setProperty(
        "offset.storage.topic", applicationConfig.getKafka().getOffset_storage_topic());

    // Topic naming
    props.setProperty("topic.prefix", applicationConfig.getKafka().getTopic_name() + "-");

    // Set database connection details
    props.setProperty("database.hostname", "localhost");
    props.setProperty("database.port", "5432");
    String jdbcUrl = applicationConfig.getPostgres().getUrl();
    String dbName = jdbcUrl.substring(jdbcUrl.lastIndexOf('/') + 1);
    props.setProperty("database.user", applicationConfig.getPostgres().getUsername());
    props.setProperty("database.password", applicationConfig.getPostgres().getPassword());
    props.setProperty("database.dbname", dbName);
    props.setProperty(
        "database.server.name", applicationConfig.getPostgres().getReplication().getServer_name());

    // Replication configuration
    props.setProperty(
        "plugin.name", applicationConfig.getPostgres().getReplication().getPlugin_name());
    props.setProperty("slot.name", applicationConfig.getPostgres().getReplication().getSlot_name());
    props.setProperty(
        "publication.name",
        applicationConfig.getPostgres().getReplication().getPublication_names());

    // Table filtering
    props.setProperty(
        "table.include.list",
        applicationConfig.getPostgres().getReplication().getTable_include_list());

    // Additional configurations
    props.setProperty(
        "include.schema.changes",
        String.valueOf(
            applicationConfig.getPostgres().getReplication().isInclude_schema_changes()));
    props.setProperty(
        "snapshot.mode", applicationConfig.getPostgres().getReplication().getSnapshot_mode());

    // Performance tuning
    props.setProperty("max.batch.size", "1000");
    props.setProperty("max.queue.size", "8192");
    props.setProperty("poll.interval.ms", "500");

    this.debeziumEngine =
        DebeziumEngine.create(ChangeEventFormat.of(Connect.class))
            .using(props)
            .notifying(this::handleChangeEvent)
            .build();
  }

  @PostConstruct
  private void start() {
    this.executor.execute(debeziumEngine);
  }

  @PreDestroy
  private void stop() throws IOException {
    if (this.debeziumEngine != null) {
      this.debeziumEngine.close();
    }
  }

  private void handleChangeEvent(RecordChangeEvent<SourceRecord> event) {
    SourceRecord sourceRecord = event.record();
    JsonConverter keyConverter = null;
    JsonConverter valueConverter = null;

    try {
      // Initialize converters
      keyConverter = new JsonConverter();
      valueConverter = new JsonConverter();

      // Transform the record
      Map.Entry<String, String> transformedRecord =
          transformRecord(sourceRecord, keyConverter, valueConverter);

      // Publish to Kafka
      publishToKafka(transformedRecord.getKey(), transformedRecord.getValue());

      // Log source metadata for debugging
      logSourceMetadata(sourceRecord);

    } catch (Exception e) {
      log.error("Error processing change event: {}", e.getMessage(), e);
    } finally {
      closeConverters(keyConverter, valueConverter);
    }
  }

  private Map.Entry<String, String> transformRecord(
      SourceRecord sourceRecord, JsonConverter keyConverter, JsonConverter valueConverter)
      throws Exception {
    // Configure the converters
    Map<String, String> converterConfig = new HashMap<>();
    converterConfig.put(JsonConverterConfig.SCHEMAS_ENABLE_CONFIG, "false");

    // Configure key converter
    converterConfig.put(ConverterConfig.TYPE_CONFIG, ConverterType.KEY.getName());
    keyConverter.configure(converterConfig, true);

    // Configure value converter
    converterConfig.put(ConverterConfig.TYPE_CONFIG, ConverterType.VALUE.getName());
    valueConverter.configure(converterConfig, false);

    // Convert key and value to JSON bytes
    byte[] keyBytes =
        keyConverter.fromConnectData(
            sourceRecord.topic(), sourceRecord.keySchema(), sourceRecord.key());
    byte[] valueBytes =
        valueConverter.fromConnectData(
            sourceRecord.topic(), sourceRecord.valueSchema(), sourceRecord.value());

    // Convert bytes to JSON strings and return as a Map Entry
    return Map.entry(
        keyBytes != null ? new String(keyBytes) : "",
        valueBytes != null ? new String(valueBytes) : "");
  }

  private void publishToKafka(String key, String value) {
    kafkaTemplate.send(applicationConfig.getKafka().getTopic_name(), key, value);
    log.info("Published change event to Kafka - Key: {}, Value: {}", key, value);
  }

  private void logSourceMetadata(SourceRecord sourceRecord) {
    if (sourceRecord.sourceOffset() != null && !sourceRecord.sourceOffset().isEmpty()) {
      log.debug("Source offset: {}", sourceRecord.sourceOffset());
    }
    if (sourceRecord.sourcePartition() != null && !sourceRecord.sourcePartition().isEmpty()) {
      log.debug("Source partition: {}", sourceRecord.sourcePartition());
    }
  }

  private void closeConverters(JsonConverter keyConverter, JsonConverter valueConverter) {
    // Close key converter
    if (keyConverter != null) {
      try {
        keyConverter.close();
      } catch (Exception e) {
        log.warn("Error closing key converter: {}", e.getMessage());
      }
    }
    // Close value converter
    if (valueConverter != null) {
      try {
        valueConverter.close();
      } catch (Exception e) {
        log.warn("Error closing value converter: {}", e.getMessage());
      }
    }
  }
}
