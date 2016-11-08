/**
 * https://github.com/ethereum/wiki/wiki/JavaScript-API
 *
 * https://github.com/ethereum/wiki/wiki/JSON-RPC
 *
 * https://github.com/ethereum/go-ethereum/wiki/Management-APIs
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

    function convertInvoicingAddressToBytes32(invoicingAddress) {

        while(invoicingAddress.length < 32) {
            invoicingAddress += "\0";
        }

        return web3.fromAscii(invoicingAddress);
    }

    function checkConnection() {
        console.log(web3.version);
        if(web3.isConnected()) {
            $("#alert-connection-success").show();
        } else {
            $("#alert-connection-failed").show();
        }

        // Coinbase account is unlocked for Populus private testnet by default
        web3.eth.defaultAccount = web3.eth.coinbase;

        // Automatically load last known contract
        var address = $("#setup-contract-address").val();
        if(address) {
            onSetupContract();
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

        $("#contract-manipulation input, #contract-manipulation button, #contract-manipulation textarea").removeAttr("disabled");

        window.localStorage.setItem("contractAddress", address);
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
     * User wants to update a record through UI.
     */
    function onUpdateData() {
        var invoicingAddress = $("#update-data-invoicing-address").val();
        var data = $("#update-data-invoicing-data").val();

        // We set max gas limit for the transaction absurdly high,
        // because we are on private net and don't care about Ether value
        var gas = 2000000;

        console.log(web3.eth.coinbase, web3.eth.defaultAccount, web3.personal.listAccounts);

        if(!contract) {
            throw new Error("Need to initialize the contract first");
        }

        invoicingAddress = convertInvoicingAddressToBytes32(invoicingAddress);

        // Create a transaction that updates the data record
        contract.updateData(invoicingAddress, data, {value:0, gas:gas}, function(err, result) {
            if(err) {
                $("#alert-update-success").hide();
                window.alert("Could not update data: " + err);
            } else {
                console.log("Outbound tx", result);
                var txid = result;

                $("#btn-update-data").html('<i class="fa fa-spinner fa-spin"></i>');

                var result = waitTx(txid, function(res) {
                    console.log("TX result", res);
                    $("#updated-data-invoicing-address").text(invoicingAddress);
                    $("#alert-update-success").show();
                    $("update-data-invoicing-data").val("");
                    $("update-data-invoicing-address").val("");
                    $("#btn-update-data").html("Update");
                });
                console.log(result);
            }
        });
    }

    /**
     * User queries data.
     */
    function onQueryData() {
        var invoicingAddress = $("#query-invoicing-address").val();

        invoicingAddress = convertInvoicingAddressToBytes32(invoicingAddress);
        console.log("Fetching data from", invoicingAddress);

        var data = contract.getData(invoicingAddress);
        var owners = contract.getOwners(invoicingAddress);
        console.log(data);
        console.log(owners);

        $("#query-result").text(data);
        $("#query-result").show();
    }

    /**
     * Don't let user to do anything until contract has been set up.
     */
    function setupUI() {

        var address = window.localStorage.getItem("contractAddress");

        $("#contract-manipulation input, #contract-manipulation button, #contract-manipulation textarea").prop("disabled", true);

        $("#setup-contract-address").val(address);

    }

    $(document).ready(function() {
        setupConnection();
        setupAbis();
        setupUI();

        $("#btn-setup-contract").click(onSetupContract);
        $("#btn-update-data").click(onUpdateData);
        $("#btn-query-data").click(onQueryData);

        console.log("Setup complete");
    });

    // https://github.com/ethereum/web3.js/issues/393
    function waitTx(txHash, callback) {
      /*
      * Watch for a particular transaction hash and call the awaiting function when done;
      * Ether-pudding uses another method, with web3.eth.getTransaction(...) and checking the txHash;
      * on https://github.com/ConsenSys/ether-pudding/blob/master/index.js
      */
      var blockCounter = 15;
      // Wait for tx to be finished
      var filter = web3.eth.filter('latest').watch(function(err, blockHash) {
        if (blockCounter<=0) {
          filter.stopWatching();
          filter = null;
          console.warn('!! Tx expired !!');
          if (callback)
            return callback(false);
          else
            return false;
        }
        // Get info about latest Ethereum block
        var block = web3.eth.getBlock(blockHash);
        --blockCounter;
        // Found tx hash?
        if (block.transactions.indexOf(txHash) > -1) {
          // Tx is finished
          filter.stopWatching();
          filter = null;
          if (callback)
            return callback(true);
          else
            return true;
        // Tx hash not found yet?
        } else {
          // console.log('Waiting tx..', blockCounter);
        }
      });
    };

})(jQuery);


