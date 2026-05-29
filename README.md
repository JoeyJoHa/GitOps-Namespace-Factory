# GitOps-Namespace-Factory

ArgoCD Namespace Factory for Lab.

## Prerequisites

- [ ] Container Engine (Docker/PodMan) ( for local excecution)
- [ ] OpenShift GitOps or Argo CD installed
- [ ] Git repo reachable from the cluster
- [ ] Repository registered in Argo (credentials if private)

## Setup

### Argo CD

We used Minikube with Podman and CRI-O to run ArgoCD, using the admin credentials in the default project.

We applied the `application.yaml` manifest to the cluster to achieve apps of apps approach with applicationset generator capabilities for our multi tenants.

### Additional information

A makefile to test the chart, run `make help` to see all available commands.

## Installation

