osp_detect() {
  case $1 in
    *.conf) SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *music {/p}" $1 | sed -r "s/( *).*/\1/")
            EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\music {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
            for EFFECT in ${EFFECTS}; do
              SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
              [ "$EFFECT" != "atmos" ] && sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/ s/^/#/g}" $1
            done;;
     *.xml) EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"music\">$/,/^ *<\/stream>$/ {/<stream type=\"music\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; p}}" $1)
            for EFFECT in ${EFFECTS}; do
              [ "$EFFECT" != "atmos" ] && sed -ri "s/^( *)<apply effect=\"$EFFECT\"\/>/\1<\!--<apply effect=\"$EFFECT\"\/>-->/" $1
            done;;
  esac
}

# Tell user aml is needed if applicable
if $MAGISK && ! $SYSOVERRIDE; then
  if $BOOTMODE; then LOC="/sbin/.core/img/*/system $MOUNTPATH/*/system"; else LOC="$MOUNTPATH/*/system"; fi
  FILES=$(find $LOC -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")
  if [ ! -z "$FILES" ] && [ ! "$(echo $FILES | grep '/aml/')" ]; then
    ui_print " "
    ui_print "   ! Conflicting audio mod found!"
    ui_print "   ! You will need to install !"
    ui_print "   ! Audio Modification Library !"
    sleep 3
  fi
fi

ui_print " "
ui_print "   Removing remnants from past v4a xhifi installs..."
# Uninstall existing v4a installs
V4AAPPS=$(find /data/app -type d -name "*com.vipercn.viper4android_v2*")
if [ "$V4AAPPS" ]; then
  if $BOOTMODE; then
    pm uninstall com.vipercn.viper4android_v2 >/dev/null 2>&1
  else
    rm -rf $V4AAPPS
  fi
fi
# Remove remnants of any old v4a installs
for REMNANT in $(find /data -name "*ViPER4AndroidFX*" -o -name "*com.vipercn.viper4android_v2*"); do
  [ "$(echo $REMNANT | cut -d '/' -f-4)" == "/data/media/0" ] && continue
  if [ -d "$REMNANT" ]; then
    rm -rf $REMNANT
  else
    rm -f $REMNANT
  fi
done

# Detect driver compatibility
ui_print " "
ABIVER=$(echo $ABILONG | sed -r 's/.*-v([0-9]*).*/\1/')
[ -z $ABIVER ] && ABIVER=0
CPUFEAT=$(cat /proc/cpuinfo | grep 'Features')
if [ $ABIVER -ge 7 ] || [ "$(echo $CPUFEAT | grep 'neon')" ]; then
  ui_print "   Neon Device detected!"
  DRV=NEON
elif [ "$(echo $CPUFEAT | grep 'vfp')" ]; then
  ui_print "   Non-neon VFP Device detected!"
  DRV=VFP
elif [ $API -le 13 ] && [ "$(echo $CPUFEAT | grep 'T2')" ]; then
  ui_print "   Non-Neon, Non-VFP, T2 Device detected!"
  DRV=T2
else
  ui_print "   Non-Neon, Non-VFP Device detected!"
  DRV=NOVFP
fi

PATCH=true
mkdir -p $INSTALLER/system/lib/soundfx
if [ $API -le 13 ]; then
  [ $API -le 10 ] && PATCH=false
  cp -f $INSTALLER/custom/ViPER4AndroidXHiFi.apk $INSTALLER/system/app/ViPER4AndroidXHiFi/ViPER4AndroidXHiFi.apk
  cp -f $INSTALLER/custom/libv4a_xhifi_gb_$DRV.so $INSTALLER/system/lib/soundfx/libv4a_xhifi_gb.so
  sed -ri "s/version=(.*)/version=\1 (2.1.0.2)/" $INSTALLER/module.prop
elif [ $API -le 15 ]; then
  cp -f $INSTALLER/custom/libv4a_xhifi_ics_$DRV.so $INSTALLER/system/lib/soundfx/libv4a_xhifi_ics.so
  sed -ri "s/version=(.*)/version=\1 (2.1.0.2-1)/" $INSTALLER/module.prop
else
  cp -f $INSTALLER/custom/libv4a_xhifi_jb_$DRV.so $INSTALLER/system/lib/soundfx/libv4a_xhifi_ics.so
  sed -ri "s/version=(.*)/version=\1 (2.1.0.2-1)/" $INSTALLER/module.prop
fi

if $PATCH; then
  ui_print " "
  ui_print "   Patching existing audio_effects files..."
  for OFILE in ${CFGS}; do
    FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
    cp_ch_nb $ORIGDIR$OFILE $FILE
    osp_detect $FILE
    case $FILE in
      *.conf) sed -i "/v4a_standard_xhifi {/,/}/d" $FILE
              sed -i "/v4a_xhifi {/,/}/d" $FILE
              sed -i "s/^effects {/effects {\n  v4a_standard_xhifi { #$MODID\n    library v4a_xhifi\n    uuid d92c3a90-3e26-11e2-a25f-0800200c9a66\n  } #$MODID/g" $FILE
              sed -i "s/^libraries {/libraries {\n  v4a_xhifi { #$MODID\n    path $LIBPATCH\/lib\/soundfx\/libv4a_xhifi_ics.so\n  } #$MODID/g" $FILE;;
      *.xml) sed -i "/v4a_standard_xhifi/d" $FILE
             sed -i "/v4a_xhifi/d" $FILE
             sed -i "/<libraries>/ a\        <library name=\"v4a_xhifi\" path=\"libv4a_xhifi_ics.so\"\/><!--$MODID-->" $FILE
             sed -i "/<effects>/ a\        <effect name=\"v4a_standard_xhifi\" library=\"v4a_xhifi\" uuid=\"d92c3a90-3e26-11e2-a25f-0800200c9a66\"\/><!--$MODID-->" $FILE;;
    esac
  done
fi
