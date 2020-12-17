/* IMPORTANT! use psql -qAtX -F " " for getting raw output without headers/footers/vertical bars */

/* empty addressrelations table */
DELETE FROM addressrelations;

/* heuristic 1*/

insert into addressrelations (addr1, addr2) SELECT I1.sig_id, I2.sig_id
FROM inputs as I1, inputs as I2  
WHERE I1.tx_id = I2.tx_id 
AND I1.input_id != I2.input_id;

/* heuristic 2 */
/*
insert into addressrelations (addr1, addr2) SELECT i.sig_id, o.pk_id as transactions
FROM 	inputs as i, outputs as o
WHERE i.tx_id = o.tx_id
AND i.tx_id IN (SELECT tx_id from inputs GROUP BY  tx_id having count(*) = 1  ORDER BY tx_id )
AND o.tx_id IN (SELECT tx_id from outputs GROUP BY  tx_id having count(*) = 1  ORDER BY tx_id )
ORDER BY i.sig_id DESC;
*/


/*create table cluster and run the clusterAddresses() function to populate it*/

CREATE TABLE IF NOT EXISTS clusters(id int, address int); 

INSERT INTO clusters (id, address) SELECT *  FROM clusterAddresses();


