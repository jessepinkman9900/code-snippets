package com.code_snipperts.postgres_stream_using_logical_replication.config;

import jakarta.annotation.PostConstruct;
import lombok.Data;
import lombok.Getter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Getter
@Configuration
@ConfigurationProperties(prefix = "application")
public class ApplicationConfig {
  public PostgresConfig postgres;
  public KafkaConfig kafka;

  @Data
  @Getter
  public static class PostgresConfig {
    public String url;
    public String username;
    public String password;
    public ReplicationConfig replication;
    public int status_interval_ms;
  }

  @Data
  @Getter
  public static class KafkaConfig {
    private String topic_name;
    private String bootstrap_servers;
    private String consumer_group_id;
    private String offset_storage_topic;
    private int offset_storage_partitions;
    private short offset_storage_replication_factor;
    private Integer max_poll_records;
    private Integer max_poll_interval_ms;
    private Integer session_timeout_ms;
    private Integer heartbeat_interval_ms;
    private String auto_offset_reset;
    private Boolean enable_auto_commit;
    private Integer auto_commit_interval_ms;
  }

  @Data
  @Getter
  public static class ReplicationConfig {
    public String slot_name;
    public String plugin_name;
    public String publication_names;
    public String server_name = "dbserver1";
    public String offset_storage = "/tmp/offsets.dat";
    public long offset_flush_interval_ms = 60000;
    public String table_include_list = "public.*";
    public boolean include_schema_changes = false;
    public String snapshot_mode = "never";
  }

  @PostConstruct
  public void init() {
    // print the config
    System.out.println("ApplicationConfig: " + this);
  }
}
