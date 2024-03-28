## Part 1

1.  **top 5 IP addresses requests come from;**

**Command:** ```awk '{print $3}' access.log | sort | uniq -c | sort -nr | head -5```
**Results:** 
```
$ awk '{print $3}' access.log | sort | uniq -c | sort -nr | head -5
   1184 98.126.83.64
      1 99.90.171.165
      1 99.9.195.153
      1 99.81.223.86
      1 99.4.242.220
```
**Comments:** In this command, we are focusing on the 3rd column which contains IP addresses requests come from. Along with this command, we are piping the results of the previous commands, sorting the IP addresses in a numerical order, filtering and counting the sorted values, sorting them again in descending order, and finally, cutting and showing top-5 results.      

2.  **number of requests with '500' and '200' HTTP codes;**

**Command for '200' HTTP codes:** ```awk '$4 == 200 {count++} END {print count}' access.log```
**Results:** 
```
$ awk '$4 == 200 {count++} END {print count}' access.log
1849
```
**Command for '500' HTTP codes:** ```awk '$4 == 500 {count++} END {print count}' access.log```
**Results:** empty output = no 500 logs
**Comments:** Both commands are incrementing the 'count' value each time the value in the 4th column with HTTP code equals 200 or 500. At the end of the script's work, the command prints the counted value.

**Alternative command to confirm the results above:** ```awk '{print $4}' access.log | sort | uniq -c | sort -r```
**Results:** 
```
$ awk '{print $4}' access.log | sort | uniq -c | sort -r
   1849 200
   1772 404
    379 499
```
**Comments:** Here we are taking all the HTTP codes from the file, sorting them before filtering and counting, and then, sorting them again in descending order.

3.  **number of requests per minute;**

**Command:** ```cut -d' ' -f1,2 test.log | cut -d':' -f1,2 | sort | uniq -c```
**Results:** 
```
$ cut -d' ' -f1,2 access.log | cut -d':' -f1,2 | sort | uniq -c
    802 04/Oct/2023 15:00
    801 04/Oct/2023 15:01
    778 04/Oct/2023 15:02
    800 04/Oct/2023 15:03
    808 04/Oct/2023 15:04
     11 04/Oct/2023 15:05
```
**Comments:** In the first 'cut' iteration, we are taking out the date and the time to the pipe by pointing to the 1st and 2nd fields. Then, we are cutting off the seconds number since we need to calculate requests per minute by using the ':' delimiter. And, finally, the results are sorted and calculated.

4.  **which domain is the most requested one?**

**Command:** ```awk '{print $5}' access.log | sort | uniq -c | sort -nr | head -1```
**Results:** 
```
$ awk '{print $5}' access.log | sort | uniq -c | sort -nr | head -1
   2009 example2.com
```
**Comments:** We are focusing on the 5th column that contains domains, sorting-filtering-counting-sorting the way it was performed in the previous commands, and displaying only top-1 result. We can also see the whole top-list by removing ```| head -1```

5. **do all the requests to '/page.php' result in '499' code?**

**Command:** ```awk '/page.php/ {print $0}' access.log | awk '$4 != 499 {print $0}'```
**Results:** empty output which means that 'awk' didn't find any other requests to 'page.php' that don't equal 499, so the answer is "yes".
**Comments:** Here we are specifying the condition for 'awk' to search for mentions of 'page.php' (we could also specify the exact column for search, as in the alternative command below, but I believe it is not obligatory in our case) and  'print $0' means to display all the columns. This output is piped for further checking if the gathered 'page.php'-related requests don't have the 499 status.

**Alternative command to count the requests:** ```awk '$6 == "/page.php" && $4 != 499 {count++} END {print count}' access.log```
**Comments:** It checks specifically the requested pages and the received HTTP codes at once. If any matches found - the number of such requests is printed.

## Part 2
**Based on log and gathered data, can you outline any anomalies that should be taken into attention?**

[1] As we already know, all the requests with the 499 status code are sent to the /page.php. Also, it is worth checking if all these requests are related to the same domain (and it is):
```
$ awk '$4 == 499{print $5}' access.log | sort | uniq -c | sort -nr
    379 example4.com
```
Additionally, it means that all requests to example4.com had the 499 HTTP response code, and they were all targeted to /page.php. So at this point, it would be worth checking if the website works fine and if it is a DDoS.

[2] We have another error code which is 404. Using the following command, we can define the domains and pages requested: 
```
$ awk '$4 == 404{print $5,$6}' access.log | sort | uniq -c | sort -nr
    992 example2.com /wp-login.php
    575 example3.com /page.html
    205 example1.com /page.html
```
It also may be useful to check the specified websites and the corresponding pages. 

[3] By getting back to the top-1 IP address, we can check its requests: 
```
$ awk '$3 == "98.126.83.64"{print $4,$5,$6}' access.log | sort | uniq -c | sort -nr
    609 200 example3.com /page.html
    575 404 example3.com /page.html
```
We can also improve its readability:
```
$ awk '$3 == "98.126.83.64"{print $4,$5,$6}' access.log | sort | uniq -c | sort -nr | awk 'BEGIN {print "Q-ty Code Domain Page"} {print $0}' | column -t
Q-ty  Code  Domain        Page
609   200   example3.com  /page.html
575   404   example3.com  /page.html
```
This IP address sends a lot of requests to the specific page, so it would be good to keep an eye on it and block if needed.

[4] Let's also get the general statistics:
```
$ awk '{print $4,$5,$6}' access.log | sort | uniq -c | sort -nr | awk 'BEGIN {print "Q-ty Code Domain Page"} {print $0}' | column -t
Q-ty  Code  Domain        Page
1017  200   example2.com  /wp-login.php
992   404   example2.com  /wp-login.php
609   200   example3.com  /page.html
575   404   example3.com  /page.html
379   499   example4.com  /page.php
223   200   example1.com  /page.html
205   404   example1.com  /page.html
```

**Short conclusions:**
- 98.126.83.64 (for example3.com): review if it is not DDoSing/brute-forcing
- example1.com and example3.com: double-check if the specified page can be accessed properly
- example2.com: check if the '/wp-login.php' works fine or if it is DDoS/brute-force
- example4.com: check '/page.php'