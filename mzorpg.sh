#!/bin/bash

if [ -z "$1" ]
then
    NAME="$USER"
else
    NAME="$1"
fi
SPEED=0.2
DB=/tmp/mzorpg.db

COLS=`tput cols`
LINES=`tput lines`
WINDOW_WIDTH=100
WINDOW_HEIGHT=30
if [[ $COLS -lt $WINDOW_WIDTH || $LINES -lt $WINDOW_HEIGHT ]]
then
    echo "Your teminal must be at least 100x30 characters to run mzorpg"
    exit 1
fi
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

function message {
    update_window "$1"
}

function fight_status {
    local MONSTER_HP=$1
    local TOTAL_MONSTER_HP=$2
    local PLAYER_HP=$3
    local TOTAL_PLAYER_HP=$4
    local MESSAGE=$5
    local MONSTER_NAME=$6
    local PLAYER_BAR=$(vitality_bar $PLAYER_HP $TOTAL_PLAYER_HP)
    local MONSTER_BAR=$(vitality_bar $MONSTER_HP $TOTAL_MONSTER_HP)
    local PLAYER_LABEL="Your vitality:"
    local MONSTER_LABEL="${MONSTER_NAME} vitality:"
    local PLAYER_LABEL_LENGTH=${#PLAYER_LABEL}
    local MONSTER_LABEL_LENGTH=${#MONSTER_LABEL}
    if [ $PLAYER_LABEL_LENGTH -gt $MONSTER_LABEL_LENGTH ]
    then
        local DIFF=$((PLAYER_LABEL_LENGTH - MONSTER_LABEL_LENGTH))
        while [ $DIFF -gt 0 ]
        do
            MONSTER_LABEL="${MONSTER_LABEL} "
            DIFF=$((DIFF-1))
        done
    else
        local DIFF=$((MONSTER_LABEL_LENGTH - PLAYER_LABEL_LENGTH))
        while [ $DIFF -gt 0 ]
        do
            PLAYER_LABEL="${PLAYER_LABEL} "
            DIFF=$((DIFF-1))
        done
    fi
    local STATUS="
$MESSAGE

$PLAYER_LABEL $PLAYER_BAR$WINDOW_TEXT $PLAYER_HP

$MONSTER_LABEL $MONSTER_BAR$WINDOW_TEXT $MONSTER_HP
"
    message "$STATUS"
}

function wait_for_ready {
    sleep 0.001
}

function send_fight_status {
    local MONSTER_HP=$1
    local TOTAL_MONSTER_HP=$2
    local PLAYER_HP=$3
    local TOTAL_PLAYER_HP=$4
    local MESSAGE=$5
    local PIPE=$6
    local MONSTER_NAME=$7
    local STATUS=`fight_status $1 $2 $3 $4 $5 $7`
    while read -r LINE; do
         echo "${LINE}" >$PIPE
         wait_for_ready
    done <<< "$STATUS"
    echo $EOM >$PIPE
    wait_for_ready
}

function vitality_bar {
    CURRENT_VALUE=$1
    TOTAL_VALUE=$2
    PERCENTAGE=$((CURRENT_VALUE * 100 / TOTAL_VALUE))
    if [ $PERCENTAGE -eq 100 ]
    then
        PERCENTAGE=99
    fi

    LENGTH=33
    FULL=$((PERCENTAGE / 3 ))
    PARTIAL=$((PERCENTAGE % 3 ))
    EMPTY=$(($LENGTH - $FULL - 1))
    BAR="${BOLD}${FG_GREEN}"

    for i in `seq 1 $FULL`
    do
        BAR=$BAR"█"
    done

    BAR="${BAR}${RESET}"

    if [ $PARTIAL -eq 2 ]
    then
        BAR=${BAR}${FG_GREEN}"█"
    elif [ $PARTIAL -eq 1 ]
    then
        BAR=${BAR}${FG_RED}"█"
    elif [ $FULL -lt $LENGTH ]
    then
        EMPTY=$((EMPTY+1))
    fi

    if [ $EMPTY -gt 0 ]
    then
        BAR=${BAR}${BOLD}${FG_RED}
        for i in `seq 1 $EMPTY`
        do
            BAR=$BAR"█"
        done
    fi
    BAR=${BAR}${RESET}

    echo $BAR
}

function update_status {
    status_bar "Level: ${LEVEL} | Score: ${SCORE} | Hit points ${HP} | Armour class ${AC}"
}

function query {
    local RETURN=1
    local TIMEOUT=10
    while [ $RETURN -gt 0 ]
    do
        sqlite3 "$DB" $1 2>/dev/null
	RETURN=$?
	TIMEOUT=$((TIMEOUT - 1))
	if [ $TIMEOUT -eq 0 ]
	then
	    echo "Could not run query $1"
	    exit 1
	fi
    done
}

function create_db {
    query <<EOF
         CREATE TABLE battles (
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             agressor_id INTEGER NOT NULL,
	           defender_id INTEGER,
             confirmed INTEGER
         );
         CREATE TABLE characters (
             id INTEGER PRIMARY KEY,
             name VARCHAR(255) UNIQUE NOT NULL,
             level INTEGER NOT NULL,
             score INTEGER NOT NULL,
             hp INTEGER NOT NULL,
             ac INTEGER NOT NULL
         );
EOF
}

function register_character {
    query <<EOF
        INSERT INTO characters (name, level, score, hp, ac) VALUES ('${1//\'/\'\'}', $2, $3, $4, $5);
        SELECT last_insert_rowid();
EOF
}

function load_character {
    query <<EOF
	      SELECT * FROM characters WHERE name='${1//\'/\'\'}'
EOF
}

function save_score {
    query <<EOF
        UPDATE characters SET score=$1 WHERE id = $2
EOF
}

function save_level {
    query <<EOF
        UPDATE characters SET level=$1 WHERE id = $2
EOF
}

function find_battle_offer {
    query <<EOF
        SELECT b.id
        FROM battles b
        JOIN characters c ON c.id = b.agressor_id
        WHERE b.defender_id IS NULL AND c.level = $1
EOF
}

function create_battle_offer {
    query <<EOF
	      INSERT INTO battles (agressor_id) VALUES ($1);
        SELECT last_insert_rowid();
EOF
}

function accept_battle_offer {
    query <<EOF
	      UPDATE battles SET defender_id = $2 WHERE id = $1;
EOF
}

function check_battle_offer {
    query <<EOF
	      SELECT * FROM battles WHERE defender_id IS NOT NULL AND id = $1
EOF
}

function confirm_battle_offer {
    query <<EOF
	      UPDATE battles SET confirmed = 1 WHERE id = $1;
EOF
}

function check_battle_offer_confirmed {
    query <<EOF
	      SELECT * FROM battles WHERE defender_id = $2 AND id = $1 AND confirmed = 1
EOF
}

function clear_battle {
    local ID=$1
    query <<EOF
	      DELETE FROM battles WHERE ID = $ID
EOF
    rm "/tmp/mzorpg${ID}.battle"
}


function pick_a_fight {
    local BATTLE_ID
    local BATTLE
    local CONFIRMED
    local ID
    local TIMEOUT
    ID=$1
    BATTLE_ID=`find_battle_offer $LEVEL`
    if [ -z $BATTLE_ID ]
    then
        #echo "No battle found for level ${LEVEL}" >> "/tmp/mzorpg.${NAME}.log"
        BATTLE_ID=`create_battle_offer $ID`
        #echo "Created battle ID ${BATTLE_ID} for ${LEVEL}" >> "/tmp/mzorpg.${NAME}.log"
	      while [ -z $BATTLE ]
	      do
            #echo "Waiting for ${BATTLE_ID} to be accepted" >> "/tmp/mzorpg.${NAME}.log"
            sleep 5
            BATTLE=`check_battle_offer $BATTLE_ID`
	      done
    	  #echo "Battle ${BATTLE_ID} accepted. confirming." >> "/tmp/mzorpg.${NAME}.log"
	      #echo "${BATTLE}" >> "/tmp/mzorpg.${NAME}.log"
	      confirm_battle_offer $BATTLE_ID
    else
        #echo "Found battle ID ${BATTLE_ID} for level ${LEVEL}" >> "/tmp/mzorpg.${NAME}.log"
        accept_battle_offer $BATTLE_ID $ID
	      TIMEOUT=5
	      while [[ $TIMEOUT != 0 ]]
	      do
            #echo "Waiting for confirmation of ${BATTLE_ID} ." >> "/tmp/mzorpg.${NAME}.log"
            sleep 5
            CONFIRMED=`check_battle_offer_confirmed $BATTLE_ID $ID`
	          if [ ! -z $CONFIRMED ]
            then
	              mkfifo "/tmp/mzorpg${BATTLE_ID}.battle"
		            #echo "Created FIFO for ${BATTLE_ID}" >> "/tmp/mzorpg.${NAME}.log"
                BATTLE=`check_battle_offer $BATTLE_ID`
	              #echo "${BATTLE}" >> "/tmp/mzorpg.${NAME}.log"
		            break
            fi
	          TIMEOUT=$((TIMEOUT - 1))
	      done
        if [ -z $BATTLE ]
        then
	          #echo "Timed out waiting for confirmation. Retrying." >> "/tmp/mzorpg.${NAME}.log"
	          # The battle was never confirmed, try again.
	          BATTLE=`pick_a_fight $ID`
	      fi
    fi
    echo "${BATTLE}"
}

function roll_stats {
    local HP_BONUS=$((RANDOM % 5))
    local AC_BONUS=$((5 - HP_BONUS))
    HP=$((20 + HP_BONUS))
    AC=$((10 + AC_BONUS))
}

function level_threshold {
    local TRIANGLE=$LEVEL
    local THRESHOLD
    while [ $TRIANGLE -gt 0 ]
    do
        THRESHOLD=$((THRESHOLD+TRIANGLE))
	      TRIANGLE=$((TRIANGLE-1))
    done
    echo $THRESHOLD
}

if [ ! -f "$DB" ]
then
    create_db
fi

EOM="EOM"

CHARACTER=`load_character "$NAME"`

show_window

if [ -z "${CHARACTER}" ]
then
    LEVEL=1
    SCORE=0
    HP=0
    AC=0
    ACCEPTED=0
    while [ "$ACCEPTED" -eq 0 ]
    do
        roll_stats
        STATS="
Welcome, $NAME!

Your statistics:
Hit points: $HP
Armour class: $AC
    
Press y to accept, or r to re-roll
"
        message "$STATS"
        read -n 1 -s KEY
        if [[ "$KEY" == "y" ]]
        then
            ACCEPTED=1
        fi

    done

    ID=`register_character "$NAME" 1 0 $HP $AC`
else
    IFS='|' read -r -a CHARACTER <<< "$CHARACTER"
    ID=${CHARACTER[0]}
    LEVEL=${CHARACTER[2]}
    SCORE=${CHARACTER[3]}
    HP=${CHARACTER[4]}
    AC=${CHARACTER[5]}
    STATS="
    Welcome back, $NAME!
    ID: $ID
    Your statistics:
    Hit points: $HP
    Armour class: $AC
"
    message "$STATS"
fi


update_status
sleep 1
CURRENT_HP=$HP
while true; do
    if [ $SCORE -eq $(level_threshold) ]
    then
        CURRENT_HP=$HP
        message "You drink a potion of healing."
        update_status
        sleep 2
        message "Finding another adventurer to battle..."
        IFS='|' read -r -a BATTLE <<< `pick_a_fight $ID`
        BATTLE_ID=${BATTLE[0]}
        AGRESSOR=${BATTLE[1]}
        DEFENDER=${BATTLE[2]}
        PIPE="/tmp/mzorpg${BATTLE_ID}.battle"
        #echo "Using FIFO ${PIPE}" >> "/tmp/mzorpg.${NAME}.log"
        if [ $AGRESSOR == $ID ]
        then
	          LINE=
            #echo "Agressor in fight ${BATTLE_ID}" >> "/tmp/mzorpg.${NAME}.log"
	          sleep 5
            # Wait for defender's stats.
            while [ -z $LINE ]
            do
                read LINE <$PIPE
            done
            #echo "${LINE}" >> "/tmp/mzorpg.${NAME}.log"
            IFS='|' read -r -a DEFENDER <<< $LINE
            DEFENDER_NAME=${DEFENDER[0]}
            DEFENDER_HP=${DEFENDER[1]}
            DEFENDER_AC=${DEFENDER[2]}
            LOCAL_MESSAGE="
You encountered ${DEFENDER_NAME}! Here are their statistics:
Hit points: $DEFENDER_HP
Armour class: $DEFENDER_AC"
            message "$LOCAL_MESSAGE"
            echo "You encountered ${NAME}! Here are their statistics:" >$PIPE
	          wait_for_ready
	          echo "Hit points: $HP" >$PIPE
	          wait_for_ready
            echo "Armour class: $AC" >$PIPE
	          wait_for_ready
            echo "${EOM}" >$PIPE
            sleep 5
            LOCAL_MESSAGE='FIGHT!!!'
            message "$LOCAL_MESSAGE"
            echo "${LOCAL_MESSAGE}" >$PIPE
	          wait_for_ready
            echo "${EOM}" >$PIPE
            sleep 1

            TURN=1
            CURRENT_DEFENDER_HP=$DEFENDER_HP
            while [ $CURRENT_HP -gt 0 ] && [ $CURRENT_DEFENDER_HP -gt 0 ]; do
                if [ $TURN -eq 1 ]; then
                    fight_status $CURRENT_DEFENDER_HP $DEFENDER_HP $CURRENT_HP $HP "You attack ${DEFENDER_NAME}" "${DEFENDER_NAME}"
                    send_fight_status $CURRENT_HP $HP $CURRENT_DEFENDER_HP $DEFENDER_HP "${NAME} attacks you" $PIPE "${NAME}"
                    sleep $SPEED
                    HIT=$((RANDOM % 20))
                    if [ $HIT -ge $DEFENDER_AC ]; then
                        CURRENT_DEFENDER_HP=$((CURRENT_DEFENDER_HP-1))
                        fight_status $CURRENT_DEFENDER_HP $DEFENDER_HP $CURRENT_HP $HP "You hit them" "${DEFENDER_NAME}"
                        send_fight_status $CURRENT_HP $HP $CURRENT_DEFENDER_HP $DEFENDER_HP "They hit you" $PIPE "${NAME}"
                    else
                        fight_status $CURRENT_DEFENDER_HP $DEFENDER_HP $CURRENT_HP $HP "You miss them" "${DEFENDER_NAME}"
                        send_fight_status $CURRENT_HP $HP $CURRENT_DEFENDER_HP $DEFENDER_HP "They miss you" $PIPE "${NAME}"
                    fi
                    sleep $SPEED
                    TURN=2
                else
                    fight_status $CURRENT_DEFENDER_HP $DEFENDER_HP $CURRENT_HP $HP "${DEFENDER_NAME} attacks you" "${DEFENDER_NAME}"
                    send_fight_status $CURRENT_HP $HP $CURRENT_DEFENDER_HP $DEFENDER_HP "You attack ${NAME}" $PIPE "${NAME}"
                    sleep $SPEED
                    HIT=$((RANDOM % 20))
                    if [ $HIT -ge $AC ]; then
                        fight_status $CURRENT_DEFENDER_HP $DEFENDER_HP $CURRENT_HP $HP "They hit you" "${DEFENDER_NAME}"
                        send_fight_status $CURRENT_HP $HP $CURRENT_DEFENDER_HP $DEFENDER_HP "You hit them" $PIPE "${NAME}"
                        CURRENT_HP=$((CURRENT_HP-1))
                    else
                        fight_status $CURRENT_DEFENDER_HP $DEFENDER_HP $CURRENT_HP $HP "They miss you" "${DEFENDER_NAME}"
                        send_fight_status $CURRENT_HP $HP $CURRENT_DEFENDER_HP $DEFENDER_HP "You miss them" $PIPE "${NAME}"
                    fi
                    sleep $SPEED
                    TURN=1
                fi
            done;
            if [ $CURRENT_HP -gt 0 ]; then
                LEVEL=$((LEVEL+1))
                WIN="
You won!
Welcome to level ${LEVEL}
You drink a potion of healing"
                message "$WIN"
                echo "LOSE" >$PIPE
                save_level $LEVEL $ID
                CURRENT_HP=$HP
                update_status
		            clear_battle $BATTLE_ID
                sleep 2
            else
                LOSE="
You died, sorry!
Your score was $SCORE"
                message "$LOSE"
                echo "WIN" >$PIPE
                break;
            fi
        else
            #echo "Defender in fight ${BATTLE_ID}" >> "/tmp/mzorpg.${NAME}.log"
            # Send stats and wait for futher messages.
	          LINE="${NAME}|${HP}|${AC}"
	            #echo $LINE >> "/tmp/mzorpg.${NAME}.log"
            echo $LINE >$PIPE
            while true
            do
                read LINE <$PIPE
                if [ ! -z $LINE ]
	              then
		                #echo $LINE >> "/tmp/mzorpg.${NAME}.log"
                    if [[ "$LINE" == "WIN" || "$LINE" == "LOSE" ]]
                    then
		                    #echo "FINAL LINE, BREAKING: $LINE" >> "/tmp/mzorpg.${NAME}.log"
                        break
	                  elif [ "$LINE" == "$EOM" ]
		                then
                        message "${MESSAGE}"
                        MESSAGE=""
                    else
                        MESSAGE="${MESSAGE}
${LINE}"
                    fi
                fi
            done

            if [ "$LINE" == "WIN" ]
            then
                LEVEL=$((LEVEL+1))
                WIN="
You won!
Welcome to level ${LEVEL}
You drink a potion of healing"
                message "$WIN"
                save_level $LEVEL $ID
                CURRENT_HP=$HP
                update_status
		            clear_battle $BATTLE_ID
                sleep 2
            else
                LOSE="
You died, sorry!
Your score was $SCORE"
                message "$LOSE"
                break;
            fi
        fi
    else
        message "Finding a monster..."
        MONSTER_HP=$((LEVEL + RANDOM % 5))
        MONSTER_AC=$LEVEL
        sleep 1
        MONSTER="
You found a monster! Here are its statistics:
Hit points: $MONSTER_HP
Armour class: $MONSTER_AC"
        message "$MONSTER"
        sleep 1
        message "FIGHT!!"
        sleep 1

        TURN=1
        CURRENT_MONSTER_HP=$MONSTER_HP
        while [ $CURRENT_HP -gt 0 ] && [ $CURRENT_MONSTER_HP -gt 0 ]; do
            if [ $TURN -eq 1 ]; then
                fight_status $CURRENT_MONSTER_HP $MONSTER_HP $CURRENT_HP $HP "You attack the monster" "Monster"
                sleep $SPEED
                HIT=$((RANDOM % 20))
                if [ $HIT -ge $MONSTER_AC ]; then
                    CURRENT_MONSTER_HP=$((CURRENT_MONSTER_HP-1))
                    fight_status $CURRENT_MONSTER_HP $MONSTER_HP $CURRENT_HP $HP "You hit it" "Monster"
                else
                    fight_status $CURRENT_MONSTER_HP $MONSTER_HP $CURRENT_HP $HP "You miss it" "Monster"
                fi
                sleep $SPEED
                TURN=2
            else
                fight_status $CURRENT_MONSTER_HP $MONSTER_HP $CURRENT_HP $HP "The monster attacks you" "Monster"
                sleep $SPEED
                HIT=$((RANDOM % 20))
                if [ $HIT -ge $AC ]; then
                    fight_status $CURRENT_MONSTER_HP $MONSTER_HP $CURRENT_HP $HP "It hits you" "Monster"
                    CURRENT_HP=$((CURRENT_HP-1))
                else
                    fight_status $CURRENT_MONSTER_HP $MONSTER_HP $CURRENT_HP $HP "It misses you" "Monster"
                fi
                sleep $SPEED
                TURN=1
            fi
        done;

        if [ $CURRENT_HP -gt 0 ]; then
            SCORE=$((SCORE+1))
            WIN="
You won!
Your remaining vitality is $CURRENT_HP out of $HP
You current score is $SCORE"
            message "$WIN"
            save_score $SCORE $ID
            update_status
            sleep 0.5
        else
            LOSE="
You died, sorry!
Your score was $SCORE"
            message "$LOSE"
            break;
        fi
    fi
done
