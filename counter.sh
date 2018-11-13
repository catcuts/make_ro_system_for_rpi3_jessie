START=`date +%s%N`;
sleep 3;
END=`date +%s%N`;
time=$((END-START))
time=`echo "$time" | awk '{printf ("%.2f\n", $time/1000000000)}'`
#time=`expr $time / 1000000`
echo $time
