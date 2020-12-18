/* IMPORTANT! use psql -qAtX -F " " for getting raw output without headers/footers/vertical bars */

/* empty addressrelations table */
DELETE FROM addressrelations;

/* heuristic 1*/

-- Joint control

insert into addressrelations (addr1, addr2) SELECT I1.sig_id, I2.sig_id
FROM inputs as I1, inputs as I2  
WHERE I1.tx_id = I2.tx_id 
AND I1.sig_id != I2.sig_id;

/*heuristic 2*/

/*insert into addressrelations (addr1, addr2) SELECT i.sig_id, o.pk_id as transactions
FROM 	inputs as i, outputs as o
WHERE i.tx_id = o.tx_id
AND i.tx_id IN (SELECT tx_id from inputs GROUP BY  tx_id having count(*) = 1  ORDER BY tx_id )
AND o.tx_id IN (SELECT tx_id from outputs GROUP BY  tx_id having count(*) = 1  ORDER BY tx_id )
ORDER BY i.sig_id DESC;*/

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
INSERT INTO addressRelations
SELECT in_addr, out_addr
FROM in_addresses
JOIN out_addresses USING (tx_id);

/*create table cluster and run the clusterAddresses() function to populate it*/

CREATE TABLE IF NOT EXISTS clusters(id int, address int); 

INSERT INTO clusters (id, address) SELECT *  FROM clusterAddresses();

CREATE EXTENSION if not exists pgcrypto;

/*for debugging*/
/*SELECT c.id, sum(o.value)
  FROM outputs AS o, clusters as c, utxos as u
  WHERE o.pk_id = c.address
  AND o.output_id = u.output_id
  GROUP BY c.id
  ORDER BY sum(o.value) DESC;
*/

DELETE FROM max_cluster_id;
DELETE FROM max_value_by_entity;
DELETE FROM min_addr_of_max_entity;
DELETE FROM max_tx_to_max_entity;

DO $$
DECLARE max_cluster_id integer; 
BEGIN
  
	SELECT c.id INTO max_cluster_id
	FROM outputs AS o, clusters as c, utxos as u
	WHERE o.pk_id = c.address
	AND o.output_id = u.output_id
	GROUP BY c.id
	ORDER BY sum(o.value) DESC
	LIMIT 1;
  
	INSERT INTO max_value_by_entity SELECT sum(o.value) as unspent_total
	FROM outputs AS o, clusters as c
	WHERE o.pk_id = max_cluster_id
	GROUP BY c.id
	ORDER BY unspent_total DESC
	LIMIT 1;
	
	INSERT INTO min_addr_of_max_entity SELECT c.address
	FROM clusters as c
	WHERE c.id = max_cluster_id
	ORDER BY c.address ASC
	LIMIT 1;
	
	INSERT INTO max_tx_to_max_entity SELECT tx_id/*, o.value*/
	FROM outputs o, clusters c 
	WHERE c.id = max_cluster_id
	AND c.address = o.pk_id
	ORDER BY o.value desc
	LIMIT 1;

  
END $$;





