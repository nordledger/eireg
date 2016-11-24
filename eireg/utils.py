def string_to_bytes32(str):
    """Convert OVT formatted invoicing address to internal bytes32 format.

    Right pad addresses with zero.
    """
    b = str.encode("ascii")
    assert len(b) < 32
    b += b'\0' * (32 - len(b))
    assert len(b) == 32
    return b


def ytunnus_to_vat_id(str):
    """Convert Y-Tunnus to international format."""
    assert str[-2] == "-"
    return "FI" + str[0:-2] + str[-1]


def normalize_invoicing_address(str) -> str:
    """Guess what format the invoicing address is and return normalized form.

    :return: E.g. "IBAN:FI6213763000140986"
    """

    # 003705090754 OVT-tunnus
    # FI6213763000140986 IBAN

    mappings = {
        "OVT-tunnus": "OVT",
        "IBAN": "IBAN",
    }

    address, spec = str.split(" ")

    if spec == "OVT-tunnus":
        address = address.lstrip("0")  # Dunno?

    return mappings[spec] + ":" + address


