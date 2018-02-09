#!/bin/sh

date;

export ORACLE_SID=garaz
export ORACLE_HOME=/u01/home/oracle/app/product/12.2.0/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin

cd /u01/home/oracle/gielda/downloaded/

date;

wget http://bossa.pl/pub/ciagle/omega/omegacgl.zip

date;

mv omegacgl.zip /u01/home/oracle/gielda/downloaded/omegacgl_`date '+%Y%m%d'`.zip

date;

mkdir omegacgl_`date '+%Y%m%d'`

date;

unzip omegacgl_`date '+%Y%m%d'`.zip

date;

mv *txt omegacgl_`date '+%Y%m%d'`

date;

cat omegacgl_`date '+%Y%m%d'`/*.txt | grep -v "Name,Date,Open,High,Low,Close,Volume" | sort -u | tr -d '\015' > ../work/all_`date '+%Y%m%d'`.txt

date;

cd ../work

date;

sqlldr hadzio/hadzio@192.168.1.89:1521/garaz control=loader_dni.ctl log=../logs/all_`date '+%Y%m%d'`.log data=all_`date '+%Y%m%d'`.txt bad=../logs/all_`date '+%Y%m%d'`.bad discard=../logs/all_`date '+%Y%m%d'`.dsc direct=true

date;

sqlplus hadzio/hadzio@192.168.1.89:1521/garaz << EOF1 
ALTER SESSION FORCE PARALLEL QUERY PARALLEL 6;
INSERT INTO hadzio.OMEGA_RAWDATA
SELECT GENERAL_SEQ.NEXTVAL,
  sysdate,
  intsql.ior_Name ,
  intsql.ior_date ,
  intsql.ior_Open ,
  intsql.ior_High ,
  intsql.ior_low ,
  intsql.ior_close,
  intsql.ior_volume
FROM
  (SELECT UNIQUE hol.or_Name ior_Name,
    hol.or_date ior_date,
    hol.or_Open ior_Open,
    hol.or_High ior_High,
    hol.or_low ior_low,
    hol.or_close ior_close,
    hol.or_volume ior_volume
  FROM hadzio.OMEGA_loaded hol
  WHERE (hol.or_Name, hol.or_date) NOT IN
    (SELECT UNIQUE hor.or_Name, hor.or_date FROM hadzio.OMEGA_RAWDATA hor
    )
  ) intsql;
COMMIT;
TRUNCATE TABLE hadzio.omega_datastats;
INSERT INTO hadzio.omega_datastats
SELECT sysdate stats_date,
  ORW.OR_DATE trade_date,
  COUNT(*) num_of_companies
FROM hadzio.OMEGA_RAWDATA orw
GROUP BY ORW.OR_DATE
ORDER BY ORW.OR_DATE DESC;
COMMIT;
EOF1

date;

