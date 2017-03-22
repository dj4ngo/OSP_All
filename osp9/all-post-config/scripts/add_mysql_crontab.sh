#!/bin/bash
#
# Add MYSQL database dump crontab entry on controller-0
set -x ; l=post_deploy-add_mysql_crontab; VLOG=/var/log/ospd/${l%\.sh}.log ; exec &> >(tee -a "${VLOG}")

#
myhostname=$(hostname -s)
case ${myhostname} in
        *-ctrl-0|*-controller-0)
		if [ ! -f /var/spool/cron/root ]
		then
			mkdir /root/database_dumps
                	echo "Adding MYSQL database dump crontab entry..."
			echo "00 08 * * * mysqldump --opt --all-databases > /root/database_dumps/nxgenaz-all-databases.sql.\`date +\%w\`" > /var/spool/cron/root
                	echo "Display root crontab entry..."
			crontab -l
		else
			crontab -l | grep mysqldump
			if [ $? -eq 1 ]
			then
				mkdir /root/database_dumps
				echo "The root crontab already exists..."
                        	echo "Re-adding MYSQL database dump crontab entry..."
                        	echo "00 08 * * * mysqldump --opt --all-databases > /root/database_dumps/nxgenaz-all-databases.sql.\`date +\%w\`" >> /var/spool/cron/root
                		echo "Display root crontab entry..."
				crontab -l
			fi
		fi
	;;
	*)
		echo "Not Controller0, skipping..."
	;;
esac
