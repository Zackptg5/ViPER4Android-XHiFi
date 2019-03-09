(until [ $(getprop sys.boot_completed) -eq 1 ]; do
  sleep 5
done
am start -a android.intent.action.MAIN -n com.vipercn.viper4android.xhifi/.main.ViPER4Android_XHiFi
until [ "$(pidof com.vipercn.viper4android.xhifi)" ]; do
  sleep 3
done
killall com.vipercn.viper4android.xhifi
killall audioserver
killall mediaserver)&
