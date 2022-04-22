#!/bin/bash

ORACLE_SID=cc
BASE_DIRECTORY="/tmp/oracle"

while read line

do
   
    OLD_IFS="$IFS"
    IFS="," 
    arr=($line)
    Cno="${arr[0]}"
    DIS="${arr[1]}"
    IFS="$OLD_IFS"
    COMM="${arr[2]}"	
    TYPE="${arr[3]}"
    RE1="${arr[4]}"
    RE2="${arr[5]}"
    RE3="${arr[6]}"

if [ "${TYPE}" = "Automatic_configuration" ]; then
	#set different separator for different param arrays
	IFS=' '
	RE1=($RE1)
	RE2=($RE2)
	RE3=($RE3)
	IFS=';'
	COMM=($COMM)
	
	#check if base directory or file exists
        if [ ! -d "${BASE_DIRECTORY}" ]; then
			mkdir -p $BASE_DIRECTORY
        fi
	
		cd $BASE_DIRECTORY
		
        if [ -f "${0}.sql" ]; then
			rm -rf "${0}.sql"
        fi
	
		touch "${0}.sql"

        SQL_WORK="$BASE_DIRECTORY/${0}.sql"
        chmod 775 $SQL_WORK
	
	echo "COMM=$COMM";
	#echo "RE1=$RE1";
	#echo "RE2=$RE2";
	#echo "RE3=$RE3";

	#with keywords for to traverse arrays elements redirect to sql_work
	for i in ${COMM[@]};
	do
		echo "${i};" >> $SQL_WORK
	done

	sed -i /^$/d $SQL_WORK;

	for j in ${RE1[@]};
	do
		sed -i "s/<read1>/${j}/" $SQL_WORK
	done
	for j in ${RE2[@]};
	do
		sed -i "s/<read2>/${j}/" $SQL_WORK
	done
	for j in ${RE3[@]};
	do
		sed -i "s/<read3>/${j}/" $SQL_WORK
	done
		
	#sign up oracle by export sid and sqlplus statement
	su - oracle -c "export ORACLE_SID=${ORACLE_SID} && sqlplus / as sysdba" << EOF
	whenever sqlerror exit 1;
	@${SQL_WORK}
EOF
	if [[ "$?" -eq 0 ]]; then
    echo "success"
  else
    echo "failed"
	fi
	
	echo ""${Cno}","${Sno}","${DIS}","${TYPE}","${result}""
fi
done < security_test_2.csv


