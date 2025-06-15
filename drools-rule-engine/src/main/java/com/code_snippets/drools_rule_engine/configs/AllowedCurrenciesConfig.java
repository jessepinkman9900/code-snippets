package com.code_snippets.drools_rule_engine.configs;

import java.io.IOException;
import org.kie.api.KieServices;
import org.kie.api.builder.KieBuilder;
import org.kie.api.builder.KieFileSystem;
import org.kie.api.builder.KieRepository;
import org.kie.api.runtime.KieContainer;
import org.kie.api.runtime.KieSession;
import org.kie.internal.io.ResourceFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

@Configuration
public class AllowedCurrenciesConfig {
  private static final String RULES_DIR = "rules/";

  @Bean
  public KieFileSystem kieFileSystem() throws IOException {
    KieFileSystem kieFileSystem = KieServices.Factory.get().newKieFileSystem();
    PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
    Resource[] files = resolver.getResources("classpath*:" + RULES_DIR + "**/*.drl");
    for (Resource file : files) {
      kieFileSystem.write(
          ResourceFactory.newClassPathResource(RULES_DIR + file.getFilename(), "UTF-8"));
    }
    return kieFileSystem;
  }

  @Bean
  public KieContainer kieContainer() throws IOException {
    KieServices kieServices = KieServices.Factory.get();
    KieRepository kieRepository = kieServices.getRepository();
    kieRepository.addKieModule(() -> kieRepository.getDefaultReleaseId());
    KieBuilder kieBuilder = kieServices.newKieBuilder(kieFileSystem());
    kieBuilder.buildAll();
    return kieServices.newKieContainer(kieRepository.getDefaultReleaseId());
  }

  @Bean
  public KieSession kieSession() throws IOException {
    return kieContainer().newKieSession();
  }
}
