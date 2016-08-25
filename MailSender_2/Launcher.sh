cd /app_univ/MailSender/


Count=`ksh Script_Exporter.sh /app_univ/Services/Alarmer/ QueryExecuter.sh "SELECT COUNT(*) from Queues.Send_Mail WHERE Status='not_sent'"`
echo "Counter="$Count
Count=`expr "$Count" + 0`
#mysql -hCNPVAS03 -uReader -pReader -P3307 -e"SELECT COUNT(*) from Queues.Send_Mail WHERE Status='not_sent'"
Rand=$RANDOM
OutFile="/share/Exporters/SendMail/$Rand"
Command="SELECT ID,Subject,REPLACE(Body,'\r\n','A5A5'),Receipients,\`From\` FROM Queues.Send_Mail WHERE Status='not_sent' INTO OUTFILE '$OutFile' FIELDS TERMINATED BY '|'"
mysql -hCNPVAS03 -uReader -pReader -P3307 -e"$Command"

Line=0
while [ $Line -lt $Count ]
        do
        Line=$(($Line+1))
        ID=`head -$Line $OutFile | tail -1 | cut -d '|' -f1`
        Subject=`head -$Line $OutFile | tail -1 | cut -d '|' -f2`
        Body=`head -$Line $OutFile | tail -1 | cut -d '|' -f3 | sed -e $'s/A5A5/<br\/>/g'`
       	Receipients=`head -$Line $OutFile | tail -1 | cut -d '|' -f4`
       	From=`head -$Line $OutFile | tail -1 | cut -d '|' -f5`
	
	echo "Processing Mail with ID:$ID"
	rm Error.txt
	java -jar SendMail.jar "$Receipients" "$Subject" "$Body" "$From" 2>Error.txt
	Error=`cat Error.txt`
	
	if [ "$Error" = "" ]
		then
			Command="UPDATE Queues.Send_Mail SET Status='Sent' WHERE ID=$ID"
		else
			Command="UPDATE Queues.Send_Mail SET Status='Error',Error_Description='$Error' WHERE ID=$ID"
	fi
	mysql -hCNPVAS03 -uWriter -pWriter -P3307 -e"$Command"
	
done
rm $OutFile
