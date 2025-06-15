package com.code_snippets.drools_rule_engine;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

@SpringBootApplication
@EnableAspectJAutoProxy
public class DroolsRuleEngineApplication {

  public static void main(String[] args) {
    SpringApplication.run(DroolsRuleEngineApplication.class, args);
  }
}
