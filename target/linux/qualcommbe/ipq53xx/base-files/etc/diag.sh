#!/bin/sh
# Copyright (C) 2026 OpenWrt.org

. /lib/functions.sh
. /lib/functions/leds.sh

get_status_led() {
	case $(board_name) in
	xiaomi,rn01)
		# The board's only status indicator is a bi-color (orange/blue)
		# PWM LED, exposed as two led-class devices. Blue is the
		# "system is fine" colour in the vendor firmware, so use it for
		# the normal boot progression.
		status_led="blue:status"
		;;
	*)
		status_led=$(cd /sys/class/leds && ls -1d *:status 2> /dev/null | head -n 1)
		;;
	esac
}

set_state() {
	get_status_led

	case "$1" in
	preinit)
		status_led_blink_preinit
		;;
	failsafe)
		status_led_blink_failsafe
		;;
	preinit_regular)
		status_led_blink_preinit_regular
		;;
	done)
		status_led_on
		;;
	esac
}
