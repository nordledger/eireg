/**
 * https://github.com/ethereum/wiki/wiki/JavaScript-API
 */

(function($) {
    "use strict";

    var web3;
    var abis = null;

    // web3.Contract object to EInvoicingRegistry
    var contract = null;

    function setupConnection() {
        web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
        setTimeout(checkConnection, 2000);
    }

    function setupAbis() {
        $.getJSON("/contracts.json", function(data) {
            abis = data;
            console.log("ABI descriptions loaded");
        });
    }

    function checkConnection() {
        console.log(web3.version);
        if(web3.isConnected()) {
            $("#alert-connection-success").show();
        } else {
            $("#alert-connection-failed").show();
        }
    }

    /**
     * Use web3 to poke the contract to see if it looks registry proper.
     */
    function setupContract(address) {
        if(!abis) {
            window.alert("ABI data not loaded");
            return;
        }

        // Load contract ABI data
        var EInvoicingRegistry = web3.eth.contract(abis.EInvoicingRegistry.abi);

        // Instiate proxy object
        contract = EInvoicingRegistry.at(address);

        try {
            var ver = contract.version();
        } catch(e) {
            window.alert("Error communicating with the contract:" + e);
            return;
        }

        if(!ver) {
            window.alert("Contract seems to be invalid");
            return;
        }

        $("#active-address").text(address);
        $("#active-version").text(ver);
        $("#alert-contract-success").show();

        $("#contract-manipulation input, #contract-manipulation button").removeAttr("disabled");
    }

    /**
     * Check given contract id is valid.
     */
    function onSetupContract() {
        var address = $("#setup-contract-address").val();
        if(!address) {
            window.alert("Please enter contract address");
            return;
        }

        setupContract(address);
    }

    /**
     * Don't let user to do anything until contract has been set up.
     */
    function disableUI() {
        $("#contract-manipulation input, #contract-manipulation button").prop("disabled", true);
    }

    $(document).ready(function() {
        setupConnection();
        setupAbis();
        disableUI();

        $("#btn-setup-contract").click(onSetupContract);

        console.log("Setup complete");
    });

})(jQuery);
