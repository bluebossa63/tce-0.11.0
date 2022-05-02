# Tanzu Community Edition 0.11 - hands on!

This repository contains all files I used to set up a management cluster that is capable to drive builds and the creation of workload clusters on demand.

I adapted everything to my home lab environment with minimal requirements - no NSX and no LB integration with HA-Proxy or AVI-Loadbalancer. I decided to postpone this step (publishing to the internet) for now. If I can reach everything from my home network, this is good enough for now.


## Documentation
TCE has it's own community driven [documentation](https://tanzucommunityedition.io/docs/v0.11/). I'm pleased with the quality so far. The only topic I had to dig deeper was the usage of self-signed registries or CAs. If you don't plan to use registries without a well known CA, you just can start installing according to the documentation. And of course don't miss the awesome knowledge that can be picked up at any time at [Tanzu Developer Center](https://tanzu.vmware.com/developer/).

### Repository Conventions
The git repository was created with for my personal environment and is NOT parametrized. 
Please scan for the following keywords to adapt it right from the start. 

- ne.local (my local home domain, is used for a lot of fqdns and certificates)
- niceneasy (my company, used for the cluster issuer niceneasy-ca)
- administrator@vsphere.local (admin user for vsphere)
- CHANGEME (password for vsphere)
- For some registry-credentials you must provide your own user password, of course.

I hope I got them all, please check each file individually before launching any installs.

### Prerequisites

- you have to be able to set your own DNS records 
- knative-serving needs support of wildcard domains
- You have created your own CA and have key and crt in place
- You are working with a fully equiped workstation (kubectl, tanzu binaries, docker)
- You have access to a vCenter installation with enough ressources

DNS can be simulated by editing /etc/hosts on the machines but this can be cumbersome...
And I found out that any domain ending with "local" is not treated correctly by resolvectl resulting in "Temporary failure in name resolution". The reason seems to be that resolvectl is consindering itself as master of the "local" domain - any subdomain must be registered explicitely in the search path of /etc/resolv.conf - now managed by system-resolved.

```bash
/etc/systemd/resolved.conf:

[Resolve]
DNS=192.168.0.9
FallbackDNS=192.168.0.9
Domains=ne.local

systemctl restart systemd-resolved.service
```
I set the DNS and the domains explicitely. That's another task that could be done by using the templating mechanism of [tanzu cluster creation](https://github.com/bluebossa63/tce-0.11.0/blob/master/blogs/part%201/blog-1.md#use-a-local-domain).

### Further Reading

Please follow my write-ups covering my tests and findings:

[Cluster Configuration - Custom Certificate Authority](./blogs/part%201/blog-1.md)

[Package Handling - Configuration Management](./blogs/part%202/blog-2.md)

[Build Tools proposed by TCE 0.11.0](./blogs/part%203/blog-3.md)

[E2E Sample](./blogs/part%204/blog-4.md)