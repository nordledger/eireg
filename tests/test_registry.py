import json
from typing import List

import pytest
from web3.utils.transactions import wait_for_transaction_receipt
from web3.contract import Contract
from web3 import Web3

from eireg import importer
from eireg.importer import import_invoicing_address
from eireg.data import ContentType


@pytest.fixture()
def registry_contract(chain) -> Contract:
    contract = chain.get_contract('EInvoicingRegistry')
    return contract


@pytest.fixture()
def web3(chain) -> Web3:
    return chain.web3


@pytest.fixture()
def sample_company() -> dict:
    """Load one example company from CSV sample data."""

    # Adusso Oy
    # 003724303727 OVT-tunnus
    for data in importer.read_csv(importer.SAMPLE_CSV, ["2430372-7"]):
        return data

@pytest.fixture()
def multiple_tieke_rows(chain) -> dict:
    """Return a company with multiple addresses."""

    # 360 Plus Oy
    # 2659753-8
    # FI6213763000140986 IBAN
    # 003726597538 OVT-tunnus
    return [data for data in importer.read_csv(importer.SAMPLE_CSV, ["2659753-8"])]


def test_import_company_with_one_address(web3: Web3, registry_contract: Contract, sample_company: dict):
    """Create a new company record + new invoicing address under it."""

    import_invoicing_address(registry_contract, sample_company)

    assert registry_contract.call().hasCompany("FI24303727")
    assert registry_contract.call().getVatIdByAddress("OVT:3724303727") == "FI24303727"

    # Check business core data
    expected = {
        "name": "Adusso Oy"
    }

    actual = registry_contract.call().getBusinessInformation("FI24303727", ContentType.TiekeCompanyData.value)
    assert json.loads(actual) == expected

    # Check address data
    expected = {
        "operatorName": "OpusCapita Group Oy",
        "operatorId": "3710948874",
        "permissionToSend": True,
        "sends": True,
        "receives": True,
    }

    # See we have one address
    assert registry_contract.call().getInvoicingAddressCount("FI24303727") == 1
    assert registry_contract.call().getInvoicingAddressByIndex("FI24303727", 0) == "OVT:3724303727"

    actual = registry_contract.call().getAddressInformation("OVT:3724303727", ContentType.TiekeAddressData.value)
    assert json.loads(actual) == expected


def test_import_company_with_multiple_addresses(web3: Web3, registry_contract: Contract, multiple_tieke_rows: List[dict]):
    for row in multiple_tieke_rows:
        import_invoicing_address(registry_contract, row)

    assert registry_contract.call().getInvoicingAddressCount("FI26597538") == 2
    assert registry_contract.call().getInvoicingAddressByIndex("FI26597538", 0) == "IBAN:FI6213763000140986"
    assert registry_contract.call().getInvoicingAddressByIndex("FI26597538", 1) == "OVT:3726597538"


