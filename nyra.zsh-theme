# nyra.zsh-theme
# https://github.com/Nyramu/nyra-zsh
#
# Aesthetic inspired by Jovial (https://github.com/zthxxx/jovial) 
# and Yeknomhtooms/smoothmonkey (https://github.com/sebastianpulido/oh-my-zsh)

autoload -U colors && colors

typeset -gA NYRA_SYMBOL=(
    corner.top    '╭─'
    corner.bottom '╰─'
    arrow '─➤'
    arrow.git-clean '(๑˃̵ᴗ˂̵)و'
    arrow.git-dirty '(ﾉ˚Д˚)ﾉ'
)

autoload -Uz add-zsh-hook
setopt prompt_subst

typeset -g nyra_rev_git_dir=""
typeset -g nyra_exit_code_display=""

@nyra.find-git-dir() {
    local dir="${PWD}"
    while [[ "${dir}" != "/" ]]; do
        if [[ -d "${dir}/.git" ]]; then
            echo "${dir}/.git"
            return 0
        fi
        dir="${dir:h}"
    done
    return 1
}

@nyra.chpwd-hook() {
    nyra_rev_git_dir="$(@nyra.find-git-dir)"
}

add-zsh-hook chpwd @nyra.chpwd-hook
@nyra.chpwd-hook

@nyra.is-git-dirty() {
    [[ -n "$(\git status --porcelain 2>/dev/null)" ]]
}

@nyra.git-branch() {
    if [[ -z ${nyra_rev_git_dir} ]]; then return 1; fi
    
    local ref
    ref="$(\git symbolic-ref --short HEAD 2>/dev/null)" \
      || ref="$(\git describe --tags --exact-match 2>/dev/null)" \
      || ref="$(\git rev-parse --short HEAD 2>/dev/null)" \
      || return 1
    echo "${ref}"
}

@nyra.git-action() {
    if [[ ! -d "${nyra_rev_git_dir}" ]]; then return; fi
    
    local action=""
    
    if [[ -d "${nyra_rev_git_dir}/rebase-merge" ]]; then
        if [[ -f "${nyra_rev_git_dir}/rebase-merge/interactive" ]]; then
            action="REBASE-i"
        else
            action="REBASE-m"
        fi
        
        if [[ -f "${nyra_rev_git_dir}/rebase-merge/msgnum" ]]; then
            local step="$(cat ${nyra_rev_git_dir}/rebase-merge/msgnum)"
            local total="$(cat ${nyra_rev_git_dir}/rebase-merge/end)"
            action="${action} ${step}/${total}"
        fi
    elif [[ -d "${nyra_rev_git_dir}/rebase-apply" ]]; then
        action="REBASE"
        if [[ -f "${nyra_rev_git_dir}/rebase-apply/next" ]]; then
            local step="$(cat ${nyra_rev_git_dir}/rebase-apply/next)"
            local total="$(cat ${nyra_rev_git_dir}/rebase-apply/last)"
            action="${action} ${step}/${total}"
        fi
    elif [[ -f "${nyra_rev_git_dir}/MERGE_HEAD" ]]; then
        action="MERGING"
    elif [[ -f "${nyra_rev_git_dir}/CHERRY_PICK_HEAD" ]]; then
        action="CHERRY-PICKING"
    elif [[ -f "${nyra_rev_git_dir}/REVERT_HEAD" ]]; then
        action="REVERTING"
    elif [[ -f "${nyra_rev_git_dir}/BISECT_LOG" ]]; then
        action="BISECTING"
    fi
    
    if [[ -n "${action}" ]]; then
        echo "|${action}"
    fi
}

@nyra.git-info() {
    if [[ -z ${nyra_rev_git_dir} ]]; then return; fi
    
    local branch="$(@nyra.git-branch)"
    if [[ -z ${branch} ]]; then return; fi
    
    local action="$(@nyra.git-action)"
    
    if @nyra.is-git-dirty; then
        echo " %{$fg[white]%}(%{$fg[cyan]%}${branch}${action}%{$fg[white]%}) %{$fg[yellow]%}✗"
    else
        echo " %{$fg[white]%}(%{$fg[cyan]%}${branch}${action}%{$fg[white]%})"
    fi
}

@nyra.typing-pointer() {
    if [[ -z ${nyra_rev_git_dir} ]]; then
        echo "${NYRA_SYMBOL[arrow]}"
        return
    fi
    
    if @nyra.is-git-dirty; then
        echo "${NYRA_SYMBOL[arrow.git-dirty]}"
    else
        echo "${NYRA_SYMBOL[arrow.git-clean]}"
    fi
}

@nyra.show-exit-code() {
    if [[ "${nyra_exit_code_display}" != "0" ]] && [[ -n "${nyra_exit_code_display}" ]]; then
        echo " %{$fg[white]%}exit:%{$fg[red]%}${nyra_exit_code_display}"
    fi
}

@nyra.precmd() {
    local exit_code=$?
    nyra_exit_code_display="${exit_code}"
}

add-zsh-hook precmd @nyra.precmd

PROMPT='
%{$fg_bold[green]%}${NYRA_SYMBOL[corner.top]}%{$fg[white]%}[ %{$fg_bold[green]%}%~ %{$fg[white]%}]$(@nyra.git-info)$(@nyra.show-exit-code)%{$reset_color%}
%{$fg_bold[green]%}${NYRA_SYMBOL[corner.bottom]}$(@nyra.typing-pointer) %{$reset_color%}'

PS2='%{$fg[red]%}\ %{$reset_color%}'

RPS1=''
