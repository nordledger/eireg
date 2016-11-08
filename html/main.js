/**
 * https://github.com/ethereum/wiki/wiki/JavaScript-API
 */

(function($) {
    "use strict";

    var web3;

    function setupConnection() {
        web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
        setTimeout(checkConnection, 2000);
    }

    function checkConnection() {
        console.log(web3.version);
        if(web3.isConnected()) {
            $("#alert-connection-success").show();
        } else {
            $("#alert-connection-failed").show();
        }
    }

    $(document).ready(function() {
        setupConnection();
        console.log("foobar");
    });

})(jQuery);
