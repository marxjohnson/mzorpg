#!/bin/bash
COLS=`tput cols`
LINES=`tput lines`
WINDOW_WIDTH=100
WINDOW_HEIGHT=30
if [ $((COLS % 2)) -eq 1 ]
then
    WINDOW_WIDTH=$((WINDOW_WIDTH+1))
fi
if [ $((LINES % 2)) -eq 1 ]
then
    WINDOW_HEIGHT=$((WINDOW_HEIGHT+1))
fi
TB_BORDER=$(((LINES - WINDOW_HEIGHT) / 2))
LR_BORDER=$(((COLS - WINDOW_WIDTH) / 2))
BORDER_COLOUR=`tput sgr0``tput setaf 4`
WINDOW_BLANK=`tput sgr0``tput setaf 7`
WINDOW_TEXT=`tput sgr0``tput setab 7``tput setaf 0`
RESET=`tput sgr0`
FG_RED=`tput setaf 1`
FG_GREEN=`tput setaf 2`
BOLD=`tput bold`
CURSOR_LINE=$TB_BORDER
PREVIOUS_LINE_COUNT=0

function tb_border {
	local line
	line="${line}${sequence}"
	for i in `seq 1 $TB_BORDER`
	do
	    line="${line}${BORDER_COLOUR}"
	    for j in `seq 1 $COLS`
	    do
	        line="${line}█"
	    done	    
	    line=${line}${RESET}
	done
	line=${line}
	echo "$line"
}

function lr_border {
	local border
        border=$BORDER_COLOUR
	for k in `seq 1 $LR_BORDER`
	do
	    border="${border}█"
	done
        border="${border}${RESET}"
	echo $border
}

function show_window_line {
	local line
	line=`lr_border`
	line="${line}${WINDOW_BLANK}"
	for l in `seq 1 $WINDOW_WIDTH`
	do
	    line="${line}█"
	done
	line="${line}${RESET}"
	line="${line}`lr_border`"
	echo $line
}

function window_line {
	local line
	local message
	local message_length
	local line_end
	local visible_message
	message=$1
	message_length=${#message}
	line_end=$((WINDOW_WIDTH-message_length))
	line="${line}${WINDOW_BLANK}"
	if [ ! -z "${message}" ]
	then
	    line_end=$((line_end-1))
	    line="${line}█${WINDOW_TEXT}${message}${WINDOW_BLANK}"
	fi
	for l in `seq 1 $line_end`
	do
	    line="${line}█"
	done
	line="${line}${RESET}"
	CURSOR_LINE=$((CURSOR_LINE+1))
	echo $line
	tput cup $CURSOR_LINE $LR_BORDER
}

function show_window {
	local window
	window=`tb_border`
	for h in `seq 1 $WINDOW_HEIGHT`
        do
	    window="${window}`show_window_line`"
	done
	window="${window}`tb_border`"
	echo $window
}

function update_window {
	local window
	local message_lines
	local line_count
	local window_bottom
	local cursor_line
	CURSOR_LINE=$TB_BORDER
	tput cup $CURSOR_LINE $LR_BORDER
	line_count=1
	IFS=$'\n' message_lines=($1)
	for line in "${message_lines[@]}"
	do
	    if [ ! -z "${line}" ]
	    then
	        window_line "${line}"
		line_count=$((line_count+1))
	    fi
	done
	clear_lines=$((PREVIOUS_LINE_COUNT-line_count))
	if [[ clear_lines -gt 0 ]]
	then
	    for h in `seq 1 $clear_lines`
            do
	        window_line
	    done
	fi
	PREVIOUS_LINE_COUNT=$line_count
}

function status_bar {
	local window_line
	local message
	message=$1
	window_line=$((TB_BORDER+WINDOW_HEIGHT-3))
	tput cup $window_line $LR_BORDER
	window_line $message
}


show_window
