#!/bin/bash
MONITOR_INTERFACES=(wlx4c60def132e8 wlx00c0ca8525ee)
interface_5g=wlx4c60def132e8 # NG
interface_24g=wlx00c0ca8525ee # Ralink
channel_5g=1
channel_24g=6
jsonfile=/var/log/tshark.json

airmon () {
airmon-ng $1 $2 $3 && monitor_mode=true
}

channel_check () {
iw $1 info | grep channel | awk {'print $2'}
}

while true ;do
   if [ -d '/sys/class/net/wlan1mon' ] && [ -d '/sys/class/net/wlan2mon' ];then monitor_mode=true
      if [ `cat /sys/class/net/wlan1mon/flags` != "0x1003" ]; then ifconfig wlan1mon up
      elif [ `cat /sys/class/net/wlan2mon/flags` != "0x1003" ]; then ifconfig wlan2mon up
      fi
   sleep 1
          if [ `iw wlan1mon info | grep channel | awk {'print $2'}` -ne $channel_24g ]; then
	       echo "wrong channel detected on wlan1mon: $channel_24g"
	       declare -i error_code=2
	 else error_code=0
         fi
         if [ `iw wlan2mon info | grep channel | awk {'print $2'}` -ne $channel_5g ]; then
	        echo "wrong channel detected on wlan2mon: $channel_5g"
	        declare -i error_code=2
	 else error_code=0
            fi
   else
	monitor_mode=false && declare -i error_code=1
   fi
   if [ $monitor_mode = false ] || [ $error_code -ne 0 ];then
      if [ $error_code -eq 2 ]; then echo "Setting correct channel on wlan interfaces"
         for interface in {wlan1mon wlan2mon};do 
            if [ $interface_5g = "$interface" ]; then iw $interface set channel $channel_5g
            elif [ $interface_24g = "$interface" ]; then iw $interface set channel $channel_24g
            fi
	 declare -i error_code=0
         done
      fi
      if [ $error_code -eq 1 ]; then echo "Reinit on wlan interfaces due to monitor mode not properly actived"
         for interface in ${MONITOR_INTERFACES[@]};do 
	    if [ $interface_5g = "$interface" ]; then airmon start $interface $channel_5g
	    elif [ $interface_24g = "$interface" ]; then airmon start $interface $channel_24g
	    fi
	    sleep 1
	    ifconfig wlan1mon up
	    ifconfig wlan2mon up
	    sleep 1
	 done
      fi
   fi
   if [ $monitor_mode = true ] && [ `pgrep -fca 'tshark -i wlan1mon'` -lt 1 ]; then
               /usr/bin/tshark -i wlan1mon -i wlan2mon -f "type mgt subtype probe-resp or type mgt subtype probe-req or type mgt subtype assoc-req or type mgt subtype assoc-resp or type mgt subtype reassoc-req or type mgt subtype reassoc-resp or type mgt subtype disassoc or type mgt subtype auth or type mgt subtype deauth" -e wlan.fc.type_subtype -e wlan.da -e wlan.da_resolved -e wlan.sa -e wlan.sa_resolved -e wlan_radio.data_rate -e wlan.fc.retry -e wlan_radio.signal_dbm -e wlan_radio.signal_dbm -e wlan.ra_resolved -e wlan.ta -e wlan.ta_resolved -e wlan_mgt.ssid -e wlan_mgt.ds.current_channel -e wlan_mgt.qbss.cu -e wlan_mgt.qbss.scount -e wlan_mgt.qbss.adc -e wlan_mgt.extcap.b19 -e wlan_mgt.fixed.bss_transition_status_code -e wlan_mgt.fixed.bss_transition_target_bss -e wlan_mgt.fixed.bss_transition_candidate_list_entries -T ek >> $jsonfile
   fi
sleep 5
done
