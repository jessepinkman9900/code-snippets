package com.code_snippets.drools_rule_engine.service.aspect;

import com.code_snippets.drools_rule_engine.models.Transaction;
import com.code_snippets.drools_rule_engine.models.ValidationResult;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.kie.api.runtime.KieSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Aspect
@Component
public class ValidationAspect {
  private static final Logger logger = LoggerFactory.getLogger(ValidationAspect.class);
  private final KieSession kieSession;

  public ValidationAspect(KieSession kieSession) {
    this.kieSession = kieSession;
  }

  @Before(
      "execution(* com.code_snippets.drools_rule_engine.service.aspect.AspectTransactionService.processTransaction(com.code_snippets.drools_rule_engine.models.Transaction))")
  public void validateTransaction(Transaction transaction) {
    logger.info("Validating transaction: {}", transaction);
    ValidationResult validationResult = new ValidationResult();
    kieSession.setGlobal("validationResult", validationResult);
    kieSession.insert(transaction);
    kieSession.fireAllRules();
    logger.info("Transaction validation result: {}", transaction);
    if (!validationResult.isValid()) {
      throw new IllegalArgumentException(validationResult.getMessage());
    }
  }
}
