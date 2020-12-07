DROP TABLE IF EXISTS invalid_blocks_temp;
CREATE TEMPORARY TABLE invalid_blocks_temp ( block_id int );

-- Common views

CREATE OR REPLACE VIEW coinbase_transactions
AS SELECT block_id, tx_id
    FROM (
             SELECT block_id, MIN(tx_id) AS tx_id
             FROM transactions
             GROUP BY block_id
         ) AS first_transactions
    JOIN inputs USING (tx_id)
    WHERE sig_id = 0;

CREATE OR REPLACE VIEW non_coinbase_transactions
AS SELECT block_id, tx_id
    FROM transactions
    EXCEPT
    SELECT block_id, tx_id
    FROM coinbase_transactions;

-- 6.

WITH first_txs AS (
	-- Get the first transaction of each block
	SELECT MIN(tx_id) AS tx_id, block_id
	FROM transactions
	GROUP BY block_id
)
INSERT INTO invalid_blocks_temp
-- Get blocks that have a non-coinbase first transaction
SELECT block_id
FROM first_txs
WHERE tx_id NOT IN (SELECT tx_id FROM coinbase_transactions);

INSERT INTO invalid_blocks_temp
-- Get blocks that have more than 1 coinbase transaction
SELECT DISTINCT block_id
FROM transactions JOIN inputs USING (tx_id)
WHERE sig_id = 0
GROUP BY block_id
HAVING COUNT(tx_id) > 1;

-- 7.2

INSERT INTO invalid_blocks_temp
-- Get blocks that have transactions with no inputs
SELECT DISTINCT block_id
FROM transactions
JOIN inputs USING (tx_id)
GROUP BY tx_id
HAVING COUNT(input_id) = 0;

-- 7.4

INSERT INTO invalid_blocks_temp
-- Get blocks that have transactions with invalid output values
SELECT DISTINCT block_id
FROM transactions JOIN outputs USING (tx_id)
WHERE value < 0 OR value > 2100000000000000;

INSERT INTO invalid_blocks_temp
-- Get blocks that have transactions with no outputs or invalid sum output values
SELECT DISTINCT block_id
FROM transactions
JOIN outputs USING (tx_id)
GROUP BY tx_id
HAVING COUNT(output_id) = 0 OR SUM(value) < 0 OR SUM(value) > 2100000000000000;

-- 16.1

CREATE OR REPLACE VIEW not_coinbase_inputs AS (
    SELECT *
    FROM non_coinbase_transactions
    JOIN inputs USING (tx_id)
);

-- 16.1.1

INSERT INTO invalid_blocks_temp
-- Get blocks containing transactions where inputs have no corresponding output
SELECT DISTINCT block_id
FROM not_coinbase_inputs
LEFT OUTER JOIN outputs USING(output_id)
WHERE value IS NULL;

-- 16.1.4
INSERT INTO invalid_blocks_temp
-- Get blocks where a input signature does not match the output signature
SELECT DISTINCT block_id
FROM not_coinbase_inputs
JOIN outputs USING (output_id)
WHERE sig_id <> pk_id;

-- 16.1.5
-- Get outputs spent more than once
WITH double_spent_outputs AS (
    SELECT output_id
    FROM not_coinbase_inputs
    JOIN outputs USING (output_id)
    GROUP BY output_id
    HAVING COUNT (input_id) > 1
), first_spent AS (
-- Get the input_id of the where the output was first spent
    SELECT MIN(input_id) AS input_id, output_id
    FROM non_coinbase_transactions
             JOIN inputs USING (tx_id)
    WHERE output_id IN (SELECT * FROM double_spent_outputs)
    GROUP BY output_id
)
INSERT INTO invalid_blocks_temp
-- Get blocks containing invalid inputs due to double spend
SELECT block_id
    FROM non_coinbase_transactions
             JOIN inputs USING (tx_id)
    WHERE output_id IN (SELECT * FROM double_spent_outputs)
    AND input_id NOT IN (SELECT input_id FROM first_spent);

INSERT INTO invalid_blocks_temp
-- Get blocks where there is an input referencing a later output
SELECT DISTINCT block_id
FROM non_coinbase_transactions
JOIN inputs USING (tx_id)
JOIN outputs USING (output_id)
WHERE outputs.tx_id >= inputs.tx_id;

-- 16.1.6

CREATE OR REPLACE VIEW input_sums
AS SELECT block_id, tx_id, sum
FROM transactions JOIN (
    SELECT not_coinbase_inputs.tx_id AS tx_id, SUM(value) AS sum
FROM not_coinbase_inputs JOIN outputs USING (output_id)
GROUP BY not_coinbase_inputs.tx_id) AS inputs USING(tx_id);

INSERT INTO invalid_blocks_temp
-- Get blocks with transactions whose input sum is outside legal range
SELECT DISTINCT block_id
FROM input_sums
WHERE sum < 0 OR sum > 2100000000000000;

INSERT INTO invalid_blocks_temp
-- Get blocks with transactions whose input values are outside legal range
SELECT DISTINCT block_id
FROM not_coinbase_inputs JOIN outputs USING (output_id)
WHERE value < 0 OR value > 2100000000000000;

-- 16.1.7
WITH output_sums AS (
    SELECT block_id, tx_id, sum
    FROM transactions
    JOIN (SELECT tx_id, SUM(value) AS sum
    FROM non_coinbase_transactions JOIN outputs USING (tx_id)
    GROUP BY tx_id) AS outputs USING(tx_id)
)
INSERT INTO invalid_blocks_temp
-- Get blocks with transactions whose sum(inputs) < sum(outputs)
SELECT DISTINCT input_sums.block_id FROM
input_sums JOIN output_sums USING (tx_id)
WHERE input_sums.sum < output_sums.sum;

-- 16.2

WITH coinbase_values AS (
    -- Get coinbase value for each block
    SELECT block_id, SUM(value) AS coinbase_value
    FROM coinbase_transactions
             JOIN outputs USING (tx_id)
    GROUP BY block_id
),
 input_values AS (
     -- Get sum(inputs) for each block
     SELECT block_id, SUM(value) AS total_inputs
     FROM transactions
              JOIN inputs USING (tx_id)
              JOIN outputs USING (output_id)
     WHERE inputs.tx_id NOT IN (SELECT tx_id FROM coinbase_transactions)
     GROUP BY block_id
 ),
 output_values AS (
     -- Get sum(outputs) for each block
     SELECT block_id, SUM(value) AS total_outputs
     FROM transactions
              JOIN outputs USING (tx_id)
     WHERE tx_id NOT IN (SELECT tx_id FROM coinbase_transactions)
     GROUP BY block_id
 )
INSERT INTO invalid_blocks_temp
-- Get blocks where coinbase value > block creation fee + transaction fees:
-- Block creation fee = 50 BTC; Transaction fees = sum(inputs)-sum(outputs) of all transactions
SELECT DISTINCT block_id
FROM coinbase_values JOIN input_values USING (block_id) JOIN output_values USING (block_id)
WHERE coinbase_values.coinbase_value > (5000000000 + (input_values.total_inputs - output_values.total_outputs));

DELETE FROM invalid_blocks;
INSERT INTO invalid_blocks
SELECT DISTINCT block_id
FROM invalid_blocks_temp;

-- Get invalid block count and sha256 hash
SELECT COUNT(*) AS total, encode(sha256(string_agg(block_id::text, '' ORDER BY block_id ASC)::bytea), 'hex') AS hash
FROM invalid_blocks;
