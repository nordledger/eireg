# -*- coding: utf-8 -*-
import csv
import json
import os
from typing import Optional
from web3.contract import Contract

from eireg.eireg.blockchain import check_succesful_tx
from eireg.eireg.data import NULL_VAT_ID, ContentType
from eireg.eireg.utils import ytunnus_to_vat_id, normalize_invoicing_address, string_to_bytes32

SAMPLE_CSV = os.path.join(os.path.dirname(__file__), "..", "sample.csv")


def read_csv(fname, limit_to: Optional[list]=None):
    """Read Tieke CSV export file.

    :param fname: abs path to .csv
    :param limit_to:  limit to list of given value in Y-tunnus column
    :yield: dict of read rows
    """

    with open(fname) as inp:
        reader = csv.DictReader(inp)

        for row in reader:

            if limit_to:
                if row["Y-tunnus"].strip() not in limit_to:
                    continue
            yield row


def import_invoicing_address(contract: Contract, tieke_data: dict):
    """Sample importer for an invoicing address."""

    vat_id = ytunnus_to_vat_id(tieke_data["Y-Tunnus"])
    vat_id = string_to_bytes32(vat_id)  # Internal format

    # We have not imported this company yet
    if not contract.call().hasCompany(vat_id):
        # TODO: This demo creates a company record too, but all vatIds should be prepopulated
        txid = contract.transact.createNewCompany(vat_id)
        assert check_succesful_tx(contract, txid)

        # Create core company info

        data = {
            "name": tieke_data["Yrityksen nimi"]
        }

        data = json.dumps(data)  # Convert to UTF-8 string
        contract.transact.setCompanyData(vat_id, ContentType.TiekeCompanyData, data)

    address, address_format = normalize_invoicing_address(tieke_data["Vastaanotto-osoite"])
    address = string_to_bytes32(address)# Internal format

    # We have not imported this address yet
    assert contract.call().getVatIdByAddress(vat_id, address) == NULL_VAT_ID

    # Create new OVT address
    txid = contract.transact().createInvoicingAddress(vat_id, address_format, address)
    assert check_succesful_tx(contract, txid)

    tieke_address_data = {
        "operatorName": tieke_data["Operaattori"],
        "operatorId": tieke_data["Välittäjän tunnus"],
        "permissionToSend": tieke_data["Lähetyslupa"] == "Kyllä",
        "sends": tieke_data["Lähettää"] == "Kyllä",
        "receives": tieke_data["Vastaanottaa"] == "Kyllä",
    }

    contract.transact().setInvoicingAddressData(vat_id, address, ContentType.TiekeAddressData, tieke_address_data)

