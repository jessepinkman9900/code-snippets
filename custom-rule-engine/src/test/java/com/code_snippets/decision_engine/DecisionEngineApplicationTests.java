package com.code_snippets.decision_engine;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@Import(TestcontainersConfiguration.class)
@SpringBootTest
class DecisionEngineApplicationTests {

  @Test
  void contextLoads() {}
}
