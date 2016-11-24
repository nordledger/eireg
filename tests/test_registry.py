import json

import pytest
from web3.utils.transactions import wait_for_transaction_receipt
from web3.contract import Contract
from web3 import Web3

from eireg import importer
from eireg.eireg.importer import import_invoicing_address


@pytest.fixture()
def registry_contract(chain) -> Contract:
    contract = chain.get_contract('EInvoicingRegistry')
    return contract


@pytest.fixture()
def web3(chain) -> Web3:
    return chain.web3


@pytest.yield_fixture()
def sample_company(chain) -> dict:
    """Load one example company from CSV sample data."""

    # Adusso Oy
    for data in importer.read_csv(importer.SAMPLE_CSV, ["2430372-7"]):
        return data


def check_succesful_tx(web3, txid: str) -> bool:
    """See if transaction went through (Solidity code did not throw)"""
    # http://ethereum.stackexchange.com/q/6007/620
    receipt = wait_for_transaction_receipt(web3, txid)
    txinfo = web3.eth.getTransaction(txid)

    # EVM has only one error mode and it's consume all gas
    return txinfo["gas"] != receipt["gasUsed"]



def test_import_tieke(web3: Web3, registry_contract: Contract, sample_company: dict):
    """Create a new company record + new invoicing address under it."""

    import_invoicing_address(registry_contract, sample_company)








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
