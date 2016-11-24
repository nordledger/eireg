"""Match enums in EInvoicingRegistry.sol

TODO: Now hand mapped, use automation in the future.
"""

import enum


class ContentType(enum.Enum):
    Undefined = 0
    InvoiceContactInformation = 1
    NationalBusinessRegistryData = 2
    OperatorPublicData = 3
    TiekeCompanyData = 4
    TiekeAddressData = 5

