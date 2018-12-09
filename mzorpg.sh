#!/bin/bash

VITALITY=$((25 + $RANDOM % 75))
AGILITY=$((25 + $RANDOM % 75))
DEXTERITY=$((50 + $RANDOM % 50))
SCORE=0

echo "Your statistics:"
echo "Vitality: $VITALITY"
echo "Agility: $AGILITY"
echo "Dexterity: $DEXTERITY"
echo ""
sleep 1
while true; do
    echo "Finding a monster..."
    MONSTER_VITALITY=$((5 + $RANDOM % 10))
    MONSTER_AGILITY=$((5 + $RANDOM % 20))
    MONSTER_DEXTERITY=$((25 + $RANDOM % 50))
    sleep 1
    echo "You found a monster! Here are its statistics:"
    echo "Vitality: $MONSTER_VITALITY"
    echo "Agility: $MONSTER_AGILITY"
    echo "Dexterity: $MONSTER_DEXTERITY"
    echo ""
    echo "FIGHT!"

    TURN=1
    while [ $VITALITY -gt 0 ] && [ $MONSTER_VITALITY -gt 0 ]; do
	if [ $TURN -eq 1 ]; then
	    echo "You attack the monster"
	    HIT=$(($RANDOM % 100))
	    if [ $HIT -gt $DEXTERITY ]; then
		echo "You hit it"
		MONSTER_VITALITY=$((MONSTER_VITALITY-1))
	    else
		echo "You miss it"
	    fi
	    echo "Monster's vitality: $MONSTER_VITALITY"
	    TURN=2
	else
	    echo "The monster attacks you"
	    HIT=$(($RANDOM % 100))
	    if [ $HIT -gt $DEXTERITY ]; then
		echo "It hits you"
		VITALITY=$((VITALITY-1))
	    else
		echo "It misses you"
	    fi
	    echo "Your vitality: $VITALITY"

	    TURN=1
	fi
    done;

    if [ $VITALITY -gt 0 ]; then
	echo "You won!"
	SCORE=$((SCORE+1))
	echo "Your remaining vitality is $VITALITY"
	echo "You current score is $SCORE"
	sleep 0.5
    else
	echo "You died, sorry!"
	echo "Your score was $SCORE"
	break;
    fi
done

