package com.code_snippets.decision_engine;

import org.springframework.boot.SpringApplication;

public class TestDecisionEngineApplication {

  public static void main(String[] args) {
    SpringApplication.from(DecisionEngineApplication::main)
        .with(TestcontainersConfiguration.class)
        .run(args);
  }
}
