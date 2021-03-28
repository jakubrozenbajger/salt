# vim:ft=zsh ts=2 sw=2 sts=2
#
# prompt settings
PROMPT_DATE=${SALT_PROMPT_DATE:-false}
PROMPT_TIME=${SALT_PROMPT_TIME:-true}
PROMPT_VI=${SALT_PROMPT_VI:-true}
PROMPT_VENV=${SALT_PROMPT_VENV:-true}
PROMPT_GIT=${SALT_PROMPT_GIT:-true}
PROMPT_USER=${SALT_PROMPT_USER:-true}

SEGMENT_SEPARATOR="${SALT_SEGMENT_SEPARATOR:-}"
ENDL_SEPARATOR="${SALT_ENDL_SEPARATOR:-}"


#disable default venv prompt
"$PROMPT_VENV" && export VIRTUAL_ENV_DISABLE_PROMPT=true

# Vi mode indicators
VICMD_INDICATOR="NORMAL"
VIINS_INDICATOR="INSERT"
#VICMD_INDICATOR="N"
#VIINS_INDICATOR="I"

# Status symbols
SYMBOL_CMD=" $ "
SYMBOL_CMD_SU="%{%F{red}%} # %{%f%}"
SYMBOL_ERR="\u2718"
SYMBOL_ROOT="\u26a1"
SYMBOL_JOB="\u2699"

# Git symbols
PLUSMINUS="\u00b1"
BRANCH="\uf126"

# Vi mode
prompt_vi_mode() {
  local mode
  is_normal() {
    test -n "${${KEYMAP/vicmd/$VICMD_INDICATOR}/(main|viins)/}"  # param expans
  }
  if is_normal; then
    print -n "%S%B $VICMD_INDICATOR %b%s"
  else
    print -n "%B $VIINS_INDICATOR %b"
  fi
}

prompt_end() {
  print -n "%{%k%}"
  print -n "%{%f%}"
}

### Prompt components
# who am I and where am I - if root red{user@host} else on remote magenta{user@host}, on local - {user}
prompt_context() {
  local ctx
  if [ -n "$SSH_CLIENT" ]; then
    ctx="%{%F{magenta}%} %n@%m %{%f%}"
  else
    $PROMPT_USER && ctx=" %n "
  fi
  print -n "%(!.%{%F{white}%K{red}%} %n@%m %{%k%}%{%f%}.${ctx:-})"
}

