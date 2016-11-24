from typing import Union

from web3 import Web3
from web3.contract import Contract
from web3.utils.transactions import wait_for_transaction_receipt


def check_succesful_tx(web3: Union[Web3, Contract], txid: str) -> bool:
    """See if transaction went through (Solidity code did not throw)"""

    if isinstance(web3, Contract):
        web3 = web3.web3

    # http://ethereum.stackexchange.com/q/6007/620
    receipt = wait_for_transaction_receipt(web3, txid)
    txinfo = web3.eth.getTransaction(txid)

    # EVM has only one error mode and it's consume all gas
    return txinfo["gas"] != receipt["gasUsed"]
