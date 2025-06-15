package com.code_snippets.drools_rule_engine.service;

import com.code_snippets.drools_rule_engine.models.Transaction;
import org.kie.api.runtime.KieSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class TransactionService {
  private static final Logger logger = LoggerFactory.getLogger(TransactionService.class);
  private final KieSession kieSession;

  public TransactionService(KieSession kieSession) {
    this.kieSession = kieSession;
  }

  public Transaction validateTransaction(Transaction transaction) {
    logger.info("Validating transaction: {}", transaction);
    kieSession.insert(transaction);
    kieSession.fireAllRules();
    logger.info("Transaction validation result: {}", transaction);
    return transaction;
  }
}
