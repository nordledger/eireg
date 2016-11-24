enum ContentType {

    Undefined,

    /** XML as defined in PEPPOL */
    InvoiceContactInformation,

    /** Direct YTJ / other national import */
    NationalBusinessRegistryData,

    /** Data operator wants to expose to others */
    OperatorPublicData,

    /** Data as defined in current TIEKE */
    TiekeCompanyData,

    /** Data as defined in current TIEKE */
    TiekeAddressData

}

enum AddressFormat {
    Undefined,
    OVT,
    IBAN,
    Other
}


struct InvoicingAddressData {

    /* How can modify this invoicing address as a
       list of Ethereum addresses (public keys).
       Contains one entry, the public key of operator. */
    address owners[];

    /* Invoicing address as ASCII string, all capitalized */
    bytes32 invoicingAddress;

    AddressFormat format;

    /* Different information attached to this invoicing address  */
    mapping(ContentType=>string) data;
}


/* Business owner set tables what addresses he/she wants to use */
struct RoutingInformation {
    mapping(bytes32 => bool) allowReceive;
    mapping(bytes32 => bool) allowSend;

    /** Active business owner set address where invoices should be
      * send if multiple options are available */
    bytes32 defaultReceive;
}

struct Company {

    /* Y-Tunnus in Finnish system in the format FI123134. Right bytes zero padded. */
    bytes32 vatId;

    /** List of different business core information data */
    mapping(ContenType => string data[]) businessInformation;

    /* Routing information as set by the business owner. */
    RoutingInformation routingInformation;

    InvoicingAddress invoicingAddresses[];
}

/**
* Registry of e-invoicing addresses as Solidity smart contract.
*/
contract EInvoicingRegistry {

    string public version = "0.2";

    /**
     * Map VAT IDs to company records.
     *
     * Key is 32 bytes, or 32 characters of ASCII.
     * In the case of Finland this is OVT address, expressed as ASCII string
     * where the right bytes are zero padded.
     *
     */
    mapping(bytes32 => InvoicingAddressInfo) vatIdRegistry;

    /**
     * MAP invoicing addresses to VAT ids */
     */
    mapping(bytes32 => bytes32) invoicingAddressRegistry;

    /**
     * Events that smart contracts post to blockchain, so that various listening
     * services can easily detect modifications.
     *
     * These events are indexable by Ethereum node and you can directly query them in JavaScript.
     */
    event CompanyCreated(bytes32 vatId);
    event CompanyUpdated(bytes32 vatId);
    event InvoicingAddressCreated(bytes32 invoicingAddress);
    event InvoicingAddressUpdated(bytes32 invoicingAddress);

    /**
     * Constructor parameterless.
     */
    function EInvoicingRegistry() {
    }

    /**
     * Create or update a new company record.
     *
     * If a record is created the initial owners are the caller of the function.
     */
    function updateCompany(bytes32 vatId, ContentType contentType, string data) public returns (bool) { {

        // Check if this party is allowed to update company core data (msg.sender = YTJ only)
        if(!canUpdateCompany(vatId, msg.sender)) {
            throw;
        }

        // Solidity doesn't have the concept of null,
        // so for empty records we check no owners
        if(!hasCompany(vatId)) {
            // This is a new record
            createNewCompany(vatId);
            CompanyCreated(vatId);
        } else {
            // Update new data
            CompanyUpdated(vatId);
        }

        // Set company data
        vatIdRegistry[vatId].businessInformation[contentType] = data;
    }

    function hasCompany(bytes32 vatId) public constant returns (bool) {
        return vatIdRegistry[vatId].owners.length == 0;
    }

    /**
     * Return VAT ID for a given invoicing address.
     */
    function getVatIdByAddress(bytes32 invoicingAddress) public constant returns (bytes32) {
        return invoicingAddressRegistry[invoicingAddress];
    }

    function createCompany(bytes32 vatId) public {

        // Check if this party is allowed to update company core data (msg.sender = YTJ only)
        if(!canUpdateCompany(vatId, msg.sender)) {
            throw;
        }

        vatIdRegistry[vatId].owners.push(msg.sender);
        CompanyCreated(vatId);
    }

    function createInvoicingAddress(bytes32 vatId, bytes32 invoicingAddress, AddressFormat format) public {

        if(!canCreateInvoicingAddress(vatId, invoicingAddress)) {
            throw;
        }

        // Become owner
        vatIdRegistry[vatId].invoicingAddresses[invoicingAddress].owners.append(msg.sender);
        vatIdRegistry[vatId].invoicingAddresses[invoicingAddress].format = format;

        // Backwards mapping invoicing address -> VAT ID
        invoicingAddressRegistry[invoicingAddress] = vatId;

        InvoicingAddressCreated(invoicingAddress);
    }

    function setCompanyData(bytes32 vatId, bytes32 invoicingAddress, ContentType contentType, string data) public {

        // Check if this party is allowed to update company core data (msg.sender = YTJ only)
        if(!canUpdateCompany(vatId, msg.sender)) {
            throw;
        }

        vatIdRegistry[vatId].businessInformation[contentType] = data;

        CompanyUpdated(vatId);
    }

    function setInvoicingAddressData(bytes32 vatId, bytes32 invoicingAddress, ContentType contentType, string data) public {

        if(!canCreateInvoicingAddress(vatId, invoicingAddress)) {
            throw;
        }

        // Become owner
        vatIdRegistry[vatId].invoicingAddresses[invoicingAddress].owners.append(msg.sender);
        vatIdRegistry[vatId].invoicingAddresses[invoicingAddress].format = format;

        // Backwards mapping invoicing address -> VAT ID
        invoicingAddressRegistry[invoicingAddress] = vatId;

        InvoicingAddressUpdated(invoicingAddress);
    }

    /**
     * Not implemented yet. Anybody can update company core data.
     */
    function canUpdateCompany(bytes32 vatId, address sender) {
        return true;
    }

    /**
     * Not implemented yet. Anybody can update company core data.
     */
    function canCreateInvoicingAddress(bytes32 vatId, bytes32 invoicingAddress, address sender) {
        return true;
    }

}
