#!/bin/bash

# *************************** #
#       EDIT THESE VARS       #
# *************************** #
BLA_PATH="~/Devel/bind-log-analyzer"
BLA_RVM_GEMSET="1.9.3-p125@bind_log_analyzer"
BLA_USER="my_username"

# *************************** #
# DO NOT EDIT BELOW THIS LINE #
# *************************** #
cd $BLA_PATH
. /home/$BLA_USER/.rvm/scripts/rvm && source "/home/$BLA_USER/.rvm/scripts/rvm"
rvm use $BLA_RVM_GEMSET
$BLA_PATH/bin/bind_log_analyzer -f $1