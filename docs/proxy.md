# JSON-RPC API proxy via Nginx

## Preface

This blog post discussed how to securely run your Ethereum nodes behind a password for secure exposure over Internet.

Go Ethereum (geth) is the most popular software for Ethereum node. The other popular Ethereum implementations are Parity and cpp-ethereum. Distributed applications (Dapps) are JavaScript coded web pages that connect to any of these Ethereum node softwares over JSON-RPC API protocol that is self runs on the top of HTTP protocol.

*geth* or none of the node softwares themselves doesn't provide secure networking. It is not safe to expose Ethereum JSON-RPC API to public Internet as even with private APIs disabled this opens a door for trivial denial of service attacks. Node softwares themselves don't need to provide secure networking primitives, as this kind of built-in functionality would increase complexity and add attack surface to critical blockchain node software.

Dapps themselve are pure client side HTML and JavaScript, don't need any servers and they can run in any web browser, including mobile and embedded ones, like one inside Mist wallet.

## Using Nginx proxy as HTTP Basic Authenticator

There are several ways to protect access to a HTTP API. The most common methods include API token in the HTTP header, cookie based authentication or [HTTP Basic Access Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication).

HTTP Basic Authentication is a very old feature of HTTP protocol where a web browser opens a native pop dialog asking for  username and password. It is limited in nature, but very easy to implement and perfect for use cases where one needs to expose a private Dapp for a limited Internet audience. These use cases include showing a Dapp demo, private and permissioned blockchain applications or exposing Ethereum functionality as a part of your software-as-a-service solution.

## Nginx

[Nginx](http://nginx.org/) is one of the most popular open source web server applications. We show how to set up Nginx web server, so that it servers your Dapp (HTML files) and geth JSON-RPC API privately using HTTP Basic Auth.

We assume Ubuntu 14.04 of newer Linux server. The file locations may depend on the used Linux distribution.

## Installing Nginx

Install Nginx on Ubuntu Linux 14.04 or newer:

```
sudo apt install nginx
```

# Configuring Nginx

We assume we edit the default website configuration file `/etc/nginx/sites-enabled/default`. We use [proxy_pass directive](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass) to communicate with upstream geth that runs in `localhost:8545`:

    server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
        server_name demo.nordledger.com;

        root /usr/share/nginx/html;
        index index.html 
        
        # Geth proxy that password protects the public Internet endpoint
        location /eth {
            auth_basic "Restricted access to this site";
            auth_basic_user_file /etc/nginx/protected.htpasswd;
           
            # Proxy to geth note that is bind to localhost port                        
            proxy_pass http://localhost:8545            
        }

        # Server DApp static files
        location / {
            auth_basic "Restricted access to this site";
            auth_basic_user_file /etc/nginx/protected.htpasswd;
        }       
    }
    
## Configuring geth

The easiest way to get started with daemonized geth is to run it in a screen:

```
screen

geth  # Your command line parameters here
```

Exit `screen` with CTRL+A, D.

[See geth private testnet instructions](http://ethereum.stackexchange.com/questions/125/how-do-i-set-up-a-private-ethereum-network).

## Configuring Dapp

In your Dapp, make [web3.js](https://github.com/ethereum/web3.js/) to use `/eth` endpoint:
 
```
  function getRPCURL() {
    if(window.location.href.includes("demo.nordledger.com")) {      
      // Password protected geth deployment
      return "http://demo.nordledger.com/eth"
      
    } else {
        // Localhost development
      return "http://localhost:8545";  
    }
  }
  
  // ...
    
  web3.setProvider(new web3.providers.HttpProvider(getRPCURL()));
```

## Deploying Dapp

Copy your DApp files to `/usr/share/nginx/html` on your server.




