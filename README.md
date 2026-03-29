# ubiquiti-dream-machine-acme

A Docker-based solution for issuing and renewing certificates with `acme.sh` using DNS-based ACME challenges, then staging and optionally deploying the certificate files to a Ubiquiti Dream Machine.

The project is intentionally minimal:

- it uses Let's Encrypt
- it uses RSA `2048`
- it keeps the required inputs small so the flow stays simple
- provider credentials stay outside git and are supplied through the environment

## Prerequisits 

- installed Docker with Linux containers enabled
	Docker install guide: https://docs.docker.com/engine/install/
- a DNS provider supported by `acme.sh`
- API credentials for your DNS provider with the minimum DNS edit permissions needed for `_acme-challenge` TXT records

## Docker

Build the image from the project root:

```sh
docker build -t udm-acme .
```

Run it with the project mounted into the container:

Supported Docker actions:

- `issue`: issue and stage only
- `renew`: renew and stage only
- `deploy`: deploy already-staged files only
- `issue-deploy`: issue, stage, then deploy
- `renew-deploy`: renew, stage, then deploy

Example for `issue-deploy`:

For `bash` or `sh`:

```sh
docker run --rm \
	-v "$PWD:/workspace" \
	udm-acme issue-deploy
```

For PowerShell:

```powershell
docker run --rm `
	-v "${PWD}:/workspace" `
	udm-acme issue-deploy
```

The other actions use the same command pattern with a different final action name: `issue`, `renew`, `deploy`, or `renew-deploy`.

The only persistent output inside the mounted project is `./certificates`.

The staged files are written to `./certificates/` by default:

- `privkey.pem`
- `fullchain.pem`
- `cert.pem`
- `chain.pem`

If you use a deploy-related Docker action or run the deploy script directly, the wrapper uploads:

- `./certificates/fullchain.pem` to `/data/unifi-core/config/unifi-core.crt`
- `./certificates/privkey.pem` to `/data/unifi-core/config/unifi-core.key`

and then runs `systemctl restart unifi-core` over SSH.

## Configuration

`config/local.env` is loaded directly by the wrapper, both on the host and in Docker.

Required for `issue`:

- `ACME_ACCOUNT_EMAIL`
- `CERT_DOMAIN`
- `DNS_PROVIDER`

For DNS provider-specific variables, see the `acme.sh` DNS API documentation:

- https://github.com/acmesh-official/acme.sh/wiki/dnsapi


Provider-specific variables are not interpreted by this project, but they are loaded from `config/local.env` or the shell environment and then passed through to `acme.sh`. Set whatever your selected `acme.sh` DNS provider requires.

Minimal certificate variables:

- `CERT_DOMAIN`: primary domain
- `DNS_PROVIDER`: acme.sh DNS hook name, for example `dns_ionos` or `dns_ionos_cloud`

This project always uses Let's Encrypt with RSA `2048`.

That is intentional. The idea is to avoid extra knobs unless they are actually needed, and to keep the workflow easy to understand and run.

RSA `2048` is used because Dream Machine deployments may fall back to the built-in self-signed certificate when given an ECC certificate.

Optional Dream Machine deployment variables:

- `UDM_HOST`: Dream Machine hostname or IP
- `UDM_USER`: SSH user, default `root`
- `UDM_PASSWORD`: SSH password
- `UDM_PORT`: SSH port, default `22`
- `UDM_CERT_DIR`: target directory, default `/data/unifi-core/config`
- `UDM_RESTART_COMMAND`: restart command, default `systemctl restart unifi-core`

`UDM_HOST` and `UDM_PASSWORD` are required for deploy-related Docker actions and for `bin/deploy-dream-machine.sh`.
