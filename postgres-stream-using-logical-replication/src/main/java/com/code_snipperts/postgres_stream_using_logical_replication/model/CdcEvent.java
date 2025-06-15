package com.code_snipperts.postgres_stream_using_logical_replication.model;

import com.fasterxml.jackson.annotation.JsonInclude;
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
public class CdcEvent {
  private Map<String, Object> record;
  private Map<String, Object> changes;
  private Action action;
  private CdcMetadata metadata;

  public enum Action {
    INSERT,
    UPDATE,
    DELETE,
    READ
  }
}
