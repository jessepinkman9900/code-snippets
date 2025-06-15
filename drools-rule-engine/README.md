# Drools Rule Engine

- validate api request using drools rules
- rules in [rules](src/main/resources/rules/DEPOSIT_ALLOWED_CURRENCIES.drl)
  - can add more rules
- 2 implementations for applying rules
  - [TransactionService](src/main/java/com/code_snippets/drools_rule_engine/service/TransactionService.java) - apply rules in service method
  - [AspectTransactionService](src/main/java/com/code_snippets/drools_rule_engine/service/AspectTransactionService.java) - apply rules using aspect

## Quick Start

```bash
# run app
just run
# curl api call
just api type='deposit' currency='USD'
```

## Usage

```bash
> just
just --list
Available recipes:
    setup                             # install dependencies/tools

    [api]
    api type='deposit' currency='USD' # curl api call

    [app]
    run                               # start spring boot web server
    test                              # run maven tests

    [fmt]
    fmt                               # format java code
```
