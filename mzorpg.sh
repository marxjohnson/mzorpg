#!/bin/bash

function message {
    dialog --infobox "$1" 30 60
}

function fight_status {
    MONSTER_VITALITY=$1
    PLAYER_VITALITY=$2
    MESSAGE=$3
    STATUS="
$MESSAGE

Your vitality: $PLAYER_VITALITY
Monster vitality: $MONSTER_VITALITY
"
    message "$STATUS"

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
    while [ $VITALITY -gt 0 ] && [ $MONSTER_VITALITY -gt 0 ]; do
	if [ $TURN -eq 1 ]; then
	    fight_status $MONSTER_VITALITY $VITALITY "You attack the monster"
	    sleep 0.2
	    HIT=$((RANDOM % 100))
	    if [ $HIT -gt $DEXTERITY ]; then
		MONSTER_VITALITY=$((MONSTER_VITALITY-1))
		fight_status $MONSTER_VITALITY $VITALITY "You hit it"
	    else
		fight_status $MONSTER_VITALITY $VITALITY "You miss it"
	    fi
	    sleep 0.2
	    TURN=2
	else
	    fight_status $MONSTER_VITALITY $VITALITY "The monster attacks you"
	    sleep 0.2
	    HIT=$((RANDOM % 100))
	    if [ $HIT -gt $DEXTERITY ]; then
		fight_status $MONSTER_VITALITY $VITALITY "It hits you"
		VITALITY=$((VITALITY-1))
	    else
		fight_status $MONSTER_VITALITY $VITALITY "It misses you"
	    fi
	    sleep 0.2
	    TURN=1
	fi
    done;

    if [ $VITALITY -gt 0 ]; then
	SCORE=$((SCORE+1))
	WIN="
You won!
Your remaining vitality is $VITALITY
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

