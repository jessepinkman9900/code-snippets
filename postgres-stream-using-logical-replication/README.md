# PostgreSQL CDC with Debezium

This application demonstrates Change Data Capture (CDC) from PostgreSQL using Debezium. It captures database changes and processes them in real-time.

## Features

- Real-time change capture from PostgreSQL using Debezium
- Configurable table inclusion and filtering
- Offset management for reliable processing
- Integration with Spring Boot

## Prerequisites

- Java 21+
- Maven 3.6+
- PostgreSQL 14+
- Docker (for Kafka, if needed)

## Usage
```bash
just setup # install dependencies
just up # setup postgres & kafka
just run # run the application
just load # insert data into postgres
# kafka ui - http://localhost:8088

just down # stop postgres & kafka
```

## Configuration

Update the `application.yml` with your PostgreSQL connection details:

```yaml
application:
  postgres:
    url: jdbc:postgresql://localhost:5432/your_database
    username: your_username
    password: your_password
    replication:
      plugin_name: pgoutput
      slot_name: debezium_slot
      publication_names: debezium_pub
      server_name: dbserver1
      table_include_list: public.*
```

## Running the Application

1. Ensure PostgreSQL is running with the following settings:
   - `wal_level = logical`
   - `max_wal_senders` > 1
   - `max_replication_slots` > 1

2. Create a replication slot and publication in PostgreSQL:
   ```sql
   -- Create replication slot
   SELECT pg_create_logical_replication_slot('debezium_slot', 'pgoutput');

   -- Create publication for tables you want to track
   CREATE PUBLICATION debezium_pub FOR ALL TABLES;
   ```

3. Build and run the application:
   ```bash
   mvn clean install
   java -jar target/postgres-stream-using-logical-replication-0.0.1-SNAPSHOT.jar
   ```

## How It Works

The application uses Debezium's embedded engine to capture changes from PostgreSQL. When a change occurs in the tracked tables, the `handleChangeEvent` method in `DebeziumConfig` is called with the change event.

## Configuration Options

- `plugin_name`: PostgreSQL logical decoding plugin (default: pgoutput)
- `slot_name`: Replication slot name
- `publication_names`: PostgreSQL publication name
- `server_name`: Logical name for the database server
- `table_include_list`: Tables to include in change capture (e.g., public.*)
- `include_schema_changes`: Whether to include schema changes (default: false)
- `snapshot_mode`: When to take snapshots (default: never)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
