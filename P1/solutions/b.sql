INSERT INTO utxos
SELECT output_id, value
FROM outputs
WHERE output_id NOT IN (
    SELECT output_id
    FROM inputs);
    
    
INSERT INTO number_of_utxos
SELECT count(*)
FROM utxos;

INSERT INTO id_of_max_utxo
SELECT output_id
FROM utxos
WHERE value = (
    SELECT MAX(value) 
    FROM utxos);

