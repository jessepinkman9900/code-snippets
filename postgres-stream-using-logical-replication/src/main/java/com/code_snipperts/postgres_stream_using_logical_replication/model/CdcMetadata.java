package com.code_snipperts.postgres_stream_using_logical_replication.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;
import java.util.Map;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CdcMetadata {
  private String tableSchema;
  private String tableName;
  private Instant commitTimestamp;
  private Long commitLsn;
  private Integer commitIdx;
  private String idempotencyKey;
  private Map<String, Object> transactionAnnotations;
  private SinkInfo sink;

  @Data
  @Builder
  @NoArgsConstructor
  @AllArgsConstructor
  @JsonInclude(JsonInclude.Include.NON_NULL)
  public static class SinkInfo {
    private String id;
    private String name;
  }
}
