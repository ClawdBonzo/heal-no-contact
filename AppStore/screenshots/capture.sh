#!/bin/zsh
# Capture raw App Store screenshots from the simulator in a given locale.
# Usage: ./capture.sh <locale> <udid> [outdir]
# The app's DEBUG demo harness (-seedDemo) seeds a 47-day streak so the shots
# show a populated app rather than an empty first-run state.
set -e
LOC=${1:?locale}; UDID=${2:?udid}; OUT=${3:-raw_$LOC}
BUNDLE=com.clawdbonzo.HealNoContact
mkdir -p "$OUT"
screens=(home:01-streak commitment:02-commitment progress:03-progress insights:04-insights \
         letter:05-letter welcome:06-welcome settings:07-privacy paywall:08-premium)
for pair in $screens; do
  scr=${pair%%:*}; name=${pair##*:}
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" -seedDemo YES -demoScreen "$scr" \
      -AppleLanguages "($LOC)" -AppleLocale "$LOC" >/dev/null
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
