#!/bin/bash

cleanup() {
    # SIGTERM is propagated to children.
    # Timeout is managed directly by Docker, via it's '-t' flag:
    # if SIGTERM does not teminate the entrypoint, after the time
    # defined by '-t' (default 10 secs) the container is killed
    kill $XVFB_PID $QGIS_PID
}

waitfor() {
    # Make startup syncronous
    while ! pidof $1 >/dev/null; do
        sleep 1
    done
    pidof $1
}

trap cleanup SIGINT SIGTERM


# additional fonts
#ln -s /geodata/1_Vorlagen/15_QGIS/Fonts /usr/share/fonts/giszug
#/usr/bin/fc-cache -v /usr/share/fonts

rm -f /tmp/.X99-lock
/usr/bin/Xvfb :99 -ac -screen 0 1280x1024x16 +extension GLX +render -noreset 2>&1 >/dev/null &
XVFB_PID=$(waitfor /usr/bin/Xvfb)

# /run/qgisX.pid can be used to restart the process
# kill -9 `cat /run/qgisX.pid`
spawn-fcgi -n -u qgis -g qgis -d /var/lib/qgis -P /run/qgis.pid -p 9991 -- /usr/bin/qgis_mapserv.fcgi &
QGIS_PID=$(waitfor /usr/bin/qgis_mapserv.fcgi)
wait $QGIS_PID
