#!/bin/bash

vault secrets enable -path=pki/apps/root pki

# One year
vault secrets tune -max-lease-ttl=8760h pki/apps/root

# Import CA with /config/ca
vault write pki/apps/root/config/ca pem_bundle=@talos-apps-tamrieltower-local.pem

