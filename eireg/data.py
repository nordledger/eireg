"""Match enums in EInvoicingRegistry.sol

TODO: Now hand mapped, use automation in the future.
"""

import enum


# How empty VAT id is represented in Solidity native data
NULL_VAT_ID = "\0" * 32


class ContentType(enum.Enum):
    Undefined = 0
    InvoiceContactInformation = 1
    NationalBusinessRegistryData = 2
    OperatorPublicData = 3
    TiekeCompanyData = 4
    TiekeAddressData = 5


class AddressFormat(enum.Enum):
    Undefined = 0
    OVT = 1
    IBAN = 2
    Other = 3
