/**
 * Registry of e-invoicing addresses as Solidity smart contract.
 */
contract EInvoicingRegistry {

    string public version = "0.1";

    /**
     * Describe one e-invoicing address record.
     *
     */
    struct InvoicingAddressInfo {

        /**
         * List of Ethereum addresses (public keys) that are allowed to modify
         * the invoicing address info.
         *
         * For example, the record owner (company itself), invoice operators
         * and governmental registries can be listed here.
         */
        address[] owners;

        /**
         * Payload is all public data for one invoicing address.
         *
         * Smart contract itself doesn't care what we put here.
         * This can be XML file, JSON file or something else
         * and is defined outside blockchain system.
         *
         */
        bytes data;
    }

    /**
     * Map e-invoicing addresses to full data records.
     *
     * Key is 32 bytes, or 32 characters of ASCII.
     * In the case of Finland this is OVT address, expressed as ASCII string
     * where the right bytes are zero padded.
     *
     */
    mapping(bytes32 => InvoicingAddressInfo) registry;


    /**
     * Events that smart contracts post to blockchain, so that various listening
     * services can easily detect modifications.
     *
     * These events are indexable by Ethereum node and you can directly query them in JavaScript.
     */
    event RecordCreated(bytes32 invoicingAddress);
    event RecordUpdated(bytes32 invoicingAddress);

    /**
     * Constructor parameterless.
     */
    function EInvoicingRegistry() {
    }

    /**
     * Create or update invoicing address data.
     *
     * If a record is created the initial owners are the caller of the function.
     *
     */
    function updateData(bytes32 invoicingAddress, bytes data) public returns (bool) {
        InvoicingAddressInfo memory info;

        info = registry[invoicingAddress];

        // Solidity doesn't have the concept of null,
        // so for empty records we check no owners
        if(info.owners.length == 0) {
            // This is a new record
            createNewRecord(invoicingAddress, data);

            RecordCreated(invoicingAddress);

        } else {
            if(!isAllowedToUpdate(invoicingAddress, msg.sender)) {
                // The current contract caller has no priviledges to update data
                throw;
            }

            // Update new data
            registry[invoicingAddress].data = data;

            RecordUpdated(invoicingAddress);
        }
    }

    function getData(bytes32 invoicingAddress) public constant returns (bytes) {
        return registry[invoicingAddress].data;
    }

    function getOwners(bytes32 invoicingAddress) public constant returns (address[]) {
        return registry[invoicingAddress].owners;
    }

    function createNewRecord(bytes32 invoicingAddress, bytes data) private {
        registry[invoicingAddress].data = data;

        // By default new records are owned by their creator only
        registry[invoicingAddress].owners.push(msg.sender);
    }

    /**
     * Check if particular message sender is allowed to update the record.
     *
     * The message sender (address, public key) must be listed in the record owners.
     *
     */
    function isAllowedToUpdate(bytes32 invoicingAddress, address addr) public constant returns (bool) {
        uint i;
        address[] memory owners;

        owners = registry[invoicingAddress].owners;
        for(i=0; i<owners.length; i++) {
            if(owners[i] == addr) {
                return true;
            }
        }

        return false;
    }
}
