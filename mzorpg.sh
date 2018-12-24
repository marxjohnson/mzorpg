#!/bin/bash

SPEED=0.2

function message {
    dialog --colors --no-collapse --infobox "$1" 30 60
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

Your vitality:    $PLAYER_BAR $PLAYER_VITALITY

Monster vitality: $MONSTER_BAR $MONSTER_VITALITY
"
    message "$STATUS"

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
    BAR="\Zb\Z2"

    for i in `seq 1 $FULL`
    do
        BAR=$BAR"█"
    done

    BAR=$BAR"\ZB"

    if [ $PARTIAL -eq 2 ]
    then
        BAR=$BAR"█"
    elif [ $PARTIAL -eq 1 ]
    then
        BAR=$BAR"\Z1█"
    elif [ $FULL -lt $LENGTH ]
    then
        EMPTY=$((EMPTY+1))
    fi

    if [ $EMPTY -gt 0 ]
    then
        BAR=$BAR"\Zb\Z1"
        for i in `seq 1 $EMPTY`
        do
            BAR=$BAR"█"
        done
    fi
    BAR=$BAR"\Zn"

    echo $BAR
}

VITALITY=$((25 + RANDOM % 75))
AGILITY=$((25 + RANDOM % 75))
DEXTERITY=$((50 + RANDOM % 50))
SCORE=0

STATS="
Your statistics:
Vitality: $VITALITY
Agility: $AGILITY
Dexterity: $DEXTERITY
"

dialog --msgbox "$STATS" 30 60
sleep 1
CURRENT_VITALITY=$VITALITY
while true; do
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
	sleep 0.5
    else
	LOSE="
You died, sorry!
Your score was $SCORE"
	message "$LOSE"
	break;
    fi
done

