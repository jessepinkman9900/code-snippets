package com.code_snippets.drools_rule_engine.models;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ValidationResult {
  public boolean valid;
  public String message;

  public ValidationResult() {
    this.valid = true;
    this.message = "Transaction is valid";
  }
}
