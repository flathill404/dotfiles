# shellcheck shell=bash

# Add an "alert" alias for long running commands.
# Use like so: `sleep 10; alert`
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# ls aliases
alias sl=ls
alias la='ls -AF' # Compact view, show hidden
alias ll='ls -Al'
alias l='ls -A'
alias l1='ls -1'
alias lf='ls -F'

# python tools aliases
if type "pygmentize" > /dev/null 2>&1; then
    alias ccat='pygmentize -g'
fi

# apt aliases
if type "apt" > /dev/null 2>&1; then
    alias aptsync='sudo apt update && sudo apt upgrade -y'
fi

# xmodmap aliases
if type "xmodmap" > /dev/null 2>&1; then
    alias xmm='xmodmap ~/.Xmodmap'
fi

# docker aliases
alias dk='docker'
alias dklc='docker ps -l'                                                            # List last Docker container
alias dklcid='docker ps -l -q'                                                       # List last Docker container ID
alias dklcip='docker inspect -f "{{.NetworkSettings.IPAddress}}" $(docker ps -l -q)' # Get IP of last Docker container
alias dkps='docker ps'                                                               # List running Docker containers
alias dkpsa='docker ps -a'                                                           # List all Docker containers
alias dki='docker images'                                                            # List Docker images
alias dkrmac='docker rm $(docker ps -a -q)'                                          # Delete all Docker containers

case $OSTYPE in
	darwin* | *bsd* | *BSD*)
		alias dkrmui='docker images -q -f dangling=true | xargs docker rmi' # Delete all untagged Docker images
		;;
	*)
		alias dkrmui='docker images -q -f dangling=true | xargs -r docker rmi' # Delete all untagged Docker images
		;;
esac

# Function aliases from docker plugin:
alias dkrmlc='docker-remove-most-recent-container' # Delete most recent (i.e., last) Docker container
alias dkrmall='docker-remove-stale-assets'         # Delete all untagged images and exited containers
alias dkrmli='docker-remove-most-recent-image'     # Delete most recent (i.e., last) Docker image
alias dkrmi='docker-remove-images'                 # Delete images for supplied IDs or all if no IDs are passed as arguments
alias dkideps='docker-image-dependencies'          # Output a graph of image dependencies using Graphiz
alias dkre='docker-runtime-environment'            # List environmental variables of the supplied image ID

alias dkelc='docker exec -it $(dklcid) bash --login' # Enter last container (works with Docker 1.3 and above)
alias dkrmflast='docker rm -f $(dklcid)'
alias dkbash='dkelc'
alias dkex='docker exec -it ' # Useful to run any commands into container without leaving host
alias dkri='docker run --rm -i '
alias dkric='docker run --rm -i -v $PWD:/cwd -w /cwd '
alias dkrit='docker run --rm -it '
alias dkritc='docker run --rm -it -v $PWD:/cwd -w /cwd '

# Added more recent cleanup options from newer docker versions
alias dkip='docker image prune -a -f'
alias dkvp='docker volume prune -f'
alias dksp='docker system prune -a -f'

# docker compose aliases
alias dco="docker compose"

# Defined in the `docker-compose` plugin, please check there for details.
alias dcofresh="docker-compose-fresh"
alias dcol="docker compose logs -f --tail 100"
alias dcou="docker compose up"
alias dcouns="dcou --no-start"
