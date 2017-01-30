#!/bin/bash

set -e
set -x

# Figure out coinbase account over web3
COINBASE=`geth --exec 'web3.eth.coinbase' attach rpc:http://127.0.0.1:8545 `

PASSWORD="`cat venv/lib/python3.5/site-packages/geth/default_blockchain_password`"

# Unlock coinbase
result=`geth --exec "personal.unlockAccount($COINBASE, \"$PASSWORD\", 10000)" attach rpc:http://127.0.0.1:8545`

if [ "$result" != "true" ] ; then
    echo "failed to unlock"
    exit 1
else
    echo "Unlocked coinbase $COINBASE"
fi
