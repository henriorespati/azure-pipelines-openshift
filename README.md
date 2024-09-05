# README

## Azure devops agent build
```
oc new-project azure-build
oc create configmap start-sh --from-file=./assets/start.sh
oc create imagestream azure-build-agent
oc create -f ./assets/buildconfig.yaml
```

## Get the latest release from https://github.com/microsoft/azure-pipelines-agent/releases
```
oc set env bc/azure-build-agent AZP_AGENT_PACKAGE_LATEST_URL=https://vstsagentpackage.azureedge.net/agent/3.243.1/vsts-agent-linux-x64-3.243.1.tar.gz

oc create serviceaccount azure-build-sa
oc create -f ./assets/nonroot-builder.yaml
oc adm policy add-scc-to-user nonroot-builder -z azure-build-sa

oc create secret generic azdevops \
 --from-literal=AZP_URL=https://dev.azure.com/henriorespati \
 --from-literal=AZP_TOKEN=<azure-token> \
 --from-literal=AZP_POOL=test-pool

oc create -f ./assets/deployment.yaml
```

## Azure devops pipeline prerequisites
```
oc new-project ado-openshift
oc create sa azure-sa
oc adm policy add-scc-to-user anyuid -z azure-sa --as system:admin 
oc adm policy add-cluster-role-to-user cluster-admin -z azure-sa

cat <<EOF | oc apply -f - 
apiVersion: v1
kind: Secret
metadata:
  name: azure-sa-secret
  annotations: kubernetes.io/service-account.name: "azure-sa" 
  type: kubernetes.io/service-account-token
EOF
```

## Get service account token for azure devops integration
### Configure in azure devops: Home > Project > Settings > Service Connections
### 1: Docker: openshift image registry
### 2: Kubernetes: openshift api
```
oc get secrets | grep azure-sa-token | awk '{ print $1 }’
oc get secret azure-sa-token-xxxxx -o json
```

## Expose default image registry route
```
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"defaultRoute":true}}'
```
