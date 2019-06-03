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
    local MONSTER_VITALITY=$1
    local TOTAL_MONSTER_VITALITY=$2
    local PLAYER_VITALITY=$3
    local TOTAL_PLAYER_VITALITY=$4
    local MESSAGE=$5
    local PLAYER_BAR=$(vitality_bar $PLAYER_VITALITY $TOTAL_PLAYER_VITALITY)
    local MONSTER_BAR=$(vitality_bar $MONSTER_VITALITY $TOTAL_MONSTER_VITALITY)
    local STATUS="
$MESSAGE

Your vitality:    $PLAYER_BAR$WINDOW_TEXT $PLAYER_VITALITY 

Monster vitality: $MONSTER_BAR$WINDOW_TEXT $MONSTER_VITALITY 
"
    message "$STATUS"
}

function wait_for_ready {
    sleep 0.001
}

function send_fight_status {
    local MONSTER_VITALITY=$1
    local TOTAL_MONSTER_VITALITY=$2
    local PLAYER_VITALITY=$3
    local TOTAL_PLAYER_VITALITY=$4
    local MESSAGE=$5
    local PIPE=$6
    local PLAYER_BAR=$(vitality_bar $PLAYER_VITALITY $TOTAL_PLAYER_VITALITY)
    local MONSTER_BAR=$(vitality_bar $MONSTER_VITALITY $TOTAL_MONSTER_VITALITY)
    echo "${MESSAGE}" >$PIPE
    wait_for_ready
    echo "" >$PIPE
    wait_for_ready
    echo "Your vitality:    $PLAYER_BAR$WINDOW_TEXT $PLAYER_VITALITY" >$PIPE
    wait_for_ready
    echo "Monster vitality: $MONSTER_BAR$WINDOW_TEXT $MONSTER_VITALITY" >$PIPE
    wait_for_ready
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
    status_bar "Level: ${LEVEL} | Score: ${SCORE} | Vitality ${VITALITY} | Agility ${AGILITY} | Dexterity ${DEXTERITY}"
}

function create_db {
    sqlite3 "$DB" <<EOF
         CREATE TABLE battles (
             id INTEGER PRIMARY KEY,
             agressor_id INTEGER NOT NULL,
	     defender_id INTEGER
         );
	 CREATE TABLE characters (
             id INTEGER PRIMARY KEY,
             name VARCHAR(255) UNIQUE NOT NULL,
             level INTEGER NOT NULL,
             score INTEGER NOT NULL,
             vitality INTEGER NOT NULL,
             agility INTEGER NOT NULL,
             dexterity INTEGER NOT NULL
         );
EOF
}

function register_character {
    sqlite3 "$DB" <<EOF
	INSERT INTO characters (name, level, score, vitality, agility, dexterity) VALUES ('${1//\'/\'\'}', $2, $3, $4, $5, $6);
        SELECT last_insert_rowid();
EOF
}

function load_character {
    sqlite3 "$DB" <<EOF
	SELECT * FROM characters WHERE name='${1//\'/\'\'}'
EOF
}

function save_score {
    sqlite3 "$DB" <<EOF
	UPDATE characters SET score=$1 WHERE id = $2
EOF
}

function save_level {
    sqlite3 "$DB" <<EOF
	UPDATE characters SET level=$1 WHERE id = $2
EOF
}

function find_battle_offer {
    sqlite3 "$DB" <<EOF
        SELECT b.id
        FROM battles b
        JOIN characters c ON c.id = b.agressor_id
        WHERE b.defender_id IS NULL AND c.level = $1
EOF
}

function create_battle_offer {
    sqlite3 "$DB" <<EOF
	INSERT INTO battles (agressor_id) VALUES ($1);
        SELECT last_insert_rowid();
EOF
}

function accept_battle_offer {
    sqlite3 "$DB" <<EOF
	UPDATE battles SET defender_id = $2 WHERE id = $1;
EOF
}

function check_battle_offer {
    sqlite3 "$DB" <<EOF
	SELECT * FROM battles WHERE defender_id IS NOT NULL AND id = $1
EOF
}

function pick_a_fight {
    local BATTLE_ID
    local BATTLE
    local ID
    ID=$1
    BATTLE_ID=`find_battle_offer $LEVEL`
    if [ -z $BATTLE_ID ]
    then
        BATTLE_ID=`create_battle_offer $ID`
	while [ -z $BATTLE ]
	do
            sleep 5
            BATTLE=`check_battle_offer $BATTLE_ID`
	done
    else
	mkfifo "/tmp/mzorpg${BATTLE_ID}.battle"
	mkfifo "/tmp/mzorpg${BATTLE_ID}.timing"
        accept_battle_offer $BATTLE_ID $ID
        BATTLE=`check_battle_offer $BATTLE_ID`
    fi
    echo "${BATTLE}"
}

