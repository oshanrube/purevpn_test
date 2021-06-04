#/bin/bash

echo "starting"

wget https://s3-us-west-1.amazonaws.com/heartbleed/windows/New+OVPN+Files.zip
unzip New+OVPN+Files.zip
rm New+OVPN+Files.zip
mv New\ OVPN\ Files purevpn

echo "" >final_output.csv
printf "filename, Country, City, ping min,ping avg,ping max,ping mdev \n" >>final_output.csv

for location in purevpn/*/*; do
  echo "running $location"
  openvpn --config $location --auth-user-pass auth.txt --daemon --log "outputs/$location.log"
  sleep 10
  if grep -q "Initialization Sequence Completed" outputs/$location.log; then
    echo "Connection successfull"
    echo "saving the location"
    curl ifconfig.co/json >"outputs/$location.json"
    echo "saving ping stats"
    ping -c 4 8.8.8.8 >"outputs/$location.ping"

    COUNTRY=$(grep "country\"" outputs/$location.json | sed 's/  "country": "//i' | sed 's/",//i')
    CITY=$(grep "city\"" outputs/$location.json | sed 's/  "city": "//i' | sed 's/",//i')
    PING=$(tail -1 outputs/$location.ping | sed 's/rtt min\/avg\/max\/mdev = //i' | sed 's/\//,/g')
    printf "$location, $COUNTRY, $CITY, $PING \n" >>final_output.csv
  else
    echo "Connection failed"
  fi
  killall openvpn
done

echo "done"
