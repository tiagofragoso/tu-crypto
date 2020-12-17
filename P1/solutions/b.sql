INSERT INTO utxos
-- Get unspent outputs
SELECT output_id, value
FROM outputs
WHERE output_id NOT IN (
    SELECT output_id
    FROM inputs);
    
    
INSERT INTO number_of_utxos
-- Get total number of unspent outputs
SELECT count(*) AS utxo_count
FROM utxos;


INSERT INTO id_of_max_utxo
-- Get output_id of the UTXO with the highest associated value
SELECT output_id AS max_utxo
FROM utxos
WHERE value = (
    SELECT MAX(value) 
    FROM utxos);

