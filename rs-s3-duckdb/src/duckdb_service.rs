use duckdb::Connection;

pub fn create_connection() -> duckdb::Connection {
  Connection::open_in_memory().unwrap()
}