function roll_stats {
    VITALITY=$((25 + RANDOM % 75))
    AGILITY=$((25 + RANDOM % 75))
    DEXTERITY=$((50 + RANDOM % 50))
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
    VITALITY=0
    AGILITY=0
    DEXTERITY=0
    ACCEPTED=0
    while [ "$ACCEPTED" -eq 0 ]
    do
        roll_stats
        STATS="
Welcome, $NAME!

Your statistics:
Vitality: $VITALITY
Agility: $AGILITY
Dexterity: $DEXTERITY
    
Press y to accept, or r to re-roll
"
        message "$STATS"
        read -n 1 -s KEY
        if [[ "$KEY" == "y" ]]
        then
            ACCEPTED=1
        fi

    done

    ID=`register_character "$NAME" 1 0 $VITALITY $AGILITY $DEXTERITY`
else
    IFS='|' read -r -a CHARACTER <<< "$CHARACTER"
    ID=${CHARACTER[0]}
    LEVEL=${CHARACTER[2]}
    SCORE=${CHARACTER[3]}
    VITALITY=${CHARACTER[4]}
    AGILITY=${CHARACTER[5]}
    DEXTERITY=${CHARACTER[6]}
    STATS="
    Welcome back, $NAME!
    ID: $ID
    Your statistics:
    Vitality: $VITALITY
    Agility: $AGILITY
    Dexterity: $DEXTERITY
"
    message "$STATS"
fi


update_status
sleep 1
CURRENT_VITALITY=$VITALITY
while true; do
    if [[ $SCORE > 0 && $((SCORE % 10)) == 0 ]]
    then
        CURRENT_VITALITY=$VITALITY
        message "You drink a potion of healing."
        update_status
        sleep 2
        message "Finding another adventurer to battle..."
        IFS='|' read -r -a BATTLE <<< `pick_a_fight $ID`
        BATTLE_ID=${BATTLE[0]}
        AGRESSOR=${BATTLE[1]}
        DEFENDER=${BATTLE[2]}
        PIPE="/tmp/mzorpg${BATTLE_ID}.battle"
        if [ $AGRESSOR == $ID ]
        then
            # Wait for defender's stats.
            while [ -z $LINE ]
            do
                read LINE <$PIPE
            done
            IFS='|' read -r -a DEFENDER <<< $LINE
            DEFENDER_NAME=${DEFENDER[0]}
            DEFENDER_VITALITY=${DEFENDER[1]}
            DEFENDER_DEXTERITY=${DEFENDER[2]}
            LOCAL_MESSAGE="
You encountered ${DEFENDER_NAME}! Here are their statistics:
Vitality: $DEFENDER_VITALITY
Dexterity: $DEFENDER_DEXTERITY"
            message "$LOCAL_MESSAGE"
            echo "You encountered ${NAME}! Here are their statistics:" >$PIPE
	    wait_for_ready
	    echo "Vitality: $VITALITY" >$PIPE
	    wait_for_ready
            echo "Dexterity: $DEXTERITY" >$PIPE
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
            CURRENT_DEFENDER_VITALITY=$DEFENDER_VITALITY
            while [ $CURRENT_VITALITY -gt 0 ] && [ $CURRENT_DEFENDER_VITALITY -gt 0 ]; do
                if [ $TURN -eq 1 ]; then
                    fight_status $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY $CURRENT_VITALITY $VITALITY "You attack ${DEFENDER_NAME}"
                    send_fight_status $CURRENT_VITALITY $VITALITY $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY "${NAME} attacks you" $PIPE
                    sleep $SPEED
                    HIT=$((RANDOM % 100))
                    if [ $HIT -gt $DEXTERITY ]; then
                        CURRENT_DEFENDER_VITALITY=$((CURRENT_DEFENDER_VITALITY-1))
                        fight_status $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY $CURRENT_VITALITY $VITALITY "You hit them"
                        send_fight_status $CURRENT_VITALITY $VITALITY $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY "They hit you" $PIPE
                    else
                        fight_status $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY $CURRENT_VITALITY $VITALITY "You miss them"
                        send_fight_status $CURRENT_VITALITY $VITALITY $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY "They miss you" $PIPE
                    fi
                    sleep $SPEED
                    TURN=2
                else
                    fight_status $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY $CURRENT_VITALITY $VITALITY "${DEFENDER_NAME} attacks you"
                    send_fight_status $CURRENT_VITALITY $VITALITY $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY "You attack ${NAME}" $PIPE
                    sleep $SPEED
                    HIT=$((RANDOM % 100))
                    if [ $HIT -gt $DEXTERITY ]; then
                        fight_status $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY $CURRENT_VITALITY $VITALITY "They hit you"
                        send_fight_status $CURRENT_VITALITY $VITALITY $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY "You hit them" $PIPE
                        CURRENT_VITALITY=$((CURRENT_VITALITY-1))
                    else
                        fight_status $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY $CURRENT_VITALITY $VITALITY "They miss you"
                        send_fight_status $CURRENT_VITALITY $VITALITY $CURRENT_DEFENDER_VITALITY $DEFENDER_VITALITY "You miss them" $PIPE
                    fi
                    sleep $SPEED
                    TURN=1
                fi
            done;
            if [ $CURRENT_VITALITY -gt 0 ]; then
                LEVEL=$((LEVEL+1))
                WIN="
You won!
Welcome to level ${LEVEL}
You drink a potion of healing"
                message "$WIN"
                echo "LOSE" >$PIPE
                save_level $LEVEL $ID
                CURRENT_VITALITY=$VITALITY
                update_status
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
            # Send stats and wait for futher messages.
            echo "${NAME}|${VITALITY}|${DEXTERITY}" >$PIPE
            while read LINE <$PIPE
            do
                if [[ "$LINE" == "WIN" || "$LINE" == "LOSE" ]] 
                then
                    break
	        elif [ "$LINE" == "$EOM" ]
		then
                    message "${MESSAGE}"
                    MESSAGE=""
                else
                    MESSAGE="${MESSAGE}
${LINE}"
                fi
            done
	    echo "FINAL LINE: $LINE"

            if [ "$LINE" == "WIN" ]
            then
                LEVEL=$((LEVEL+1))
                WIN="
You won!
Welcome to level ${LEVEL}
You drink a potion of healing"
                message "$WIN"
                save_level $LEVEL $ID
                CURRENT_VITALITY=$VITALITY
                update_status
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
        MONSTER_VITALITY=$((5 + RANDOM % 10))
        MONSTER_AGILITY=$((5 + RANDOM % 20))
        MONSTER_DEXTERITY=$((25 + RANDOM % 50))
        sleep 1
        MONSTER="
You found a monster! Here are its statistics:
Vitality: $MONSTER_VITALITY
Agility: $MONSTER_AGILITY
Dexterity: $MONSTER_DEXTERITY"
        message "$MONSTER"
        sleep 1
        message "FIGHT!!"
        sleep 1

        TURN=1
        CURRENT_MONSTER_VITALITY=$MONSTER_VITALITY
        while [ $CURRENT_VITALITY -gt 0 ] && [ $CURRENT_MONSTER_VITALITY -gt 0 ]; do
            if [ $TURN -eq 1 ]; then
                fight_status $CURRENT_MONSTER_VITALITY $MONSTER_VITALITY $CURRENT_VITALITY $VITALITY "You attack the monster"
                sleep $SPEED
                HIT=$((RANDOM % 100))
                if [ $HIT -gt $DEXTERITY ]; then
                    CURRENT_MONSTER_VITALITY=$((CURRENT_MONSTER_VITALITY-1))
                    fight_status $CURRENT_MONSTER_VITALITY $MONSTER_VITALITY $CURRENT_VITALITY $VITALITY "You hit it"
                else
                    fight_status $CURRENT_MONSTER_VITALITY $MONSTER_VITALITY $CURRENT_VITALITY $VITALITY "You miss it"
                fi
                sleep $SPEED
                TURN=2
            else
                fight_status $CURRENT_MONSTER_VITALITY $MONSTER_VITALITY $CURRENT_VITALITY $VITALITY "The monster attacks you"
                sleep $SPEED
                HIT=$((RANDOM % 100))
                if [ $HIT -gt $DEXTERITY ]; then
                    fight_status $CURRENT_MONSTER_VITALITY $MONSTER_VITALITY $CURRENT_VITALITY $VITALITY "It hits you"
                    CURRENT_VITALITY=$((CURRENT_VITALITY-1))
                else
                    fight_status $CURRENT_MONSTER_VITALITY $MONSTER_VITALITY $CURRENT_VITALITY $VITALITY "It misses you"
                fi
                sleep $SPEED
                TURN=1
            fi
        done;

        if [ $CURRENT_VITALITY -gt 0 ]; then
            SCORE=$((SCORE+1))
            WIN="
You won!
Your remaining vitality is $CURRENT_VITALITY out of $VITALITY
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
