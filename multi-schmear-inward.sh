#!/bin/bash
# 
# 


# =====================================================
# PROGRAM PARAMETERS	
# ===================================================== 

# Input
MY_PATH="/c/Users/connb/Desktop/GLITCHIN/SOURCES/"
FILE="PINKIE-SPLOOOOOOOOOOOOOOOOOOOOOOOOOOSION.avi"
IN="${MY_PATH}${FILE}"

# `~D'`~,-.~`'E'`~.-.~`'P'`~.-.~`'T'`~.-.~`'H'`~.-,~`'S'`~`
N=${1:-5}

# Start squares
S_W=1 
S_H=1

# Screen Pixel Resolution
P_W=300 
P_H=300

QUALITY=20

# File information
OUT="${FILE}_grid_$N"
TEMP_OUT=()

LOG="LOG.txt"
if [ -f $LOG ]; then rm $LOG; fi

SEGMENT_FILE="seg.txt"
if [ -f $SEGMENT_FILE ]; then rm $SEGMENT_FILE; fi


# =====================================================
# COMPUTATION START !
# ===================================================== 

# Create REAL source file (SCALE BEFORE THE FUCKY WUCKY)
IN_SRC="${FILE}_${P_W}x${P_H}.avi"
if ! [ -f $IN_SRC ]; then ffmpeg -i $IN -vf scale=$P_W:$P_H -q:v $QUALITY -f avi $IN_SRC; fi


# Get video information
TIME=$(ffprobe $IN_SRC 2>&1| grep -Po "(?<=Duration: )([[:digit:]][[:digit:]]:[[:digit:]][[:digit:]]:[[:digit:]][[:digit:]].[[:digit:]]+)(?=,)")
HOURS=$(($(echo $TIME | cut -c1-2)))
MINS=$(($(echo $TIME | cut -c4-5)))
SECS=$(($(echo $TIME | cut -c7-8)))
FRAC=$(($(echo $TIME | cut -c10-11)))

T=$( echo "($HOURS*60*60)+($MINS*60)+$SECS.$FRAC" | bc )
T_F=$( echo "scale=5;$T/$N" | bc )
T_C=0


# Formats a number to a two-character representation
format_num () {
	local num=$1
	while [[ $( echo "$num" | wc -m ) -lt 3 ]]
	do
		num="0${num}"
	done
	echo "$num"
}

# Turns seconds into hh:mm:ss.ss
format_time () {
	local t=$1
	
	# Parse seconds
	local frac=$( echo $t | grep -Po "\.[[:digit:]]+" )
	if [ $frac ]
	then
		if [[ $( echo "$frac" | wc -m ) == 2 ]]
		then
			frac=".00"
		elif [[ $( echo "$frac" | wc -m ) == 3 ]]
		then
			frac="${frac}0"
		else
			frac=$( echo "$frac" | cut -c1-3 )
		fi
	else
		frac=".00"
	fi

	# Get rid of frac lel
	local nfrac=$(($(echo "scale=0;$t/1" | bc )))

	# Reassemble time using stupid integer math
	local secs=$(format_num $(( $nfrac % 60 )))
	nfrac=$(( $nfrac / 60 ))

	local mins=$(format_num $(( $nfrac % 60 )))

	local hours=$(format_num $(( $nfrac / 60 )))

	# Return!
	echo "$hours:$mins:$secs$frac"
}

W=$S_W
H=$S_H
for i in $(seq 1 $N);
do	
	FILTER=""
	if [[ ( $(($W)) -gt 1 ) || ( $(($H)) -gt 1) ]]
	then
		FILTER="-filter_complex [0:v]"

		F_W=$((P_W/W))
		F_H=$((P_H/H))

		FILTER="${FILTER}scale=${F_W}:${F_H}"
		
		if [[ $W -gt 1 ]]
		then
			FILTER="${FILTER},split=${W},vstack=inputs=${W}"
		fi
		
		if [[ $H -gt 1 ]]
		then
			FILTER="${FILTER},split=${H},hstack=inputs=${H}"
		fi

		FILTER="${FILTER}[out] -map [out] -map 0:a"
	fi

	OUT_C="${OUT}_${i}.avi"
	echo "file '$OUT_C'" >> $SEGMENT_FILE
	TEMP_OUT+=($OUT_C)

	CMD="ffmpeg -ss $(format_time $T_C) -i $IN_SRC -t $(format_time $T_F) $FILTER -c:v mpeg4 -vtag xvid -q:v $QUALITY $TEST -y -f avi $OUT_C"
	echo $CMD >> $LOG
	$($CMD >> $LOG 2>&1)
	echo 

	T_C=$( echo "$T_C+$T_F" | bc )

	W=$((W+1))
	H=$((H+1))
done

ffmpeg -f concat -i $SEGMENT_FILE -c copy -y ${OUT}.avi

for file in "${TEMP_OUT[@]}"; do
	if [ -f $file ]; then rm "$file"; fi
done

ffplay -i ${OUT}.avi -volume 7 -loop 0 
