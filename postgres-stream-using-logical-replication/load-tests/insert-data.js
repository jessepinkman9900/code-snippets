import { check } from 'k6';
import sql from 'k6/x/sql';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Import PostgreSQL driver
import postgres from 'k6/x/sql/driver/postgres';

// PostgreSQL connection configuration based on docker-compose.yml
const PG_HOST = 'localhost';
const PG_PORT = '5432';
const PG_USER = 'usr';
const PG_PASSWORD = 'pwd';
const PG_DATABASE = 'operational_db';

// Connection string for PostgreSQL with SSL disabled
const connectionString = `postgres://${PG_USER}:${PG_PASSWORD}@${PG_HOST}:${PG_PORT}/${PG_DATABASE}?sslmode=disable`;

// Test configuration
export const options = {
  scenarios: {
    contacts: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '30s', target: 1 },   // Ramp up to 5 VUs over 30 seconds
        // { duration: '1m', target: 30 },   // Ramp up to 10 VUs over 1 minute
        { duration: '30s', target: 0 }    // Ramp down to 0 VUs over 30 seconds
      ],
    },
  },
  thresholds: {
    'checks': ['rate>0.95'], // 95% of checks must pass
    'http_req_duration': ['p(95)<500'], // 95% of requests must complete within 500ms
  },
};

// Generate a random product
function generateRandomProduct() {
  const productTypes = ['Organic', 'Fresh', 'Premium', 'Gourmet', 'Artisan'];
  const productItems = ['Apples', 'Bread', 'Cheese', 'Coffee', 'Pasta', 'Yogurt', 'Chocolate', 'Tea', 'Honey', 'Cereal'];
  const randomType = productTypes[Math.floor(Math.random() * productTypes.length)];
  const randomItem = productItems[Math.floor(Math.random() * productItems.length)];
  const name = `${randomType} ${randomItem} (${randomString(3, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')})`;
  const price = parseFloat((Math.random() * 20 + 1).toFixed(2)); // Random price between 1.00 and 21.00

  return { name, price };
}

// Setup function - runs once per VU
export function setup() {
  const db = sql.open(postgres, connectionString);

  try {
    // Verify connection works and table exists
    const result = db.query('SELECT COUNT(*) FROM products');
    console.log(`Initial product count: ${result[0]['count']}`);
  } catch (error) {
    console.error(`Error in setup: ${error}`);
  } finally {
    db.close();
  }

  return {};
}

// Default function - runs for each VU iteration
export default function () {
  const db = sql.open(postgres, connectionString);

  try {
    // Generate a random product
    const product = generateRandomProduct();

    // Insert the product into the database
    // Using string interpolation instead of parameterized queries due to driver limitations
    // Note: In production code, you should use proper parameterized queries to prevent SQL injection
    const result = db.query(
      `INSERT INTO products(name, price) VALUES('${product.name}', ${product.price}) RETURNING id`
    );

    // Check if insertion was successful
    check(result, {
      'product inserted successfully': (r) => r && r.length > 0 && r[0].id > 0,
    });

    console.log(`Inserted product: ${product.name} with price $${product.price} (ID: ${result[0].id})`);

  } catch (error) {
    console.error(`Error inserting product: ${error}`);
  } finally {
    db.close();
  }
}

// Teardown function - runs once at the end of the test
export function teardown() {
  const db = sql.open(postgres, connectionString);

  try {
    // Get final count of products
    const result = db.query('SELECT COUNT(*) FROM products');
    console.log(`Final product count: ${result[0]['count']}`);
  } catch (error) {
    console.error(`Error in teardown: ${error}`);
  } finally {
    db.close();
  }
}
