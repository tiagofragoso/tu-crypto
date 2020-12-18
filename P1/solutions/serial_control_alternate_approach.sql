WITH single_input_transactions AS (
    -- Get all transaction with a single input
    SELECT tx_id
    FROM inputs
    WHERE sig_id <> 0
    GROUP BY tx_id
    HAVING COUNT(input_id) = 1
), single_output_transactions AS (
    -- Get all transaction with a single output
    SELECT tx_id
    FROM outputs
    GROUP BY tx_id
    HAVING COUNT(output_id) = 1
)
-- Get addresses that appears in transactions with one input and one output
SELECT sig_id, pk_id
FROM inputs
JOIN outputs USING(tx_id)
WHERE tx_id IN (
    SELECT * 
    FROM single_input_transactions 
    JOIN single_output_transactions
    USING (tx_id)
);
