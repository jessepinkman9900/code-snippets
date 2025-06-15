package com.code_snipperts.postgres_stream_using_logical_replication;

import org.springframework.boot.SpringApplication;

public class TestPostgresStreamUsingLogicalReplicationApplication {

  public static void main(String[] args) {
    SpringApplication.from(PostgresStreamUsingLogicalReplicationApplication::main)
        .with(TestcontainersConfiguration.class)
        .run(args);
  }
}
