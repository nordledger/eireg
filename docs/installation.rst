.. highlight:: shell

============
Installation
============

Preface
^^^^^^^

Instructions are written in OSX and Linux in mind.

Experience needed

* Basic command line usage

* Basic Github usage

* Basic GNU make usage

Setting up
^^^^^^^^^^

Packages needed

* `Populus native dependencies <http://populus.readthedocs.io/en/latest/quickstart.html>`_

Get Solidity compiler. For OSX:

.. code-block:: console

    # Install solcjs using npm (JavaScript port of solc)
    sudo npm install -g solc

    # Symlink solcjs as solc, so that Populus finds it as default solc command
    sudo ln -s `which solcjs` /usr/local/bin/solc

Clone this repository from Github.

Python 3.x required. `See installing Python <https://www.python.org/downloads/>`_.

.. code-block:: console

     python3.5 --version
     Python 3.5.2

Create virtualenv for Python package management in the project root folder (same as where ``setup.py`` is):

.. code-block:: console

    python3.5 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
