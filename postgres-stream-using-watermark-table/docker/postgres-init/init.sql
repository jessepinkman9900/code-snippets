-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    quantity INT NOT NULL,
    amount FLOAT NOT NULL,
    metadata JSONB DEFAULT '{"manufacturer": "", "country_of_origin": ""}'
);

-- Create an index on product_name for faster lookups
CREATE INDEX idx_product_name ON products(product_name);

-- Grant permissions
GRANT ALL PRIVILEGES ON TABLE products TO postgres;
GRANT USAGE, SELECT ON SEQUENCE products_id_seq TO postgres;

-- Create arrays of sample data for random selection
DO $$
DECLARE
    categories TEXT[] := ARRAY['Electronics', 'Clothing', 'Home', 'Kitchen', 'Sports', 'Books', 'Toys', 'Beauty', 'Automotive', 'Garden'];
    manufacturers TEXT[] := ARRAY['TechCorp', 'MobileTech', 'AudioPro', 'WearableTech', 'OpticsPro', 'DisplayTech', 'InputPro', 'FashionCo', 'HomeGoods', 'KitchenPro', 'SportsMaster', 'BookWorld', 'ToyLand', 'BeautyEssentials', 'AutoParts'];
    countries TEXT[] := ARRAY['USA', 'China', 'Japan', 'Germany', 'South Korea', 'Taiwan', 'India', 'Vietnam', 'Mexico', 'Brazil'];
    ingredients TEXT[] := ARRAY['Aluminum', 'Plastic', 'Steel', 'Glass', 'Silicon', 'Copper', 'Rubber', 'Leather', 'Cotton', 'Polyester', 'Nylon', 'Wood', 'Carbon Fiber', 'Titanium', 'Ceramic', 'Gold', 'Silver', 'Platinum', 'Zinc', 'Nickel'];
    
    -- Variables for random generation
    category TEXT;
    product_id INT;
    product_name TEXT;
    quantity INT;
    amount FLOAT;
    manufacturer TEXT;
    country TEXT;
    metadata JSONB;
    batch_size INT := 100000; -- Insert in batches for better performance
    total_records INT := 10000000;
    i INT;
    j INT;
    batch INT;
    random_chars TEXT;
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    chars_len INT := length(chars);
    random_pos INT;
    month INT;
    day INT;
    production_date TEXT;
    batch_id TEXT;
    
    -- Ingredients variables
    num_ingredients INT;
    ingredient_array JSONB;
    used_ingredients BOOLEAN[];
    ingredient_idx INT;
    ingredient_count INT;
BEGIN
    -- Disable triggers temporarily for faster inserts
    SET session_replication_role = 'replica';
    
    -- Process in batches
    FOR batch IN 0..(total_records/batch_size - 1) LOOP
        BEGIN
            -- Generate and insert batch of records
            FOR i IN 1..batch_size LOOP
                -- Generate random product data
                category := categories[1 + floor(random() * array_length(categories, 1))::INT];
                product_id := 1000 + floor(random() * 9000)::INT;
                
                -- Generate random 3-character string
                random_chars := '';
                FOR j IN 1..3 LOOP
                    random_pos := 1 + floor(random() * chars_len)::INT;
                    random_chars := random_chars || substr(chars, random_pos, 1);
                END LOOP;
                
                product_name := category || ' ' || random_chars || '-' || product_id::TEXT;
                quantity := 1 + floor(random() * 999)::INT;
                amount := 1.0 + random() * 1999.0;
                
                -- Generate metadata
                manufacturer := manufacturers[1 + floor(random() * array_length(manufacturers, 1))::INT];
                country := countries[1 + floor(random() * array_length(countries, 1))::INT];
                month := 1 + floor(random() * 12)::INT;
                day := 1 + floor(random() * 28)::INT;
                production_date := '2025-' || LPAD(month::TEXT, 2, '0') || '-' || LPAD(day::TEXT, 2, '0');
                batch_id := 'BATCH-' || ((batch * batch_size + i) / 1000)::TEXT;
                
                -- Generate random ingredients array (2-5 ingredients)
                num_ingredients := 2 + floor(random() * 4)::INT; -- Random number between 2 and 5
                ingredient_array := '[]'::JSONB;
                used_ingredients := ARRAY_FILL(FALSE, ARRAY[array_length(ingredients, 1)]);
                ingredient_count := 0;
                
                -- Select random unique ingredients
                WHILE ingredient_count < num_ingredients LOOP
                    ingredient_idx := 1 + floor(random() * array_length(ingredients, 1))::INT;
                    
                    -- Only add if not already used
                    IF NOT used_ingredients[ingredient_idx] THEN
                        ingredient_array := ingredient_array || jsonb_build_object(
                            'name', ingredients[ingredient_idx],
                            'percentage', (5 + floor(random() * 96)::INT)::TEXT || '%',
                            'source', countries[1 + floor(random() * array_length(countries, 1))::INT]
                        );
                        used_ingredients[ingredient_idx] := TRUE;
                        ingredient_count := ingredient_count + 1;
                    END IF;
                END LOOP;
                
                metadata := json_build_object(
                    'manufacturer', manufacturer,
                    'country_of_origin', country,
                    'batch_id', batch_id,
                    'production_date', production_date,
                    'ingredients', ingredient_array
                );
                
                -- Insert the record
                INSERT INTO products (product_name, quantity, amount, metadata)
                VALUES (product_name, quantity, amount, metadata);
            END LOOP;
            
            -- Log progress
            RAISE NOTICE 'Inserted batch %: records %-%', 
                batch, 
                batch * batch_size + 1, 
                (batch + 1) * batch_size;
        EXCEPTION WHEN OTHERS THEN
            -- If there's an error, log it and continue with next batch
            RAISE NOTICE 'Error in batch %: %', batch, SQLERRM;
        END;
    END LOOP;
    
    -- Re-enable triggers
    SET session_replication_role = 'origin';
    
    -- Log completion
    RAISE NOTICE 'Data generation complete: % records inserted', total_records;
END;
$$;
