#!/bin/bash

ORACLE_SID=cc
BASE_DIRECTORY="/tmp/security_harden"
LOG="$BASE_DIRECTORY/alert.log"

echo `date '+%Y-%m-%d %H:%M:%S'` >> $LOG 

while read line

do
   
    OLD_IFS="$IFS"
    IFS="," 
    arr=($line)
    Cno="${arr[0]}"
    DIS="${arr[1]}"
    COMM="${arr[2]}"	
    TYPE="${arr[3]}"
    RE1="${arr[4]}"
    RE2="${arr[5]}"
    RE3="${arr[6]}"

if [ "${TYPE}" = "Automatic_configuration" ]; then
	#"RE1","RE2","RE3"列保存列表数据,数据以;为分隔符,将这三个变量变成列表
	IFS=';'
	RE1=($RE1)
	RE2=($RE2)
	RE3=($RE3)
	#"COMM"中的数据限制为单行而非多行, 数据以';'结尾
	COMM=$COMM
	
	#建文件SQL_WORK
        if [ ! -d "${BASE_DIRECTORY}" ]; then
			mkdir -p $BASE_DIRECTORY
        fi
			
        if [ ! -f "$BASE_DIRECTORY/${0}.sql" ]; then
			touch "${0}.sql"
			SQL_WORK="$BASE_DIRECTORY/${0}.sql"
			chmod 775 $SQL_WORK
        fi
	
	SQL_WORK="$BASE_DIRECTORY/${0}.sql"
	
	#根据参数列表的长度将命令先逐一写入SQL_WORK.
	for ((j=1;j<=${#RE1[@]};j++))
	do
		echo "$COMM" >> $SQL_WORK
	done

	sed -i /^$/d $SQL_WORK;

	for j in ${RE1[@]};
	do
		sed -i "0,/<read1>/{s/<read1>/${j}/}" $SQL_WORK
	done
	for j in ${RE2[@]};
	do
		sed -i "0,/<read2>/{s/<read2>/${j}/}" $SQL_WORK
	done
	for j in ${RE3[@]};
	do
		sed -i "0,/<read3>/{s/<read3>/${j}/}" $SQL_WORK
	done
		
	#以system用户登录oracle实例,并导入SQL_WORK.
	if [ ! -f "$LOG" ]; then
		touch "$LOG"
		chmod 755 $LOG
	fi
	
	su - oracle -c "export ORACLE_SID=${ORACLE_SID} && sqlplus / as sysdba" << EOF
	whenever sqlerror exit 1;
	@${SQL_WORK}
	exit;
EOF

	if [[ "$?" -eq 0 ]]; then
    echo "${Cno} success" >> $LOG
  else
    echo "${Cno} failed" >> $LOG
	fi
	
	#清空SQL_WORK的内容
	cat /dev/null > $SQL_WORK
fi
IFS=$OLD_IFS
done < $1



