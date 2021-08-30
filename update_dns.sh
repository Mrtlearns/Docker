# Guide : https://www.cloudsavvyit.com/3103/how-to-roll-your-own-dynamic-dns-with-aws-route-53/

# 1. Install AWS CLI if not present and AWS configure.  Install sudo yum install jq -y 
# 2   Upload script below use script below as update_dns.sh
# 3  Make excutable chmod +x and chmod 777
# 4  crontab -e (last line of script)





# Script called: update_dns.sh

#!/bin/bash
#https://www.cloudsavvyit.com/3103/how-to-roll-your-own-dynamic-dns-with-aws-route-53/
#Variable Declaration - Change These
HOSTED_ZONE_ID="Z14QVBRUF6Z9TH"
NAME="cox.playsap.us."
TYPE="A"
TTL=60
#get current IP address
IP=$(curl http://checkip.amazonaws.com/)
#validate IP address (makes sure Route 53 doesn't get updated with a
#malformed payload)
if [[ ! $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	exit 1
fi
#get current

/usr/local/bin/aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID | \
jq -r '.ResourceRecordSets[] | select (.Name == "'"$NAME"'") | select (.Type == "'"$TYPE"'") | .ResourceRecords[0].Value' > /tmp/current_route53_value


#check if IP is different from Route 53
if grep -Fxq "$IP" /tmp/current_route53_value; then
  echo "IP Has Not Changed, Exiting"
  exit 1
fi
echo "IP Changed, Updating Records"
#prepare route 53 payload
cat > /tmp/route53_changes.json << EOF
   {
	"Comment":"Updated From DDNS Shell Script",
	"Changes":[
          { 
		"Action":"UPSERT",
		"ResourceRecordSet":{
		"ResourceRecords":[
		  {
                	"Value":"$IP"
                  }
                 ],
		"Name":"$NAME",
		"Type":"$TYPE",
		"TTL":$TTL
          }
        }
      ]
    }
EOF

#update records
/usr/local/bin/aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file:///tmp/route53_changes.json >> /dev/null

#Update sudo crontab -e
#* * * * * /home/mrt/update_dns.sh >/dev/null 2>&1