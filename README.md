# Gravitate-Health HAPI FHIR Deployments

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Helm charts for deploying the FHIR servers of the **Gravitate-Health FOSPS platform**.

## Overview

The platform runs two independent FHIR server instances, each with its own Helm chart:

| Chart | Path | FHIR Version | Context path | Purpose |
|-------|------|-------------|-------------|---------|
| `fhir-epi` | `charts/fhir-epi/` | R5 | `/epi/api` | Stores electronic Product Information (ePI) FHIR resources |
| `fhir-ips` | `charts/fhir-ips/` | R4 + IPS | `/ips/api` | Stores International Patient Summary (IPS) resources |

Each chart bundles:
- **HAPI FHIR JPA Server** via the [official upstream Helm chart](https://github.com/hapifhir/hapi-fhir-jpaserver-starter/tree/master/charts/hapi-fhir-jpaserver) (no custom Docker image required)
- **PostgreSQL** via the [Bitnami chart](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)
- **Istio VirtualService** for external access through the platform gateway
- **Probe-patch Job** that automatically corrects liveness/readiness/startup probe paths after every install or upgrade

## Architecture

```
Internet
   │
   ▼
Istio Gateway (gh-gateway)      ← managed by github.com/Gravitate-Health/istio
   ├── /epi/api  ──► fhir-server-epi (Service) ──► HAPI FHIR R5 Pod ──► postgresql (fhir-epi)
   └── /ips/api  ──► fhir-server-ips (Service) ──► HAPI FHIR R4 Pod ──► postgresql (fhir-ips)
```

## Prerequisites

- Kubernetes ≥ 1.24
- Helm ≥ 3.10
- Istio ≥ 1.17 with the `gh-gateway` Gateway already deployed

## Quick Start

### 1. Add Helm repositories

```bash
helm repo add hapifhir https://hapifhir.github.io/hapi-fhir-jpaserver-starter/
helm repo add bitnami  https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Update chart dependencies

```bash
helm dependency update charts/fhir-epi
helm dependency update charts/fhir-ips
```

### 3. Deploy the ePI FHIR server

```bash
helm install fhir-epi charts/fhir-epi \
  --set postgresql.auth.postgresPassword=<admin-password> \
  --set postgresql.auth.password=<app-password>
```

### 4. Deploy the IPS FHIR server

```bash
helm install fhir-ips charts/fhir-ips \
  --set postgresql.auth.postgresPassword=<admin-password> \
  --set postgresql.auth.password=<app-password>
```

### Using Kubernetes Secrets (recommended for production)

```bash
# ePI
kubectl create secret generic postgresql-fhir-epi \
  --from-literal=postgres-password=<admin-pw> \
  --from-literal=password=<app-pw>

helm install fhir-epi charts/fhir-epi \
  --set postgresql.auth.existingSecret=postgresql-fhir-epi \
  --set hapi.externalDatabase.existingSecret=postgresql-fhir-epi \
  --set hapi.externalDatabase.existingSecretKey=password

# IPS
kubectl create secret generic postgresql-fhir-ips \
  --from-literal=postgres-password=<admin-pw> \
  --from-literal=password=<app-pw>

helm install fhir-ips charts/fhir-ips \
  --set postgresql.auth.existingSecret=postgresql-fhir-ips \
  --set hapi.externalDatabase.existingSecret=postgresql-fhir-ips \
  --set hapi.externalDatabase.existingSecretKey=password
```

## Upgrading

```bash
helm upgrade fhir-epi charts/fhir-epi [--set ...]
helm upgrade fhir-ips charts/fhir-ips [--set ...]
```

The probe-patch Job runs automatically on every upgrade — no manual patching required.

## Chart documentation

- [charts/fhir-epi/README.md](charts/fhir-epi/README.md) — ePI chart configuration reference
- [charts/fhir-ips/README.md](charts/fhir-ips/README.md) — IPS chart configuration reference

## Probe patching — why it exists

The upstream HAPI FHIR Helm chart hardcodes probe paths to `/livez` and `/readyz`. When a server is deployed at a context path (e.g. `/epi/api`), the actual health endpoints become `/epi/api/livez` and `/epi/api/readyz`. Both charts include a post-install/upgrade Helm hook Job that automatically patches the probes to the correct paths using `kubectl patch`.

## Publishing charts to GHCR

Charts are published to the GitHub Container Registry via reusable CI/CD workflows. To package a chart manually:

```bash
helm package charts/fhir-epi --destination .
helm package charts/fhir-ips --destination .
```

## Usage

Please refer to the official documentation of [HAPI FHIR](https://hapifhir.io/hapi-fhir/docs/).

## Getting help

In case you find a problem or you need extra help, please use the issues tab to report the issue.

## Contributing

To contribute, fork this repository and send a pull request with the changes squashed.

License
-------

This project is distributed under the terms of the [Apache License, Version 2.0 (AL2)](http://www.apache.org/licenses/LICENSE-2.0).  The license applies to this file and other files in the [GitHub repository](https://github.com/Gravitate-Health/Gateway) hosting this file.

```
Copyright 2022 Universidad Politécnica de Madrid

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

Authors and history
---------------------------
- Jens Kristian Villadsen ([@jkiddo](https://github.com/jkiddo))
- Álvaro Belmar ([@abelmarm](https://github.com/abelmarm))

Acknowledgments
---------------
 - [HAPI FHIR Server project](https://github.com/hapifhir/hapi-fhir)

