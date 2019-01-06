#!/bin/bash
COLS=`tput cols`
LINES=`tput lines`
WINDOW_WIDTH=60
WINDOW_HEIGHT=24
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
BORDER_COLOUR=`tput setab 4`
WINDOW_BG=`tput setab 7`
RESET=`tput sgr0`

function tb_border {
	local line
	line="${line}${sequence}"
	for i in `seq 1 $TB_BORDER`
	do
	    line="${line}${BORDER_COLOUR}"
	    for j in `seq 1 $COLS`
	    do
	        line="${line}x"
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
	    border="${border}y"
	done
        border="${border}${RESET}"
	echo $border
}

function window_line {
	local line
	line=`lr_border`
	line="${line}${WINDOW_BG}"
	for l in `seq 1 $WINDOW_WIDTH`
	do
	    line="${line}z"
	done
	line="${line}${RESET}"
	line="${line}`lr_border`"
	echo $line
}

function msg_window {
	local window
	window=`tb_border`
	for h in `seq 1 $WINDOW_HEIGHT`
        do
	    window="${window}`window_line`"
	done
	window="${window}`tb_border`"
	echo $window
}

echo "LINES: $LINES"
echo "WINHEIGHT: $WINDOW_HEIGHT"
echo "BORDER: $TB_BORDER"
echo -n `msg_window`
