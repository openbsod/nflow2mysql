Pushing Netflow v9 data to MySQL
=======
# nflow2mysql

Place files whatever you want. Create DB with
```
mysql -uroot -p < dbinstall.sql
```
start collecting with
```
./dbcollector.pl
```
Check collector output:

![alt text](https://github.com/openbsod/nflow2mysql/blob/master/images/portlistener.png)

Check MySQL:

![alt text](https://github.com/openbsod/nflow2mysql/blob/master/images/raw_flow.png)

That`s all. Quick and dirty.. 
