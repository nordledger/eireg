/**
* Registry of e-invoicing addresses as Solidity smart contract.
*/
contract EInvoicingRegistry {

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


    struct InvoicingAddressInformation {

        /* Who can modify this invoicing address as a
           list of Ethereum addresses (public keys).
           Contains one entry, the public key of operator. */
        address[] owners;

        /* Different information attached to this invoicing address.
           Key as ContentType.
         */
        mapping(uint=>string) data;
    }


    /* Business owner set tables what addresses he/she wants to use */
    struct RoutingInformation {

        /* Who can modify busines owner preferred routing.
           list of Ethereum addresses (public keys).
           Contains one entry, the public key of business owner. */
        address[] owners;

        /* Different information attached to this invoicing address  */
        mapping(uint=>string) data;
    }

    struct Company {

        /* Who can update company businessInformation (Contains one key, from YTJ) */
        address[] owners;

        /** List of different business core information data.
            Key as ContentType enum. */
        mapping(uint => string) businessInformation;

        /* Routing information as set by the business owner. */
        RoutingInformation routingInformation;

        /** Map of invoicing address (normalized) to their descriptions.
         *
         * Invoicing address as ASCII string with protocol.
         * Examples:
         *     IBAN:FI6213763000140986
         *     OVT:3705090754
         *
         */

        mapping(string=>InvoicingAddressInformation) invoicingAddresses;

        /* All invoicing addresses as a list, because map keys are not iterable in Solidity */
        string[] allInvoicingAddresses;
    }

    string public version = "0.2";

    /**
     * Map VAT IDs to company records.
     *
     * Key is international Y-Tunnus (FI12312345).
     *
     */
    mapping(string => Company) vatIdRegistry;

    /**
     * MAP invoicing addresses to VAT ids
     */
    mapping(string => string) invoicingAddressRegistry;

    /**
     * Events that smart contracts post to blockchain, so that various listening
     * services can easily detect modifications.
     *
     * These events are indexable by Ethereum node and you can directly query them in JavaScript.
     */
    event CompanyCreated(string vatId);
    event CompanyUpdated(string vatId);
    event InvoicingAddressCreated(string invoicingAddress);
    event InvoicingAddressUpdated(string invoicingAddress);

    /**
     * Constructor parameterless.
     */
    function EInvoicingRegistry() {
    }

    /**
     * Check if we have already imported company core data.
     */
    function hasCompany(string vatId) public constant returns (bool) {
        return vatIdRegistry[vatId].owners.length > 0;
    }

    /**
     * Return VAT ID for a given invoicing address.
     */
    function getVatIdByAddress(string invoicingAddress) public constant returns (string) {
        return invoicingAddressRegistry[invoicingAddress];
    }

    function createCompany(string vatId) public {

        // Check if this party is allowed to update company core data (msg.sender = YTJ only)
        if(!canUpdateCompany(vatId, msg.sender)) {
            throw;
        }

        vatIdRegistry[vatId].owners.push(msg.sender);
        CompanyCreated(vatId);
    }

    function createInvoicingAddress(string vatId, string invoicingAddress) public {

        if(!canUpdateInvoicingAddress(vatId, invoicingAddress, msg.sender)) {
            throw;
        }

        // Become owner
        Company company = vatIdRegistry[vatId];
        InvoicingAddressInformation info = company.invoicingAddresses[invoicingAddress];

        if(info.owners.length > 0) {
            throw; // Already created
        }

        info.owners.push(msg.sender);

        // Backwards mapping invoicing address -> VAT ID
        invoicingAddressRegistry[invoicingAddress] = vatId;

        // List of all registered addresses for this company
        company.allInvoicingAddresses.push(invoicingAddress);

        // Notify new address created
        InvoicingAddressCreated(invoicingAddress);
    }

    function setCompanyData(string vatId, ContentType contentType, string data) public {

        // Check if this party is allowed to update company core data (msg.sender = YTJ only)
        if(!canUpdateCompany(vatId, msg.sender)) {
            throw;
        }

        vatIdRegistry[vatId].businessInformation[uint(contentType)] = data;

        CompanyUpdated(vatId);
    }

    function setInvoicingAddressData(string vatId, string invoicingAddress, ContentType contentType, string data) public {

        if(!canUpdateInvoicingAddress(vatId, invoicingAddress, msg.sender)) {
            throw;
        }

        vatIdRegistry[vatId].invoicingAddresses[invoicingAddress].data[uint(contentType)] = data;

        InvoicingAddressUpdated(invoicingAddress);
    }

    function getBusinessInformation(string vatId, ContentType contentType) public constant returns(string) {
        return vatIdRegistry[vatId].businessInformation[uint(contentType)];
    }

    /**
     * Return all addresses for a company.
     *
     * TODO: Current Solidity does not allow to return string[] over a transaction
     */
    function getInvoicingAddressCount(string vatId) public constant returns(uint) {

        Company company = vatIdRegistry[vatId];

        if(company.owners.length == 0) {
            throw; // Not created yet
        }

        return company.allInvoicingAddresses.length;
    }

    /**
     * Return all addresses for a company.
     *
     * TODO: Current Solidity does not allow to return string[] over a transaction
     */
    function getInvoicingAddressByIndex(string vatId, uint idx) public constant returns(string) {

        Company company = vatIdRegistry[vatId];

        if(company.owners.length == 0) {
            throw; // Not created yet
        }

        return company.allInvoicingAddresses[idx];
    }

    function getAddressInformation(string invoicingAddress, ContentType contentType) public constant returns(string) {

        string memory vatId = getVatIdByAddress(invoicingAddress);
        Company company = vatIdRegistry[vatId];

        if(company.owners.length == 0) {
            throw; // Not created yet
        }

        return company.invoicingAddresses[invoicingAddress].data[uint(contentType)];
    }

    /**
     * Not implemented yet. Anybody can update company core data.
     */
    function canUpdateCompany(string vatId, address sender) public constant returns (bool) {
        return true;
    }

    /**
     * Not implemented yet. Anybody can update company core data.
     */
    function canUpdateInvoicingAddress(string vatId, string invoicingAddress, address sender) public constant returns (bool) {
        return true;
    }

}
