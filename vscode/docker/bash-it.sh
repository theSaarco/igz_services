prompt_command () {
    if [ $? -eq 0 ]; then # set an error string for the prompt, if applicable
        ERRPROMPT=" "
    else
        ERRPROMPT='->($?) '
    fi
    local TIME="\t"
    local GREEN="\[\033[0;32m\]"
    local CYAN="\[\033[0;36m\]"
    local BCYAN="\[\033[1;36m\]"
    local BLUE="\[\033[0;34m\]"
    local GRAY="\[\033[0;37m\]"
    local DKGRAY="\[\033[1;30m\]"
    local WHITE="\[\033[1;37m\]"
    local RED="\[\033[0;31m\]"
    # return color to Terminal setting for text color
    local DEFAULT="\[\033[0;39m\]"
    # set the titlebar to the last 2 fields of pwd
    local TITLEBAR='\[\e]2;`pwdtail`\a'
    local USERTAG="${V3IO_USERNAME}"
    if [ "${V3IO_USERNAME}" == "" ]; then
        USERTAG="\u"
    fi
    export PS1="\[${TITLEBAR}\]${CYAN}[${BLUE} \
${USERTAG}${CYAN} @ ${DKGRAY}\h ${WHITE}${TIME} ${CYAN}]${RED}$ERRPROMPT${GRAY}\
\W ${GREEN}${DEFAULT}$ "
}
PROMPT_COMMAND=prompt_command

pwdtail () { #returns the last 2 fields of the working directory
    pwd|awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}
