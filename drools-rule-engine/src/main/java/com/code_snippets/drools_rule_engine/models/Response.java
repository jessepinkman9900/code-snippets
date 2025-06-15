package com.code_snippets.drools_rule_engine.models;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Response<T, V> {
  public T request;
  public V validation;
}
