import json

import pytest
from web3.utils.transactions import wait_for_transaction_receipt
from web3.contract import Contract
from web3 import Web3


#: Sample data
RECORD = {
    "name": "Foobär Oy",
    "address": "Esimerkkikatu 1A 00810 Helsinki",
}

RECORD_2 = {
    "name": "Foobär Oy",
    "address": "Muuttanutkuja 1A 00810 Helsinki",
}

#: Sample address
OVT = "003712345678"


def ovt_to_bytes32(ovt: str) -> bytes:
    """Convert OVT formatted invoicing address to internal bytes32 format.

    Right pad addresses with zero.
    """
    b = ovt.encode("ascii")
    assert len(b) < 32
    b += b'\0' * (32 - len(b))
    assert len(b) == 32
    return b


@pytest.fixture()
def registry_contract(chain) -> Contract:
    contract = chain.get_contract('EInvoicingRegistry')
    return contract


@pytest.fixture()
def web3(chain) -> Web3:
    return chain.web3


def check_succesful_tx(web3, txid: str) -> bool:
    """See if transaction went through (Solidity code did not throw)"""
    # http://ethereum.stackexchange.com/q/6007/620
    receipt = wait_for_transaction_receipt(web3, txid)
    txinfo = web3.eth.getTransaction(txid)

    # EVM has only one error mode and it's consume all gas
    return txinfo["gas"] != receipt["gasUsed"]


def test_add_record(web3, registry_contract):
    """Create a new record."""

    # This call will come
    ovt_b = ovt_to_bytes32(OVT)
    data = json.dumps(RECORD).encode("utf-8")

    # Store data
    txid = registry_contract.transact().updateData(ovt_b, data)
    assert check_succesful_tx(web3, txid)

    # Verify we got a created event
    filter = registry_contract.pastEvents("RecordCreated")
    log_entries = filter.get(False)
    assert len(log_entries) == 1   # We get 1 RecordCreated event

    # Read back data
    data = registry_contract.call().getData(ovt_b)
    data = json.loads(data)
    assert data == RECORD

    # Check we are the initial owner
    our_address = web3.eth.coinbase
    owners = registry_contract.call().getOwners(ovt_b)
    assert owners == [our_address]


def test_update_record(web3, registry_contract):
    """Update a new record."""

    # This call will come
    ovt_b = ovt_to_bytes32(OVT)
    data = json.dumps(RECORD).encode("utf-8")

    # Create
    txid = registry_contract.transact().updateData(ovt_b, data)
    assert check_succesful_tx(web3, txid)

    # Update
    data2 = json.dumps(RECORD_2).encode("utf-8")
    txid = registry_contract.transact().updateData(ovt_b, data2)
    assert check_succesful_tx(web3, txid)

    # Verify we got an updated event
    filter = registry_contract.pastEvents("RecordUpdated")
    log_entries = filter.get(False)
    assert len(log_entries) == 1

    # Read back data
    data = registry_contract.call().getData(ovt_b)
    data = json.loads(data)
    assert data == RECORD_2

    # Check we are the initial owner
    our_address = web3.eth.coinbase
    owners = registry_contract.call().getOwners(ovt_b)
    assert owners == [our_address]
