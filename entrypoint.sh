# Default the TZ environment variable to UTC
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $3;exit}')
export INTERNAL_IP

# Default the IMAGE_PROMPT environment variable to something nice
IMAGE_PROMPT=${IMAGE_PROMPT:-$'\033[1m\033[33mcontainer@zenithrp~ \033[0m'}
export IMAGE_PROMPT

cd /home/container || exit 1

if [[ ! -z "${CMD_BEFORE_GAMESERVER}" ]]; then
  eval "$CMD_BEFORE_GAMESERVER"
fi

./srcds_run \
    -console \
    -game garrysmod \
    -port ${GMOD_PORT} \
    -tickrate ${GMOD_TICKRATE} \
    +maxplayers ${GMOD_PLAYERS} \
    +map ${GMOD_MAP} \
    +gamemode ${GMOD_GAMEMODE} \
    +sv_setsteamaccount ${GMOD_KEYS_SERVER_ACCOUNT} \
    +host_workshop_collection ${GMOD_WORKSHOP} \
    +sv_hibernate_think $([[ ${GMOD_HIBERNATE_THINK} == 'true' ]] && printf 1 || printf 0) \
    $([[ ${GMOD_ALLOW_LOCAL_HTTP} == 'true' ]] && printf %s '-allowlocalhttp') \
    -strictportbind \
    -norestart \
    -debug \
    -p2p

