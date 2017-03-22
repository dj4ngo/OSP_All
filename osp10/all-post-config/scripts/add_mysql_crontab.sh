#!/bin/bash
#
# Add MYSQL database dump crontab entry on controller-0
set -x ; VLOG=/var/log/ospd/post_deploy-add_mysql_crontab.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

#
case ${my_node_role} in
	CTRL)
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
		echo "Not a Controller, skipping..."
	;;
esac
