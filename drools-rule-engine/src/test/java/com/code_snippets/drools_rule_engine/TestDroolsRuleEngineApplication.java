package com.code_snippets.drools_rule_engine;

import com.code_snippets.drools_rule_engine.configs.TestcontainersConfiguration;
import org.springframework.boot.SpringApplication;

public class TestDroolsRuleEngineApplication {
  public static void main(String[] args) {
    SpringApplication.from(DroolsRuleEngineApplication::main)
        .with(TestcontainersConfiguration.class)
        .run(args);
  }
}
