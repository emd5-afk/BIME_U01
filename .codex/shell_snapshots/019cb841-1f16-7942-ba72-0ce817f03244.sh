# Snapshot file
# Unset all aliases to avoid conflicts with functions
# Functions
gawklibpath_append () 
{ 
    [ -z "$AWKLIBPATH" ] && AWKLIBPATH=`gawk 'BEGIN {print ENVIRON["AWKLIBPATH"]}'`;
    export AWKLIBPATH="$AWKLIBPATH:$*"
}
gawklibpath_default () 
{ 
    unset AWKLIBPATH;
    export AWKLIBPATH=`gawk 'BEGIN {print ENVIRON["AWKLIBPATH"]}'`
}
gawklibpath_prepend () 
{ 
    [ -z "$AWKLIBPATH" ] && AWKLIBPATH=`gawk 'BEGIN {print ENVIRON["AWKLIBPATH"]}'`;
    export AWKLIBPATH="$*:$AWKLIBPATH"
}
gawkpath_append () 
{ 
    [ -z "$AWKPATH" ] && AWKPATH=`gawk 'BEGIN {print ENVIRON["AWKPATH"]}'`;
    export AWKPATH="$AWKPATH:$*"
}
gawkpath_default () 
{ 
    unset AWKPATH;
    export AWKPATH=`gawk 'BEGIN {print ENVIRON["AWKPATH"]}'`
}
gawkpath_prepend () 
{ 
    [ -z "$AWKPATH" ] && AWKPATH=`gawk 'BEGIN {print ENVIRON["AWKPATH"]}'`;
    export AWKPATH="$*:$AWKPATH"
}

# setopts 3
set -o braceexpand
set -o hashall
set -o interactive-comments

# aliases 0

# exports 47
declare -x APPLICATION_INSIGHTS_NO_STATSBEAT="true"
declare -x BROWSER="/home/NETID/emd5/.vscode-server/cli/servers/Stable-072586267e68ece9a47aa43f8c108e0dcbf44622/server/bin/helpers/browser.sh"
declare -x CODEX_INTERNAL_ORIGINATOR_OVERRIDE="codex_vscode"
declare -x CONDA_DEFAULT_ENV="base"
declare -x CONDA_EXE="/home/NETID/emd5/miniconda3/bin/conda"
declare -x CONDA_PREFIX="/home/NETID/emd5/miniconda3"
declare -x CONDA_PROMPT_MODIFIER="(base) "
declare -x CONDA_PYTHON_EXE="/home/NETID/emd5/miniconda3/bin/python"
declare -x CONDA_SHLVL="1"
declare -x DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/722588530/bus"
declare -x DEBUG="release"
declare -x DEBUGINFOD_URLS="https://debuginfod.ubuntu.com "
declare -x ELECTRON_RUN_AS_NODE="1"
declare -x HOME="/home/NETID/emd5"
declare -x KRB5CCNAME="FILE:/tmp/krb5cc_722588530"
declare -x LANG="en_US.UTF-8"
declare -x LESSCLOSE="/usr/bin/lesspipe %s %s"
declare -x LESSOPEN="| /usr/bin/lesspipe %s"
declare -x LOGNAME="emd5"
declare -x LS_COLORS=""
declare -x PATH="/home/NETID/emd5/.codex/tmp/arg0/codex-arg06MFCbK:/home/NETID/emd5/.vscode-server/cli/servers/Stable-072586267e68ece9a47aa43f8c108e0dcbf44622/server/bin/remote-cli:/home/NETID/emd5/miniconda3/bin:/home/NETID/emd5/miniconda3/condabin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/opt/liwc-22/bin:/home/NETID/emd5/.vscode-server/extensions/openai.chatgpt-0.4.79-linux-x64/bin/linux-x86_64:/opt/liwc-22/bin"
declare -x RUST_LOG="warn"
declare -x SHELL="/bin/bash"
declare -x SHLVL="1"
declare -x SSH_CLIENT="10.67.131.136 61164 22"
declare -x SSH_CONNECTION="10.67.131.136 61164 10.155.196.27 22"
declare -x SSL_CERT_DIR="/usr/lib/ssl/certs"
declare -x SSL_CERT_FILE="/usr/lib/ssl/cert.pem"
declare -x USER="emd5"
declare -x VSCODE_AGENT_FOLDER="/home/NETID/emd5/.vscode-server"
declare -x VSCODE_CLI_REQUIRE_TOKEN="6d15069a-9008-4e2a-8c62-b084fbbe677b"
declare -x VSCODE_CWD="/home/NETID/emd5"
declare -x VSCODE_ESM_ENTRYPOINT="vs/workbench/api/node/extensionHostProcess"
declare -x VSCODE_HANDLES_SIGPIPE="true"
declare -x VSCODE_HANDLES_UNCAUGHT_ERRORS="true"
declare -x VSCODE_IPC_HOOK_CLI="/run/user/722588530/vscode-ipc-5bbf5d48-e5e0-4ece-8011-6d5943ccc865.sock"
declare -x VSCODE_NLS_CONFIG="{\"userLocale\":\"en\",\"osLocale\":\"en\",\"resolvedLanguage\":\"en\",\"defaultMessagesFile\":\"/home/NETID/emd5/.vscode-server/cli/servers/Stable-072586267e68ece9a47aa43f8c108e0dcbf44622/server/out/nls.messages.json\",\"locale\":\"en\",\"availableLanguages\":{}}"
declare -x VSCODE_RECONNECTION_GRACE_TIME="10800000"
declare -x XDG_DATA_DIRS="/usr/local/share:/usr/share:/var/lib/snapd/desktop"
declare -x XDG_RUNTIME_DIR="/run/user/722588530"
declare -x XDG_SESSION_CLASS="user"
declare -x XDG_SESSION_ID="2041"
declare -x XDG_SESSION_TYPE="tty"
declare -x _CE_CONDA=""
declare -x _CE_M=""
declare -x _CONDA_EXE="/home/NETID/emd5/miniconda3/bin/conda"
declare -x _CONDA_ROOT="/home/NETID/emd5/miniconda3"
