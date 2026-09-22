#!/bin/zsh
# Capture raw App Store screenshots from the simulator in a given locale.
# Usage: ./capture.sh <language> <udid> [outdir] [AppleLocale]   e.g. ./capture.sh en <udid> raw_en en_US
# The app's DEBUG demo harness (-seedDemo) seeds a 47-day streak so the shots
# show a populated app rather than an empty first-run state, and suppresses the
# badge-unlock toasts (GamificationOverlay.show) that used to land in the frame.
set -e
LOC=${1:?locale}; UDID=${2:?udid}; OUT=${3:-raw_$LOC}; REGION=${4:-${LOC//-/_}}
BUNDLE=com.clawdbonzo.HealNoContact
mkdir -p "$OUT"
# Same clock/battery/signal in every locale. Unpinned captures shipped with 5:16, 5:18,
# 5:27 ... side by side, one of the things that made the sets look inconsistent.
xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi --wifiMode active \
    --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
screens=(home:01-streak commitment:02-commitment progress:03-progress insights:04-insights \
         letter:05-letter welcome:06-welcome settings:07-privacy paywall:08-premium)
for pair in $screens; do
  scr=${pair%%:*}; name=${pair##*:}
  # ONLY="01-streak 08-premium" ./capture.sh ... recaptures just those shots.
  [[ -n "$ONLY" && " $ONLY " != *" $name "* ]] && continue
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" -seedDemo YES -demoScreen "$scr" \
      -AppleLanguages "($LOC)" -AppleLocale "$REGION" >/dev/null
  sleep 7
  # Verify Heal is actually the frontmost app. On a shared simulator another
  # project's app can sit in front and simctl will happily screenshot THAT —
  # which is how a set of Arabic screenshots once ended up showing someone
  # else's app under a correct Arabic headline.
  front=$(xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -c "UIKitApplication:$BUNDLE" || true)
  if [ "$front" -eq 0 ]; then
    echo "  !! ABORT: $BUNDLE is not running on $UDID — refusing to capture $name" >&2
    exit 1
  fi
  xcrun simctl io "$UDID" screenshot --type=png "$OUT/$name.png" >/dev/null 2>&1
  echo "  captured $LOC/$name"
done
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
