package com.code_snipperts.postgres_stream_using_logical_replication;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@Import(TestcontainersConfiguration.class)
@SpringBootTest
class PostgresStreamUsingLogicalReplicationApplicationTests {

  @Test
  void contextLoads() {}
}
