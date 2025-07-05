use pgrx::prelude::*;
mod retention;

/*
    In order to use this bgworker with pgrx, you'll need to edit the proper `postgresql.conf` file in
    "${PGRX_HOME}/data-$PGVER/postgresql.conf" and add this line to the end:

    ```
    shared_preload_libraries = 'bgworker.so'
    ```

    Background workers **must** be initialized in the extension's `_PG_init()` function, and can **only**
    be started if loaded through the `shared_preload_libraries` configuration setting.

    Executing `cargo pgrx run <PGVER>` will, when it restarts the specified Postgres instance, also start
    this background worker
*/

::pgrx::pg_module_magic!(name, version);

#[pg_guard]
pub extern "C-unwind" fn _PG_init() {
  retention::orchestrator::init();
}

#[pg_extern]
fn hello_extention() -> &'static str {
  "Hello, extention"
}

#[cfg(any(test, feature = "pg_test"))]
#[pg_schema]
mod tests {
  use pgrx::prelude::*;

  #[pg_test]
  fn test_hello_extention() {
    assert_eq!("Hello, extention", crate::hello_extention());
  }
}

/// This module is required by `cargo pgrx test` invocations.
/// It must be visible at the root of your extension crate.
#[cfg(test)]
pub mod pg_test {
  pub fn setup(_options: Vec<&str>) {
    // perform one-off initialization when the pg_test framework starts
  }

  #[must_use]
  pub fn postgresql_conf_options() -> Vec<&'static str> {
    // return any postgresql.conf settings that are required for your tests
    vec!["shared_preload_libraries = 'pgrx_data_retention'"]
  }
}