prompt_git() {
  # if not inside git repo do nothing
  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
    return;
  fi

  local ref dirty mode repo_path clean has_upstream
  local modified untracked added deleted tagged stashed
  local ready_commit git_status
  local commits_diff commits_ahead commits_behind has_diverged to_push to_pull
  local g_prompt_color

  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  dirty=$(git status --porcelain --ignore-submodules="${GIT_STATUS_IGNORE_SUBMODULES:-dirty}" 2> /dev/null | tail -n1)
  git_status=$(git status --porcelain 2> /dev/null)
  ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
  if [[ -n $dirty ]]; then
    clean=''
    g_prompt_color='yellow'
  else
    clean=' ✔'
    g_prompt_color='green'
  fi

  local upstream; upstream=$(git rev-parse --symbolic-full-name --abbrev-ref "@{upstream}" 2> /dev/null)
  if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then has_upstream=true; fi

  local current_commit_hash; current_commit_hash=$(git rev-parse HEAD 2> /dev/null)

  local number_of_untracked_files; number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
  # if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files◆"; fi
  if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files☀"; fi

  local number_added; number_added=$(\grep -c "^A" <<< "${git_status}")
  if [[ $number_added -gt 0 ]]; then added=" $number_added✚"; fi

  local number_modified; number_modified=$(\grep -c "^.M" <<< "${git_status}")
  if [[ $number_modified -gt 0 ]]; then
    modified=" $number_modified●"
    g_prompt_color='red'
  fi

  local number_added_modified; number_added_modified=$(\grep -c "^M" <<< "${git_status}")
  local number_added_renamed; number_added_renamed=$(\grep -c "^R" <<< "${git_status}")
  if [[ $number_modified -gt 0 && $number_added_modified -gt 0 ]]; then
    modified="$modified$((number_added_modified+number_added_renamed))$PLUSMINUS"
  elif [[ $number_added_modified -gt 0 ]]; then
    modified=" ●$((number_added_modified+number_added_renamed))$PLUSMINUS"
  fi

  local number_deleted; number_deleted=$(\grep -c "^.D" <<< "${git_status}")
  if [[ $number_deleted -gt 0 ]]; then
    deleted=" $number_deleted‒"
    g_prompt_color='red'
  fi

  local number_added_deleted; number_added_deleted=$(\grep -c "^D" <<< "${git_status}")
  if [[ $number_deleted -gt 0 && $number_added_deleted -gt 0 ]]; then
    deleted="$deleted$number_added_deleted$PLUSMINUS"
  elif [[ $number_added_deleted -gt 0 ]]; then
    deleted=" ‒$number_added_deleted$PLUSMINUS"
  fi

  local tag_at_current_commit; tag_at_current_commit=$(git describe --exact-match --tags "$current_commit_hash" 2> /dev/null)
  if [[ -n $tag_at_current_commit ]]; then tagged=" ☗$tag_at_current_commit "; fi

  local number_of_stashes; number_of_stashes="$(git stash list 2> /dev/null | wc -l)"
  if [[ $number_of_stashes -gt 0 ]]; then
    stashed=" ${number_of_stashes##*(  )}⚙"
  fi

  if [[ $number_added -gt 0 || $number_added_modified -gt 0 || $number_added_deleted -gt 0 ]]; then ready_commit=' ⚑'; fi

  local upstream_prompt=''
  if [[ $has_upstream == true ]]; then
    commits_diff="$(git log --pretty=oneline --topo-order --left-right "${current_commit_hash}...${upstream}" 2> /dev/null)"
    commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
    commits_behind=$(\grep -c "^>" <<< "$commits_diff")
    upstream_prompt="$(git rev-parse --symbolic-full-name --abbrev-ref "@{upstream}" 2> /dev/null)"
    upstream_prompt=$(sed -e 's/\/.*$/ ☊ /g' <<< "$upstream_prompt")
  fi

  has_diverged=false
  if [[ $commits_ahead -gt 0 && $commits_behind -gt 0 ]]; then has_diverged=true; fi
  if [[ $has_diverged == false && $commits_ahead -gt 0 ]]; then to_push=" ↑$commits_ahead"; fi
  if [[ $has_diverged == false && $commits_behind -gt 0 ]]; then to_pull=" %f%F{yellow} ↓$commits_behind %f%F{$g_prompt_color}"; fi

  if [[ -e "${repo_path}/BISECT_LOG" ]]; then
    mode=" <B>"
  elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
    mode=" >M<"
  elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
    mode=" >R>"
  fi

  g_prompt_txt="${ref/refs\/heads\//$BRANCH $upstream_prompt}${mode}$to_push$to_pull$clean$tagged$stashed$untracked$modified$deleted$added$ready_commit"
  print -n "%F{$g_prompt_color} $g_prompt_txt %f"
}

prompt_dir() {
  print -n " %~ "
}

prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path ]]; then
    print -n "%{%F{blue}%}  $(basename "$virtualenv_path") %{%f%}"
  fi
}

prompt_date() {
  print -n " %D{%Y-%m-%d} "
}

prompt_time() {
  print -n " %D{%H:%M} "
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=""
  [[ $RETVAL -ne 0 ]] && symbols="${symbols:+$symbols }%{%F{red}%}$SYMBOL_ERR $RETVAL%f"
  [[ $UID -eq 0 ]] && symbols="${symbols:+$symbols }%{%F{yellow}%}$SYMBOL_ROOT%f"
  local jobs_no; jobs_no=$(jobs -l | wc -l)
  [[ "$jobs_no" -gt 0 ]] && symbols="${symbols:+$symbols }%{%F{cyan}%}$SYMBOL_JOB $jobs_no%f"

  [[ -n "$symbols" ]] && print -n " $symbols "
}

prompt_cmd() {
  print -n "%(!.$SYMBOL_CMD_SU.$SYMBOL_CMD)"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  print -n "\n"
  prompt_status
  prompt_context
  prompt_dir
  "$PROMPT_VENV" && prompt_virtualenv
  "$PROMPT_GIT" && prompt_git
  prompt_end
  print -n "\n"
  prompt_cmd
  prompt_end
}

build_rprompt() {
  "$PROMPT_VI" && prompt_vi_mode
  "$PROMPT_DATE" && prompt_date
  "$PROMPT_TIME" && prompt_time
  prompt_end
}

# shellcheck disable=SC2016,SC2034
PROMPT='%{%f%b%k%}%B$(build_prompt)%b'
RPROMPT='%{%f%b%k%}%B$(build_rprompt)%b'
# shellcheck disable=SC2016,SC2034

