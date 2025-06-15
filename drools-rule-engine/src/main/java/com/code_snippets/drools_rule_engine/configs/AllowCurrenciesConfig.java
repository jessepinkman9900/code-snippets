package com.code_snippets.drools_rule_engine.configs;

import static java.nio.charset.StandardCharsets.UTF_8;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.UncheckedIOException;
import org.kie.api.runtime.KieContainer;
import org.kie.api.runtime.KieSession;
import org.kie.internal.utils.KieHelper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.util.FileCopyUtils;

@Configuration
public class AllowCurrenciesConfig {
  private static final String DRL_FILE = "ALLOWED_CURRENCIES.drl";

  @Bean
  public KieContainer kieContainer() {
    try {
      KieHelper kieHelper = new KieHelper();

      // Load the DRL content from classpath
      Resource resource = new ClassPathResource(DRL_FILE);
      try (Reader reader = new InputStreamReader(resource.getInputStream(), UTF_8)) {
        String drlContent = FileCopyUtils.copyToString(reader);
        kieHelper.addContent(drlContent, "src/main/resources/" + DRL_FILE);
      }

      // Build and return the KieContainer
      return kieHelper.getKieContainer();
    } catch (IOException e) {
      throw new UncheckedIOException("Failed to load DRL file: " + DRL_FILE, e);
    }
  }

  @Bean
  public KieSession kieSession() {
    return kieContainer().newKieSession();
  }
}
