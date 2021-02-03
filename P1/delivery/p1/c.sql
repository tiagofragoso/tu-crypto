-- DELETE FROM addressrelations;

-- Joint control

INSERT INTO addressrelations
SELECT I1.sig_id, I2.sig_id
FROM inputs AS I1, inputs AS I2
WHERE I1.tx_id = I2.tx_id
AND I1.sig_id != I2.sig_id;

-- Serial control

WITH in1_out1 AS (
-- Get transactions with only 1 input and 1 output
    SELECT tx_id
    FROM transactions
    JOIN inputs USING (tx_id)
    JOIN outputs USING (tx_id)
    GROUP BY tx_id
    HAVING COUNT(inputs.input_id) = 1 AND COUNT(outputs.output_id) = 1
), in_addresses AS (
    SELECT tx_id, sig_id AS in_addr
    FROM inputs
    WHERE inputs.tx_id IN (SELECT * FROM in1_out1)
    AND sig_id <> 0
), out_addresses AS (
    SELECT tx_id, pk_id AS out_addr
    FROM outputs
    WHERE tx_id IN (SELECT * FROM in1_out1)
)
INSERT INTO addressrelations
SELECT in_addr, out_addr
FROM in_addresses
JOIN out_addresses USING (tx_id)
WHERE in_addr <> out_addr;

/*create table cluster and run the clusterAddresses() function to populate it*/
CREATE TABLE IF NOT EXISTS clusters (id int, address int);
DELETE FROM clusters;
INSERT INTO clusters SELECT * FROM clusteraddresses();

-- SELECT encode(sha256(string_agg(id::text, ' ' ORDER BY id)::bytea), 'hex') AS hash
-- FROM clusters;

-- DELETE FROM max_value_by_entity;
-- DELETE FROM min_addr_of_max_entity;
-- DELETE FROM max_tx_to_max_entity;

DO $$
DECLARE max_cluster_id integer; 
BEGIN
    -- Get id of cluster holding most unspent BTC
	SELECT c.id INTO max_cluster_id
	FROM outputs AS o, clusters AS c, utxos AS u
	WHERE o.pk_id = c.address
	AND o.output_id = u.output_id
	GROUP BY c.id
	ORDER BY SUM(o.value) DESC
	LIMIT 1;
	
	INSERT INTO max_value_by_entity
	-- Get maximum unspent BTC held by one single entity
	SELECT SUM(o.value) AS unspent_total
    	FROM utxos AS u, outputs AS o
    	WHERE u.output_id = o.output_id AND o.pk_id IN
    		(SELECT address
        	FROM clusters
            WHERE id = max_cluster_id);

	INSERT INTO min_addr_of_max_entity
	-- Get lowest address belonging to the entity holding the most unspent BTC
	SELECT MIN(c.address)
	FROM clusters AS c
	WHERE c.id = max_cluster_id;

	INSERT INTO max_tx_to_max_entity
	-- Get transaction sending the most BTC  to the entity holding the most unspent BTC
	SELECT tx_id
	FROM outputs AS o, clusters AS c
	WHERE c.id = max_cluster_id
	AND c.address = o.pk_id
	GROUP BY o.tx_id
    ORDER BY SUM(o.value) DESC
	LIMIT 1;

END $$;

-- SELECT encode(sha256(((
--         (select value from max_value_by_entity) +
--         (select addr from min_addr_of_max_entity) +
--         (select tx_id from max_tx_to_max_entity))::varchar(255))
--     ::bytea),
--     'hex') AS hash;

