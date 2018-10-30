# k8s-update-ecr-creds
Update Kubernetes secret with latest ECR login token to avoid ImagePullBackOff issues

This requires `ecr-cred-updater` service account which can be created using below yaml
```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ecr-cred-updater
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "create", "delete"]
- apiGroups: [""]
  resources: ["serviceaccounts"]
  verbs: ["get", "patch"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ecr-cred-updater
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ecr-cred-updater
subjects:
  - kind: ServiceAccount
    name: ecr-cred-updater
roleRef:
  kind: Role
  name: ecr-cred-updater
  apiGroup: rbac.authorization.k8s.io
```
Create CronJob in Kubernetes using below yaml
```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: ecr-cred-updater
spec:
  schedule: "* */8 * * *"
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      backoffLimit: 4
      template:
        spec:
          serviceAccountName: ecr-cred-updater
          terminationGracePeriodSeconds: 0
          restartPolicy: Never
          containers:
          - name: kubectl
            image: ylonkar/k8s-update-ecr-creds
            env:
             - name: K8S_SECRET_NAME
               value: dockerimagepullsecret # <-- secret name used in imagePullSecrets
            envFrom:
              - secretRef:
                name: awscreds # <-- kubernetes secret with AWS_ACCOUNT, AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY values
```
Below are the steps executed by this job
1. It will execute [update_creds.sh](update_creds.sh) as `CMD`
1. Obtain dockertoken from ecr using values of `AWS_ACCOUNT_ID`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` environment variable 
1. Delete existing secret with name provided through value of `K8S_SECRET_NAME` environment variable
1. Create new docker-registry secret using value of `K8S_SECRET_NAME` environment variable as name
1. Patch serviceaccount default value of `imagePullSecrets`
