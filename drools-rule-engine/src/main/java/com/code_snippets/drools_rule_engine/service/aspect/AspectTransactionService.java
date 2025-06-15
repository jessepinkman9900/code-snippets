package com.code_snippets.drools_rule_engine.service.aspect;

import com.code_snippets.drools_rule_engine.models.Response;
import com.code_snippets.drools_rule_engine.models.Transaction;
import com.code_snippets.drools_rule_engine.models.ValidationResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class AspectTransactionService {
  private static final Logger logger = LoggerFactory.getLogger(AspectTransactionService.class);

  public Response<Transaction, ValidationResult> processTransaction(Transaction transaction) {
    logger.info("Processing transaction: {}", transaction);
    return new Response<>(transaction, null);
  }
}
