# fhir-epi Helm Chart

Helm chart for the **Gravitate-Health ePI FHIR server** (HAPI FHIR **R5**).

This chart bundles:
- [HAPI FHIR JPA Server](https://hapifhir.io/) (official upstream chart) — the FHIR server itself
- [Bitnami PostgreSQL](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) — persistent database
- **Istio VirtualService** — routes external traffic via the platform gateway (mutually exclusive with Ingress)
- **Kubernetes Ingress** — standard ingress alternative when Istio is not available (mutually exclusive with VirtualService)
- **Probe-patch Job** — post-install/upgrade hook that corrects HAPI's liveness/readiness/startup probes to the `/epi/api` context path
- **Auto-generated DB credentials Secret** — created on first install, preserved across upgrades, kept after uninstall

## Prerequisites

| Tool | Version |
|------|---------|
| Kubernetes | ≥ 1.24 |
| Helm | ≥ 3.10 |
| Istio | ≥ 1.17 (if `virtualService.enabled=true`) |
| Ingress controller | any (if `ingress.enabled=true`) |

The Istio **Gateway** (`gh-gateway` by default) must already exist. It is managed by the [istio](https://github.com/Gravitate-Health/istio) repository.

> **Note:** `virtualService.enabled` and `ingress.enabled` are mutually exclusive. Enabling both causes a template error.

## Installation

### 1. Add Helm repositories

```bash
helm repo add hapifhir https://hapifhir.github.io/hapi-fhir-jpaserver-starter/
helm repo add bitnami  https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Download chart dependencies

```bash
helm dependency update charts/fhir-epi
```

### 3. Install

```bash
helm install fhir-epi charts/fhir-epi
```

A 32-character random password is generated automatically and stored in the Secret `fhir-epi-postgresql`. No password flags required.

> **Release name matters:** The default `hapi.externalDatabase.host` is `fhir-epi-postgresql`, matching a release named `fhir-epi`. If you use a different release name, override the host:
> ```bash
> helm install my-release charts/fhir-epi \
>   --set hapi.externalDatabase.host=my-release-postgresql \
>   --set postgresql.auth.existingSecret=my-release-postgresql
> ```

### Credential management

The chart uses Helm's `lookup` function to manage the DB credentials Secret (`fhir-epi-postgresql` by default):

| Event | Behaviour |
|-------|-----------|
| First install | Generates a random 32-char password; creates the Secret |
| Upgrade | Looks up the existing Secret and reuses the same password |
| `helm uninstall` | Secret is **kept** (`helm.sh/resource-policy: keep`) — PVC data stays accessible |

To bring your own credentials, create the secret before installing and point the chart to it:

```bash
kubectl create secret generic my-fhir-epi-creds \
  --from-literal=postgres-password=<admin-pw> \
  --from-literal=password=<app-pw>

helm install fhir-epi charts/fhir-epi \
  --set postgresql.auth.existingSecret=my-fhir-epi-creds \
  --set hapi.externalDatabase.existingSecret=my-fhir-epi-creds
```

### Upgrade

```bash
helm upgrade fhir-epi charts/fhir-epi [--set ...]
```

The probe-patch Job runs automatically on every upgrade.

## Accessing the server

| Endpoint | URL |
|----------|-----|
| FHIR API | `https://<dns>/epi/api/fhir/` |
| OpenAPI UI | `https://<dns>/epi/api/fhir/` |
| Readiness | `https://<dns>/epi/api/readyz` |
| Liveness | `https://<dns>/epi/api/livez` |
| Prometheus metrics | `http://fhir-server-epi:8081/actuator/prometheus` (internal) |

## Key configuration values

| Value | Default | Description |
|-------|---------|-------------|
| `virtualService.enabled` | `true` | Create Istio VirtualService (mutually exclusive with `ingress.enabled`) |
| `virtualService.gateway` | `gh-gateway` | Istio Gateway name |
| `virtualService.uriPrefix` | `/epi/api` | URI prefix for routing |
| `ingress.enabled` | `false` | Create Kubernetes Ingress (mutually exclusive with `virtualService.enabled`) |
| `ingress.className` | `""` | Ingress class name (e.g. `nginx`); empty = cluster default |
| `ingress.annotations` | `{}` | Extra annotations for the Ingress resource |
| `ingress.hosts` | see values | Host rules; default path `/epi/api` with `Prefix` pathType |
| `ingress.tls` | `[]` | TLS configuration for the Ingress |
| `probePatch.enabled` | `true` | Run probe-patch Job post-install/upgrade |
| `probePatch.hookDeletePolicy` | `before-hook-creation` | Helm hook delete policy for probe patch resources |
| `probePatch.deploymentName` | `fhir-server-epi` | Deployment name to patch |
| `postgresql.enabled` | `true` | Bundle PostgreSQL sub-chart |
| `postgresql.auth.existingSecret` | `fhir-epi-postgresql` | Secret name for DB credentials (auto-created) |
| `postgresql.primary.persistence.size` | `8Gi` | DB volume size |
| `postgresql.primary.persistence.existingClaim` | `""` | Use existing PVC |
| `hapi.image.tag` | `v7.6.0` | HAPI FHIR Docker image tag |
| `hapi.replicaCount` | `1` | Number of HAPI FHIR replicas |
| `hapi.externalDatabase.host` | `fhir-epi-postgresql` | PostgreSQL service hostname |

All upstream `hapi-fhir-jpaserver` chart values are available under `hapi.*`. See the [upstream chart documentation](https://github.com/hapifhir/hapi-fhir-jpaserver-starter/tree/master/charts/hapi-fhir-jpaserver) for the full list.

## Disabling bundled PostgreSQL (external DB)

```yaml
postgresql:
  enabled: false

hapi:
  externalDatabase:
    host: my-postgres-host
    port: 5432
    user: fhir
    database: fhir
    existingSecret: my-db-secret
    existingSecretKey: password
```

## Loaded Implementation Guide

The chart pre-configures the Gravitate-Health IG at startup:

| Property | Value |
|----------|-------|
| Package URL | `https://build.fhir.org/ig/hl7-eu/gravitate-health/package.tgz` |
| Name | `hl7.eu.fhir.gh` |
| Version | `0.1.0` |

## Publishing to GHCR

Charts are published automatically via reusable CI/CD workflows. To package manually:

```bash
helm package charts/fhir-epi --destination .
```
