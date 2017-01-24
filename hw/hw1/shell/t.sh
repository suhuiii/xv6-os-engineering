ls > y
cat < y | /usr/bin/sort | uniq | wc > y1
cat y1
rm y1
ls |  /usr/bin/sort | uniq | wc
rm y
