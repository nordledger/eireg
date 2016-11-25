=====
Usage
=====

.. contents:: :local:

Working on a local private testnet
==================================

First we deploy a version of the contract on local chain managed by Populus.

.. code-block:: console

    make deploy-local

You will get deployment details::

    Transaction Mined
    =================
    Tx Hash      : 0x3557ed87c7eb517c0e9c69dd15ba7d5c4064ce8d9b40caee40f3522fe6357a73
    Address      : 0xb52fc9040759e04b793cbb094dc64ee051377c4c
    Gas Provided : 362249
    Gas Used     : 262249


This will take ~60 seconds. The default coinbase account is ``0x27d1755735abaf6cefb2299d18458b1091bb2c7b``. It is configured in ``populus.ini``.

Write down **Address** field. It varies for each deployment.

CSV import
==========

TODO

Interacting with web browser
============================

A simple interactive HTML demo is provided to interact with the contract.

Start geth deamon running a local chain. This is the same chain where we deployed the smart contract earlier:

.. code-block:: console

    make run-local-test-chain

It will start to mine transactions on your local computer.

In **another terminal** start a local development web server:

.. code-block:: console

    make run-web-server

Point your browser to::

    http://localhost:8000

The demo directly interacts with Ethereum node over JSON-RPC protocol using `web3.js <https://github.com/ethereum/web3.js/>`_ library.

Fill in ``Contract address`` based on prior ``populus deploy`` command and **Connect** to contract.

Running automated test suite
============================

To run test suite:

.. code-block::

    make test


