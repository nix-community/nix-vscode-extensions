ACTION_ID=${ACTION_ID:-1}
TARGET=${TARGET:-vscode-marketplace}

let "PREV_ID = $ACTION_ID - 1"
PREV_GENERATED_ID=$([[ $ACTION_ID = 1 ]] && echo 1 || echo $PREV_ID)

PREV_GENERATED="blocks/generated/$TARGET/generated-$PREV_GENERATED_ID.json"

WAIT_SECONDS=3

git pull

while [[ ! -f $PREV_GENERATED ]]
do
    echo "waiting $WAIT_SECONDS seconds" && sleep $WAIT_SECONDS
    git pull
done

echo "ready to push"