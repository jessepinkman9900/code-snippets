package com.code_snippets.drools_rule_engine;

import com.code_snippets.drools_rule_engine.configs.TestcontainersConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@Import(TestcontainersConfiguration.class)
@SpringBootTest
class DroolsRuleEngineApplicationTests {

  @Test
  void contextLoads() {}
}
