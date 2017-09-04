SET search_path TO '$user', 'presentation'; --staging, presentation

WITH select_columns AS(
 select "column" || '			' colmn,
         "type" || '			' typs,
         CASE
           WHEN ENCODING = 'none' THEN ''
           ELSE 'encode ' ||encoding || '			'
         END AS enoding,
         sortkey,
         pc.reldiststyle, 
         distkey, 
         ordinal_position,
         table_schema,
         table_name, 
	 				CASE
	            WHEN pc.reldiststyle = 0 THEN 'EVEN' 
	            WHEN (pc.reldiststyle = 1 and distkey = true) THEN pg_table_def."column" 
	            WHEN pc.reldiststyle = 8 THEN 'ALL' 
	            ELSE NULL::text
	        END 
	 , COUNT(1) NR_COLUMNS 
  FROM pg_table_def,
       information_schema.columns 
       , pg_class pc 
       , pg_namespace
  WHERE columns.table_name = pg_table_def.tablename
  AND   columns.column_name = pg_table_def."column"
  AND   columns.table_schema = pg_table_def.schemaname
  and   pc.relname = pg_table_def.tablename 
  and 	pg_namespace.oid = pc.relnamespace
  and 	pg_namespace.nspname = pg_table_def.schemaname 
  AND   columns.table_catalog = 'dwa'
  AND   UPPER(columns.table_schema) = UPPER('presentation')
  AND   UPPER(pg_table_def.tablename) = TRIM(UPPER('ar_invc_line_gl_dist_f')) 
  group by pg_table_def.column, pg_table_def.type, pg_table_def.encoding, pg_table_def.sortkey, pc.reldiststyle, pg_table_def.distkey, columns.ordinal_position
  	, columns.table_schema, columns.table_name
  order by ordinal_position 
)
 
SELECT statement
FROM (SELECT *,
             1 statement_type
      FROM ( SELECT CASE
						 					WHEN (ordinal_position = 1) 
						 						then (CASE WHEN ((select max(ordinal_position) from select_columns) = 1) 
						 										THEN 'drop table if exists ' ||table_schema || '.' ||table_name || ';' || '' || CHR(13) || 
						 									 			 'create table ' ||table_schema || '.' ||table_name|| '( ' || CHR(13) || colmn || '' || typs|| '' || enoding || ')'
						 										ELSE 'drop table if exists ' ||table_schema || '.' ||table_name || ';' || '' || CHR(13) || 
						 									 			 'create table ' ||table_schema || '.' ||table_name|| '( ' || CHR(13) || colmn || '' || typs|| '' || enoding || ', '
						 									END)
						          WHEN ordinal_position = (SELECT MAX(ordinal_position) FROM select_columns) THEN colmn || '' || typs|| ' ' || enoding || CHR(13) || ')' || CHR(13)
						          ELSE colmn || '' || typs|| '' || enoding|| ','
						          END AS statement
						 FROM select_columns  
						 ORDER BY ordinal_position)
      UNION ALL
      select *, 2 statement_type from (
				select max(statement) as statement from (
				SELECT 
				CASE
					WHEN reldiststyle = 0 THEN 'diststyle even' || chr(13)
					WHEN (reldiststyle = 1 and distkey = true) THEN 'distkey( ' || decode(distkey, 0, '', colmn||' ) ') || CHR(13)
					WHEN reldiststyle = 8 THEN 'diststyle all' || chr(13)
					ELSE NULL 
				END  AS statement FROM select_columns
				)
			)
      UNION ALL
      SELECT *,
             3 statement_type
      FROM (SELECT CASE
                     WHEN ordinal_position = (SELECT MIN(ordinal_position)
                                              FROM select_columns
                                              WHERE sortkey <> 0) THEN 'sortkey( ' || colmn || ','
                     WHEN ordinal_position = (SELECT MAX(ordinal_position)
                                              FROM select_columns
                                              WHERE sortkey <> 0) THEN colmn || CHR(13) || ')' || CHR(13)
                     ELSE colmn || ','
                   END AS statement
            FROM select_columns
            WHERE 1 = 1
            AND   sortkey <> 0
            ORDER BY ordinal_position)
      UNION ALL
      SELECT CHR(13)||';' , 3.5 AS statement_type 
      UNION ALL
      SELECT *,
             4 statement_type
      FROM (SELECT CHR(13) || CHR(13) || 'alter table ' ||table_schema|| '.' ||table_name || ' owner to integration_user;' || CHR(13) || 'grant select on ' ||table_schema|| '.' ||table_name || ' to  integration_user, denodo_admin, reporttool, ops_monitor, rep_readonly;' || CHR(13) AS statement
            FROM select_columns LIMIT 1))
ORDER BY statement_type;

