package com.code_snippets.drools_rule_engine.controllers;

import com.code_snippets.drools_rule_engine.models.Transaction;
import com.code_snippets.drools_rule_engine.service.TransactionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/transactions")
public class TransactionController {
  private final TransactionService transactionService;

  @Autowired
  public TransactionController(TransactionService transactionService) {
    this.transactionService = transactionService;
  }

  @PostMapping("/validate")
  public Transaction validateTransaction(@RequestBody Transaction transaction) {
    return transactionService.validateTransaction(transaction);
  }
}
