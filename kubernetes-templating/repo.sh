#!/bin/bash
helm repo add templating https://harbor.34.91.63.42.nip.io/chartrepo/library
helm push --username admin --password Harbor12345  frontend/ templating
helm push --username admin --password Harbor12345  hipster-shop/ templating
