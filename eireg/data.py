"""Match enums in EInvoicingRegistry.sol

TODO: Now hand mapped, use automation in the future.
"""

import enum
import json

from typing import List


class ContentType(enum.Enum):
    Undefined = 0
    InvoiceContactInformation = 1
    NationalBusinessRegistryData = 2
    OperatorPublicData = 3
    TiekeCompanyData = 4
    TiekeAddressData = 5



def create_company_preferences(default_address: str, invoice_addresses: List[dict]) -> str:
    """Return a JSON encoded string of a company preferences to be stored within the smart contract.

    Example of company preferences data::

        {
            "defaultAddress": "xxx",
            "invoiceAddresses": {
                "xxx": {
                    "permissionToSend": true,
                    "sends": true,
                    "receives": true,
                    "receivePreferences": ["tax"],
                }
            }

        }

    """
    data = {
        "defaultAddress": default_address,
        "invoiceAddresses": invoice_addresses,
    }
    return json.dumps(data)
