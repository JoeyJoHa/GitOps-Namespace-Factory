# GitOps Namespace Factory

A lab project that provisions tenant namespaces on Kubernetes.

## Demos

Helm:
[![asciicast](https://asciinema.org/a/8AvePqhqBtyS3cDY.svg)](https://asciinema.org/a/8AvePqhqBtyS3cDY)

Minikube Bootstrap:
[![asciicast](https://asciinema.org/a/u82n7vDqHKj3ZDTc.svg)](https://asciinema.org/a/u82n7vDqHKj3ZDTc)

ArgoCD Objects:
[![asciicast](https://asciinema.org/a/6HsV3nbQDCFWlDhA.svg)](https://asciinema.org/a/6HsV3nbQDCFWlDhA)

## Repository layout

```tree
GitOps-Namespace-Factory/
├── Makefile                              # Local validation + Minikube demo bootstrap
├── README.md
├── argocd/
│   ├── appproject.yaml                   # platform-apps AppProject
│   ├── application.yaml                  # factory-apps — app-of-apps for argocd/apps/
│   └── apps/
│       └── namespace-factory/
│           └── applicationset.yaml
├── helm/
│   └── nsfactory/                        # Namespace factory Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── namespace.yaml
│           ├── limitrange.yaml
│           ├── resourcequota.yaml
│           ├── rolebindings.yaml
│           └── appproject.yaml
└── tenants/
    ├── values.yaml.example               # Template for new tenants
    ├── values-team-a-dev.yaml
    ├── values-team-b-qa.yaml
    └── values-team-rh.yaml
```

## Prerequisites

- Container engine: Docker or Podman (for Minikube)
- CLI tools: `kubectl`, `helm`, `minikube`, `make`
- Git repo reachable from the cluster (update `repoURL` in Argo manifests if you fork this repo)
- For a private repo: register credentials in Argo CD

Default Minikube settings in the Makefile: driver `podman`, runtime `cri-o`, 2 CPUs, 7 GiB memory. Override with environment variables, for example `make cluster-start DRIVER=docker RUNTIME=docker`.

## Validate the Helm chart locally

### Lint

```bash
# Chart structure and default values only
make lint-chart

# Chart + every tenant values file under tenants/values-*.yaml
make lint-values
```

### Render (template)

```bash
# One tenant — pass the filename only (not the full path)
make template TENANT=values-team-a-dev.yaml

# All tenant value files (output discarded; fails on first error)
make template-all
```

Equivalent raw Helm commands:

```bash
helm lint helm/nsfactory
helm lint helm/nsfactory -f tenants/values-team-a-dev.yaml
helm template nsfactory helm/nsfactory -f tenants/values-team-a-dev.yaml
```

### Tenant values shape

Copy `tenants/values.yaml.example` when adding a tenant. Required fields:

```yaml
owner: team-a
environment: dev
resources:
  quota: { ... }
  limits: { ... }
rbac:
  adminGroup: team-a-admins   # optional
  viewGroup: team-a-viewers   # optional
```

Namespace name defaults to `{owner}-{environment}` unless you set `namespace:` explicitly.

## Run the local demo

The Makefile bootstraps Minikube, installs Argo CD, applies the platform AppProject, and registers the factory app-of-apps.

```bash
# Start cluster, install Argo CD, deploy platform project + factory-apps
make demo-start

# In a second terminal: show admin password and port-forward the UI
make access-argo
# Open http://localhost:8080 (user: admin)
```

After sync completes in the Argo CD UI you should see:

- `factory-apps` — syncs `argocd/apps/` (includes the ApplicationSet)
- `namespace-factory` — ApplicationSet
- One Application per `tenants/values-*.yaml` (for example `team-a-dev`)

Each tenant Application deploys into its target namespace the resources from `helm/nsfactory`.

### Stop or reset the demo

```bash
make demo-stop      # stop and delete the Minikube cluster
make cluster-stop   # stop Minikube without deleting
make cluster-delete # delete the cluster only
```

### Other useful cluster targets

```bash
make help            # list all Makefile targets
make cluster-status  # Minikube status
```

## Makefile reference

| Target | Description |
| -------- | ------------- |
| `help` | List available commands |
| `lint-chart` | `helm lint` with chart defaults |
| `lint-values` | `helm lint` for each `tenants/values-*.yaml` |
| `template TENANT=...` | Render one tenant values file |
| `template-all` | Render all tenant values files |
| `cluster-start` / `cluster-stop` / `cluster-delete` / `cluster-status` | Minikube lifecycle |
| `deploy-argo` | Install Argo CD into `argocd` namespace |
| `deploy-appproject` | Apply `argocd/appproject.yaml` |
| `deploy-application` | Apply `argocd/application.yaml` (factory-apps) |
| `access-argo` | Print admin password and port-forward UI to `:8080` |
| `demo-start` | `cluster-start` + Argo CD + appproject + application |
| `demo-stop` | Stop and delete the Minikube cluster |

## Adding a tenant

1. Copy `tenants/values.yaml.example` to `tenants/values-<owner>-<env>.yaml`.
2. Fill in `owner`, `environment`, `resources`, and optional `rbac` groups.
3. Validate locally: `make lint-values` and `make template TENANT=values-<owner>-<env>.yaml`.
4. Commit and push; the ApplicationSet picks up new `tenants/values-*.yaml` files on the configured Git revision.

If you use a fork, update `repoURL` (and optionally `targetRevision`) in:

- `argocd/application.yaml`
- `argocd/apps/namespace-factory/applicationset.yaml`
- `argocd/appproject.yaml` (`sourceRepos`)
