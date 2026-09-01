if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx > /root/xsession.log 2>&1
fi
