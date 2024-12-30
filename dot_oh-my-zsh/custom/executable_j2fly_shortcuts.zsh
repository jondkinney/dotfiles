# DB Stuff
# --------
# PG
alias pgstart='pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start'
alias pgtail='tail -f /usr/local/var/postgres/server.log'
alias pgstop='pg_ctl -D /usr/local/var/postgres stop -s -m fast'
# MySQL
alias mysqlstart='mysql.server start'
alias mysqlstop='mysql.server stop'
# Both
alias startdbs='pgstart;mysqlstart'
alias stopdbs='pgstop;mysqlstop'
alias restartdbs='stopdbs;startdbs'
alias redis='redis-server /usr/local/etc/redis.conf'

# System Level
# ------------
alias uldb='sudo /usr/libexec/locate.updatedb' #update the location database
alias flush_dns='sudo killall -HUP mDNSResponder'
alias c='clear'
alias clera='clear'
alias rm_sym='find . ! -name . -prune -type l | xargs rm'
# Kill pid of a port
kill_port() {
  if [ $# -eq 0 ]; then
    echo "Usage: kill_port <port> [node=true]"
  else
    local port=$1
    local node_only=$2

    if [[ "$node_only" == "node=true" ]]; then
      local pids=$(sudo lsof -t -i:$port -sTCP:LISTEN | xargs ps -p | grep node | awk '{print $1}')
      if [ -z "$pids" ]; then
        echo "No Node.js process found running on port $port"
      else
        for pid in $pids; do
          echo "Killing Node.js process $pid running on port $port"
          sudo kill -9 $pid
          echo "Node.js process $pid has been killed"
        done
      fi
    else
      local pid=$(sudo lsof -t -i:$port)
      if [ -z "$pid" ]; then
        echo "No process found running on port $port"
      else
        echo "Killing process $pid running on port $port"
        sudo kill -9 $pid
        echo "Process $pid has been killed"
      fi
    fi
  fi
}

# Git
# -----------------
alias gmnff='git merge --no-edit --no-ff $*'
alias mmts='git checkout staging; git merge --no-edit --no-ff main; git push; git push --tags'
alias mmtp='git checkout production; git merge --no-edit --no-ff main; git push; git push --tags'
alias mmte='mmts;mmtp'
alias gbc='git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d "\n" | pbcopy' # copies the current branch to your clipboard (on os x)
alias dev='git checkout development'
alias sta='git checkout staging'
alias prd='git checkout production'
alias main='git checkout main'
alias gauthor='f() { GIT_COMMITTER_DATE=$1 git commit --amend --date=$1 }; f' # Wed Mar 14 14:08 2018 -0600
alias pr_show='hub pr show'
alias pr_create='hub pull-request -b main'

gitPruneRemoteAndLocal () {
   git fetch -p && git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d
}

alias gprl='gitPruneRemoteAndLocal'

function git-change-author() {
  local NEW_NAME="Jon Kinney"
  local NEW_EMAIL="jon@headway.io"

  # Nord color scheme ANSI codes with exact hex values
  local RESET="\033[0m"
  local NORD_RED="\033[38;2;191;97;106m"    # Red for commit hashes (#BF616A)
  local NORD_WHITE="\033[38;2;216;222;233m" # White for commit messages (#D8DEE9)
  local NORD_BLUE="\033[38;2;129;161;193m"  # Blue for dates (#81A1C1)
  local NORD_GREEN="\033[38;2;163;190;140m" # Green for author names (#A3BE8C)
  local NORD_CYAN="\033[38;2;136;192;208m"  # Cyan for branch point prefix (#88C0D0)
  local NORD_YELLOW="\033[38;2;235;203;139m" # Yellow for new author info (#EBCB8B)

  # Determine the base branch (usually main or master or dev)
  local BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

  # Find the branching point
  local BRANCH_POINT=$(git merge-base HEAD origin/$BASE_BRANCH)

  if [[ -z "$BRANCH_POINT" ]]; then
    echo "Error: Could not determine the branch point."
    return 1
  fi

  # Get the short hash, author, date, and commit message of the branch point
  local BRANCH_POINT_INFO=$(git log -1 --pretty=format:"%h%x00%an%x00%ad%x00%s" --date=format:"%Y-%m-%d %I:%M:%S%p" $BRANCH_POINT | sed 's/AM/am/g; s/PM/pm/g')

  echo -e "This will change the author for all commits in the current branch that are not in ${NORD_CYAN}$BASE_BRANCH${RESET} to:"
  echo -e "${NORD_YELLOW}$NEW_NAME <$NEW_EMAIL>${RESET}"
  echo ""
  echo "The last commit that will NOT be changed is:"

  # Find the longest author name for padding (including the branch point commit)
  local MAX_AUTHOR_LENGTH=$(git log ${BRANCH_POINT}..HEAD --format="%an" | awk '{ print length }' | sort -rn | head -n1)
  MAX_AUTHOR_LENGTH=$((MAX_AUTHOR_LENGTH > ${#NEW_NAME} ? MAX_AUTHOR_LENGTH : ${#NEW_NAME}))

  # Display the branch point commit with author
  IFS=$'\0' read -r bp_hash bp_author bp_date bp_subject <<< "$BRANCH_POINT_INFO"
  printf "${NORD_RED}%s ${NORD_GREEN}%-${MAX_AUTHOR_LENGTH}s ${NORD_BLUE}(%s) ${NORD_CYAN}%s ${NORD_WHITE}%s${RESET}\n" "$bp_hash" "$bp_author" "$bp_date" "[$BASE_BRANCH]" "$bp_subject"

  echo ""
  echo "Commits to be changed:"

  # Display commits with Nord color scheme and right-padded author names
  git log --reverse ${BRANCH_POINT}..HEAD --pretty=format:"%h%x00%an%x00%ad%x00%s%n" --date=format:"%Y-%m-%d %I:%M:%S%p" | 
  sed 's/AM/am/g; s/PM/pm/g' |
  while IFS=$'\0' read -r commit_hash author date commit_subject; do
    # Ensure all fields are correctly parsed
    if [[ -n "$commit_hash" && -n "$author" && -n "$date" && -n "$commit_subject" ]]; then
      printf "${NORD_RED}%s ${NORD_GREEN}%-${MAX_AUTHOR_LENGTH}s ${NORD_BLUE}(%s) ${NORD_WHITE}%s${RESET}\n" "$commit_hash" "$author" "$date" "$commit_subject"
    fi
  done

  echo ""
  echo "Proceed? [Y/n]"
  read -r response

  # Convert response to lowercase
  response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

  # If response is empty or starts with 'y', proceed
  if [[ -z "$response" || "$response" =~ ^y ]]; then
    # Squelch the filter-branch warning
    (export FILTER_BRANCH_SQUELCH_WARNING=1; git filter-branch --force --env-filter '
    if [ "$GIT_COMMIT" != "'"$BRANCH_POINT"'" ]; then
      export GIT_COMMITTER_NAME="'"$NEW_NAME"'"
      export GIT_COMMITTER_EMAIL="'"$NEW_EMAIL"'"
      export GIT_AUTHOR_NAME="'"$NEW_NAME"'"
      export GIT_AUTHOR_EMAIL="'"$NEW_EMAIL"'"
    fi
    ' ${BRANCH_POINT}..HEAD)

    # Check if git filter-branch was successful
    if [[ $? -eq 0 ]]; then
      echo "Author information updated for new commits in the current branch."
      echo "Please review the changes and force push if necessary."
    else
      echo "Error: git filter-branch did not complete successfully."
      echo "Please check the output for details and resolve any issues before retrying."
    fi
  else
    echo "Operation cancelled."
  fi
}

alias gchange_author='git-change-author'



# Nocorrect Aliases
# -----------------
unsetopt correct_all

# Apps
# ----
alias tl='tmux ls'
alias ta='tmux attach -t $*'
alias tk='tmux kill-session -t $*'
alias tks='tmux kill-server'
alias to='tmuxinator open $*'
alias ts='tmuxinator start $@'
alias ml='tmuxinator list'

# Wemux
# -----
alias wl='wemux list'
alias wj='wemux join $*'
alias wr='wemux rogue $*'
alias wp='wemux pair $*'
alias wsj='f() { wemux join $1; wemux start }; f'
alias wk='wemux stop $*'
alias wks='wemux stop'


# Project Shortcuts
# -----------------
alias hack='tmuxinator start hack; set_tab_and_title_name Hack'
alias coachesEDG='cd ~/Code/coachesedg/coachesedg-web; set_tab_and_title_name CoachesEDG Web'
alias festival='cd ~/Code/festival; set_tab_and_title_name Festival'
alias weedwire='cd ~/Code/weedwire; set_tab_and_title_name Weedwire'
alias ia='cd ~/Code/ia-workspaces/; set_tab_and_title_name Inductive Automation; tmuxinator start ia'


# VIM
# ---
alias vim='nvim'
alias vce='set_tab_and_title_name Nvim Setup; cd ~/.config/nvim; nvim .'
alias vim_huge='nvim -u NONE -U NONE -N $*'


# RAILS
# -----
# you need to use bundle exec before each command you run in a app controlled by
# bundler so this alias helps make that easier
alias be='bundle exec $*'
alias rdm='bin/rails db:migrate'
alias rc='bin/rails console'
alias rdbc='bin/rails dbconsole'
alias kr='kill -9 `cat tmp/pids/server.pid; echo;`'

# IA Kill Ports
alias kia='kill_port 9088; kill_port 9089; kill_port 6006 node=true'

alias webserver='python -m SimpleHTTPServer'

# $1 = type; 0 - both, 1 - tab, 2 - title
# rest = text
function setTerminalText () {
    local mode=$1 ; shift
    local text="$@"

    if [[ "$TERM" == "xterm-kitty" ]]; then
        # Kitty
        case $mode in
            0) # Both tab and window title
                kitty @ set-tab-title "$text"
                kitty @ set-window-title "$text"
                ;;
            1) # Tab title only
                kitty @ set-tab-title "$text"
                ;;
            2) # Window title only
                kitty @ set-window-title "$text"
                ;;
        esac
    else
        # iTerm2 and other terminals
        case $mode in
            0) # Both tab and window title
                echo -ne "\033]0;$text\007"
                ;;
            1) # Tab title only
                echo -ne "\033]1;$text\007"
                ;;
            2) # Window title only
                echo -ne "\033]2;$text\007"
                ;;
        esac
    fi
}

set_tab_name() { setTerminalText 1 "$@"; }
set_title_name() { setTerminalText 2 "$@"; }
set_tab_and_title_name() { setTerminalText 0 "$@"; }

# Set Window Title initially, then setting tab titles won't override it
# set_tab_and_title_name Let\'s Make Headway

#Set new tab titles to the machine's name
case `uname` in
  Darwin)
  set_tab_and_title_name `hostname | cut -d'.' -f 1`
  ;;
esac

# Yazi - this function will change the directory to the one specified in the
# yazi file so that when you close the terminal you will be in the correct
# directory
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Edit this file
alias ea='chezmoi edit ~/.oh-my-zsh/custom/j2fly_shortcuts.zsh'
alias ez='chezmoi edit ~/.zshrc'
alias eg='chezmoi edit ~/.gitconfig'
alias ek='nvim ~/.config/kitty/kitty.conf'

#Source this file
alias ea_source='chezmoi apply; source $HOME/.oh-my-zsh/custom/j2fly_shortcuts.zsh'
alias ez_source='chezmoi apply; source $HOME/.zshrc'
alias eg_source='chezmoi apply; source $HOME/.gitconfig'
