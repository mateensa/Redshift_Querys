SELECT CAST(use2.usename AS VARCHAR(50)) AS OWNER
 ,TRIM(pgdb.datname) AS DATABASE
 ,TRIM(pgn.nspname) AS SCHEMA
 ,TRIM(a.NAME) AS TABLE
 ,(b.mbytes) / 1024 AS Gigabytes
 ,a.ROWS as rows_deleted
FROM (
 SELECT db_id
 ,id
 ,NAME
 ,SUM(ROWS) AS ROWS
 FROM stv_tbl_perm a
 --where trim(name) not like regexp_substr(trim(NAME),'[^0-9]*') and trim(name) not like 's3%' and trim(name) not like '%11i%' 
 GROUP BY db_id
 ,id
 ,NAME
 ) AS a
JOIN pg_class AS pgc ON pgc.oid = a.id
LEFT JOIN pg_user use2 ON (pgc.relowner = use2.usesysid)
JOIN pg_namespace AS pgn ON pgn.oid = pgc.relnamespace
 AND pgn.nspowner > 1
JOIN pg_database AS pgdb ON pgdb.oid = a.db_id
JOIN (
 SELECT tbl
 ,COUNT(*) AS mbytes
 FROM stv_blocklist
 GROUP BY tbl
 ) b ON a.id = b.tbl
WHERE pgdb.datname = 'dwa' 
ORDER BY mbytes DESC
 ,a.db_id
 ,a.NAME;
