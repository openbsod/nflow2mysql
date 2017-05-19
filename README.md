Pushing Netflow v9 data to MySQL
=======
# nflow2mysql

Place files whatever you want. Create DB with
```
mysql -uroot -p < install_db.sql
```
start collecting with
```
./dbcollector.pl
```
Check collector output:

![alt text](https://github.com/openbsod/nflow2mysql/blob/master/images/portlistener.png)

Check MySQL:

![alt text](https://github.com/openbsod/nflow2mysql/blob/master/images/raw_flow.png)

You can find additional info here (https://www.iana.org/assignments/ipfix/ipfix.xml)
and also at (https://tools.ietf.org/html/rfc7012)

That`s all. Quick and dirty.. 
