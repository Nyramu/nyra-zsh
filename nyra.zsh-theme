# nyra.zsh-theme
# https://github.com/Nyramu/nyra-zsh
#
# Aesthetic inspired by Jovial (https://github.com/zthxxx/jovial) 
# and Yeknomhtooms/smoothmonkey (https://github.com/sebastianpulido/oh-my-zsh)

autoload -U colors && colors

typeset -gA NYRA_SYMBOL=(
    corner.top      '╭─'
    corner.bottom   '╰─'
    arrow           '─➤'
    arrow.git-clean '(๑˃̵ᴗ˂̵)و'
    arrow.git-dirty '(ﾉ˚Д˚)ﾉ'
)

autoload -Uz add-zsh-hook
setopt prompt_subst

typeset -g nyra_rev_git_dir=""
typeset -g nyra_exit_code_display=""

@nyra.find-git-dir() {
    local current_dir="${PWD}"
    local root_dir="/"
    
    while [[ "${current_dir}" != "${root_dir}" ]]; do
        local git_dir="${current_dir}/.git"
        
        if [[ -d "${git_dir}" ]]; then
            echo "${git_dir}"
            return 0
        fi
        
        current_dir="${current_dir:h}"
    done
    
    return 1
}

@nyra.chpwd-hook() {
    nyra_rev_git_dir="$(@nyra.find-git-dir)"
}

add-zsh-hook chpwd @nyra.chpwd-hook
@nyra.chpwd-hook

@nyra.is-git-dirty() {
    local git_status="$(\git status --porcelain 2>/dev/null)"
    [[ -n "${git_status}" ]]
}

@nyra.git-branch() {
    if [[ -z ${nyra_rev_git_dir} ]]; then 
        return 1
    fi
    
    local branch_ref
    branch_ref="$(\git symbolic-ref --short HEAD 2>/dev/null)" \
      || branch_ref="$(\git describe --tags --exact-match 2>/dev/null)" \
      || branch_ref="$(\git rev-parse --short HEAD 2>/dev/null)" \
      || return 1
    
    echo "${branch_ref}"
}

@nyra.git-action() {
    if [[ ! -d "${nyra_rev_git_dir}" ]]; then 
        return
    fi
    
    local rebase_merge_dir="${nyra_rev_git_dir}/rebase-merge"
    local rebase_apply_dir="${nyra_rev_git_dir}/rebase-apply"
    local action=""
    
    if [[ -d "${rebase_merge_dir}" ]]; then
        if [[ -f "${rebase_merge_dir}/interactive" ]]; then
            action="REBASE-i"
        else
            action="REBASE-m"
        fi
        
        local msgnum_file="${rebase_merge_dir}/msgnum"
        local end_file="${rebase_merge_dir}/end"
        
        if [[ -f "${msgnum_file}" ]]; then
            local current_step="$(cat ${msgnum_file})"
            local total_steps="$(cat ${end_file})"
            action="${action} ${current_step}/${total_steps}"
        fi
        
    elif [[ -d "${rebase_apply_dir}" ]]; then
        action="REBASE"
        
        local next_file="${rebase_apply_dir}/next"
        local last_file="${rebase_apply_dir}/last"
        
        if [[ -f "${next_file}" ]]; then
            local current_step="$(cat ${next_file})"
            local total_steps="$(cat ${last_file})"
            action="${action} ${current_step}/${total_steps}"
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
    if [[ -z ${nyra_rev_git_dir} ]]; then 
        return
    fi
    
    local branch="$(@nyra.git-branch)"
    if [[ -z ${branch} ]]; then 
        return
    fi
    
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
    local exit_code="${nyra_exit_code_display}"
    local success_code="0"
    
    if [[ "${exit_code}" != "${success_code}" ]] && [[ -n "${exit_code}" ]]; then
        echo " %{$fg[white]%}exit:%{$fg[red]%}${exit_code}"
    fi
}

@nyra.precmd() {
    nyra_exit_code_display=$?
}

add-zsh-hook precmd @nyra.precmd

PROMPT='
%{$fg_bold[green]%}${NYRA_SYMBOL[corner.top]}%{$fg[white]%}[ %{$fg_bold[green]%}%~ %{$fg[white]%}]$(@nyra.git-info)$(@nyra.show-exit-code)%{$reset_color%}
%{$fg_bold[green]%}${NYRA_SYMBOL[corner.bottom]}$(@nyra.typing-pointer) %{$reset_color%}'

PS2='%{$fg[red]%}\ %{$reset_color%}'
RPS1=''
