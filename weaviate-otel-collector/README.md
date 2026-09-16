# weaviate-otel-collector (Helm chart)

Deploys a pre-configured OpenTelemetry collector into a customer's Kubernetes
cluster. It scrapes a self-hosted Weaviate's Prometheus endpoint and **pushes** a
curated, label-sanitised metric set to the Weaviate Cloud ingest gateway
(OTLP/HTTP, gzip, bearer-auth). Part of "Cloud Connect Phase 1" — see
`oss-metrics-rfc-v2`.

> **Status: scaffold.** Validated with `helm lint` + `helm template`; not yet
> tested against a live cluster. See "Known TODOs" below.

## What it deploys
- An OTEL collector `Deployment` (`otel/opentelemetry-collector-contrib`).
- A `ConfigMap` with the collector pipeline (prometheus k8s_sd receiver →
  allow-list filter → label/cardinality reduction → OTLP push).
- A namespaced **`Role` + `RoleBinding`** (`pods: get/list/watch`) — **not** a
  `ClusterRole`. Minimal blast radius (RFC § 2.1.1).
- A `ServiceAccount`.

It does **not** create any `Service`/`Ingress`/`Gateway` — the collector is
outbound-only.

## Design note: self-contained vs subchart
RFC § 2.1 suggested depending on the upstream `opentelemetry-collector` chart as a
subchart. This scaffold instead **vendors its own templates**, because the
collector config must be templated with `.Values` (gateway endpoint, Weaviate
namespace, ports) and Helm can't template values *into* a subchart cleanly. A
self-contained chart keeps full control and is simpler to publish/install. Revisit
if we'd rather inherit the upstream chart's probe/resource ergonomics.

## Install
Prereq: Weaviate running with `PROMETHEUS_MONITORING_ENABLED=true`, and a Secret
holding the telemetry token (the console generates the token):

```bash
kubectl create secret generic weaviate-telemetry-token \
  --from-literal=token=wvtt_xxxxxxxx -n <weaviate-namespace>

helm install weaviate-otel-collector ./weaviate-otel-collector \
  --namespace <weaviate-namespace> \
  --set gateway.endpoint=https://telemetry.weaviate.cloud \
  --set telemetry.existingSecretName=weaviate-telemetry-token
```

Install into the **same namespace as Weaviate** (then `weaviate.namespace`
defaults to the release namespace). To scrape a different namespace, set
`weaviate.namespace` explicitly.

## Key values
| Value | Required | Default | Notes |
|---|---|---|---|
| `gateway.endpoint` | ✅ | — | Weaviate Cloud metrics endpoint |
| `telemetry.existingSecretName` | ✅ | — | Secret holding the token |
| `telemetry.secretKey` | | `token` | key within the Secret |
| `weaviate.namespace` | | release ns | where Weaviate pods run |
| `weaviate.metricsPort` | | `2112` | Weaviate Prometheus port |
| `cluster.name` | | `""` | cosmetic only; gateway owns identity (see below) |
| `scrape.intervalSeconds` | | `30` | |
| `batch.timeoutSeconds` | | `30` | |
| `rbac.create` | | `true` | namespaced Role + RoleBinding |

**No `cluster.id` value** — the gateway derives the cluster identity from the
token server-side and ignores client-provided identity (RFC § 2.2.2). `cluster.name`
is currently a cosmetic placeholder (stripped downstream); wire it to `service.name`
if a human-readable local label is wanted.

## Known TODOs (before beta)
1. **Complete `transform/aggregate`** — the per-metric statement list is copied
   verbatim from the internal Notion config (RFC Appendix A); only representative
   examples are present here.
2. **Heartbeat metric** — `weaviate_oss_collector_heartbeat` (RFC § 2.1.3) is
   allow-listed but not yet emitted; implement (e.g. transform-rename the
   collector's own uptime metric, or a tiny dedicated pipeline).
3. **Pin image digest** and add `securityContext` / `podSecurityContext`.
4. **Decide distribution** (Q7): publish to a public Helm registry vs. fold into
   `wcs-helm-charts`.
5. **Validate against a live cluster** end-to-end (the gateway spike already proved
   the collector→gateway→Prometheus path with the equivalent config).
