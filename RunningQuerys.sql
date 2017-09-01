/* Show running querys */

SELECT sysdate, userid,status,starttime,duration,user_name,db_name,substring(query, 1,100) query ,pid
 FROM stv_recents
WHERE  1=1
and status = 'Running'
order by starttime desc ; 
