package com.code_snippets.drools_rule_engine.models;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Transaction {
  private String id;
  private String type;
  private double amount;
  private String currency;
  private boolean valid = true;
  private String message;

  // Helper method to mark transaction as invalid with a message
  public void reject(String message) {
    this.valid = false;
    this.message = message;
  }
}
