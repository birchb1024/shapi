# shapi
Use ssh as transport for JSON-based APIs. (Kinda REST over ssh)

# Introduction
In many Linux and Unix sites, [ssh](https://www.openssh.com/) is on all machines and is very trusted. ssh is trusted becuase it uses PKI for authentication and strong ciphers for on-the-wire encryption. Every machine runs the ssh server/daemon `sshd` and users and automation tools such as [Ansible](https://www.ansible.com/) securely connect from machine to machine to automate many privileged administration tasks. ssh is the workhorse of DevOps. Some shops also use `scp/sftp` to transfer data files around the organisation. 

When most architects realise they need a client-server system to allow machines to access services remotely, they provide a REST service or microservice which is JSON carried on HTTP(S) usually they will add JWT for authentication. This requires quite some work - installing web servers, authentication solutions, possible load balancers. For solutions which must scale to millions of transactions ut makes perfect sense. However for administration tasks which are typically very low volume this is a significant overhead. 

Shapi provides a way to to provide JSON APIs by leveraging existing ssh networks without the overhead of building a web infrastructure. 

# Example

Supposing you are a client, you want to access a shapi service for getting data from a user directory service. First you provide your ssh public key to the service administrator. The API documentation provides details of the command to run and the interface. You invoke ssh and supply the command line with the userid:

```
$ ssh -p 2549 user/detail '{ "userid": "jondoh" }'
```

The service responds with the data on standard out:
```
$ ssh -p 2549 user/detail '{ "userid": "jondoh" }'
{ "userid": "jondoh",
  "name" : "Jon Doh",
  "email" : "jon.doh@megacorp.com",
 . . .
 }
```

# How It Works

## Rootless ssh Daemon

Normally the ssh daemon is running as the `root` user and only `root` can change its configuration. Since we're most likely to be ordinary users, we don't want root access in order to administer our own ssh world. Luckily for us `openssh` allows ordinary users to run their own limited ssh daemons. shapi provides the configuration files needed to do this. This ssh daemon will need it's own port other than the default port 22. (Of course if you _are_ root an all your systems you can choose to use the system sshd, but that is going to be less secure than running non-root.) 

So we have our own ssh daemon. Let's say we have a user called `shapiuser` who has run up the sshd. sshd allows shells to be spawned running as the `shapiuser` and they can only access the files and resources configure in the operating system. However we don't want the client to run a normal shell session.  

## Forced Commands

The ssh daemon can run particular commands instead of starting an interactice shell. This is via the `ForceCommand` directive. So in our example there is a mapping between `user/detail` and a special script or command which executes the service. shapi provides a framework for launching application programs and passing parameters to them. 

## Performance

Setting up an ssh session involves quite a bit. There is negotiation of authentication, ciphers, DNS lookups and so on. This is the cost of good security. Without optimisatio connections can take 200 milliseconds, however there are [ways to improve this](https://www.tecmint.com/speed-up-ssh-connections-in-linux/) to around 25 milliseconds depending on the equiment. 

The sshd server is very capable of handling hundreds of simultaneous connections, so load capacity is configurable.

# shapi

To Be Continued...

# Notes
## Alternative to openssh - ssh daemons
Initially shapi will use the defacto sshd - openssh - mainly becuase it's already installed on most Linux machines we use at my workplace. Later I may add support for the alternatives, these are some of the more interesting options. 
* [sshfront - A lightweight SSH server frontend where authentication and connections are controlled with command handlers / shell scripts.](https://github.com/gliderlabs/sshfront)
* [dropbear - a relatively small SSH server and client.](https://matt.ucc.asn.au/dropbear/dropbear.html)
* [gliderlabs](https://github.com/gliderlabs/ssh)
* [More...](https://en.wikipedia.org/wiki/Comparison_of_SSH_servers)
## Alternatives to shapi

* [Simplifies running a single command over SSH, and manages authorized keys (ACL) and users in order to do so.](https://github.com/dokku/sshcommand)
* 

