Update kubeconfig `aws eks --region us-east-2 update-kubeconfig --name <cluster_name>`

Change context to specific namespace `kubectl config set-context --current --namespace=<name>`

Find availability zones (AZs) by region

```sh
  aws ec2 describe-availability-zones --region <region_name>
  aws ec2 describe-availability-zones --region <region_name> | grep ZoneName # Show only zone names
```

## Initiate infrastructure

```sh
    terraform init
    terraform apply
```

Finally! I was able to create the cluster
```sh
    Apply complete! Resources: 5 added, 0 changed, 1 destroyed.

    Outputs:

    account_id = "980135452157"
    caller_arn = "arn:aws:iam::980135452157:user/rluna-class3"
    caller_user = "AIDA6INFADX6WGQUQBXO6"
```

## Step 1: Deployment Troubleshooting
### Issue
```sh
   > kubectl logs hello-world-6464549999-wj5kb
    Ready to receive requests on 9000
    * Serving Flask app 'main' (lazy loading)
    * Environment: production
    WARNING: This is a development server. Do not use it in a production deployment.
    Use a production WSGI server instead.
    * Debug mode: off
    * Running on all addresses.
    WARNING: This is a development server. Do not use it in a production deployment.
    * Running on http://10.100.1.167:9000/ (Press CTRL+C to quit)
    Failed health check you want to ping /healthz
    10.100.1.129 - - [08/Mar/2025 17:21:39] "GET /nginx_status HTTP/1.1" 500 -
    Failed health check you want to ping /healthz
    10.100.1.129 - - [08/Mar/2025 17:21:41] "GET /nginx_status HTTP/1.1" 500 -
    Failed health check you want to ping /healthz
    10.100.1.129 - - [08/Mar/2025 17:21:43] "GET /nginx_status HTTP/1.1" 500 -    
```

### How I fixed it
I changed the path in the `livenessProve` from `/nginx_status` to `/healthz`. This is in the `Deployment`.
Fixed by running `

### Fixed

```sh
    > kubectl logs hello-world-844c8ccbb-d5tpt
    10.100.1.129 - - [08/Mar/2025 17:54:50] "GET /healthz HTTP/1.1" 200 -
    Healthy!
    10.100.1.129 - - [08/Mar/2025 17:54:52] "GET /healthz HTTP/1.1" 200 -
    Healthy!
    10.100.1.129 - - [08/Mar/2025 17:54:54] "GET /healthz HTTP/1.1" 200 -
    Healthy!
    10.100.1.129 - - [08/Mar/2025 17:54:56] "GET /healthz HTTP/1.1" 200 -
    Healthy!
    10.100.1.129 - - [08/Mar/2025 17:54:58] "GET /healthz HTTP/1.1" 200 -
    Healthy!
    10.100.1.129 - - [08/Mar/2025 17:55:00] "GET /healthz HTTP/1.1" 200 -
    Healthy!
    10.100.1.129 - - [08/Mar/2025 17:55:02] "GET /healthz HTTP/1.1" 200 -
    Healthy!
    10.100.1.129 - - [08/Mar/2025 17:55:04] "GET /healthz HTTP/1.1" 200 -
    Healthy!
    10.100.1.129 - - [08/Mar/2025 17:55:06] "GET /healthz HTTP/1.1" 200 -
    Healthy!
    10.100.1.129 - - [08/Mar/2025 17:55:08] "GET /healthz HTTP/1.1" 200 -
```

## Step 2: Canary Deployments

<!-- Pods before deploying Canary v2 -->
```sh
    > kubectl get pods
    NAME                          READY   STATUS    RESTARTS   AGE
    blue-68f654b6f9-5t8t4         1/1     Running   0          25m
    blue-68f654b6f9-6jc97         1/1     Running   0          23m
    blue-68f654b6f9-cjpl6         1/1     Running   0          25m
    canary-v1-58cb5c49d-7mxdr     1/1     Running   0          23m
    canary-v1-58cb5c49d-lx4lk     1/1     Running   0          25m
    canary-v1-58cb5c49d-mhwjv     1/1     Running   0          23m
    hello-world-844c8ccbb-xbtwq   1/1     Running   0          23m
```
<!-- Creating new Canary v2 pod -->
```sh
    > kubectl get pods
    NAME                          READY   STATUS              RESTARTS   AGE
    blue-68f654b6f9-5t8t4         1/1     Running             0          29m
    blue-68f654b6f9-6jc97         1/1     Running             0          27m
    blue-68f654b6f9-cjpl6         1/1     Running             0          29m
    canary-v1-58cb5c49d-7mxdr     1/1     Running             0          27m
    canary-v1-58cb5c49d-lx4lk     1/1     Running             0          29m
    canary-v1-58cb5c49d-mhwjv     1/1     Running             0          27m
    canary-v2-55647dff9d-jqrqp    0/1     ContainerCreating   0          7s
    hello-world-844c8ccbb-xbtwq   1/1     Running             0          27m
```

<!-- Canary v2 pods running  -->
```sh
    > kubectl get pods
    NAME                          READY   STATUS    RESTARTS   AGE
    blue-68f654b6f9-5t8t4         1/1     Running   0          62m
    blue-68f654b6f9-6jc97         1/1     Running   0          60m
    blue-68f654b6f9-cjpl6         1/1     Running   0          62m
    canary-v1-58cb5c49d-qlgbr     1/1     Running   0          16m
    canary-v1-58cb5c49d-xqr9t     1/1     Running   0          16m
    canary-v2-55647dff9d-d7jmq    1/1     Running   0          14m
    canary-v2-55647dff9d-l6rnh    1/1     Running   0          14m
    hello-world-844c8ccbb-xbtwq   1/1     Running   0          60m
```

I then had to modify starter/apps/canary/canary-svc.yml's `selector` and remove `version: "1.0"`
to ensure it gets traffic from both pods. Ohh I also too the liberty of making making the replicas
50/50 for v1 and v2.


```sh
    <html>
    <h1>This is version 1</h1>
    </html>
    debug:~# curl 172.20.76.129
    <html>
    <h1>This is version 1</h1>
    </html>
    debug:~# curl 172.20.76.129
    <html>
    <h1>This is version 1</h1>
    </html>
    debug:~# curl 172.20.76.129
    <html>
    <h1>This is version 1</h1>
    </html>
    debug:~# curl 172.20.76.129
    <html>
    <h1>This is version 2</h1>
    </html>
    debug:~# curl 172.20.76.129
    <html>
    <h1>This is version 2</h1>
    </html>
    <html>
    <h1>This is version 1</h1>
    </html>
     <html>
    <h1>This is version 1</h1>
    </html>
     <html>
    <h1>This is version 1</h1>
    </html>
     <html>
    <h1>This is version 2</h1>
    </html>
```

Result of running command canary.sh

```sh
    Startint Canary v2
    deployment.apps/canary-v2 unchanged
    Canary v2 initiated
    error: failed to create configmap: configmaps "canary-config-v2" already exists
    Configmap for version 2 created
    V1 PODS: 2
    V2 PODS: 2
    deployment.apps/canary-v2 scaled
    deployment.apps/canary-v1 scaled
    Waiting for deployment "canary-v2" rollout to finish: 2 of 4 updated replicas are available...
    Waiting for deployment "canary-v2" rollout to finish: 2 of 4 updated replicas are available...
    Waiting for deployment "canary-v2" rollout to finish: 2 of 4 updated replicas are available...
    deployment "canary-v2" successfully rolled out
    Canary deployment of 2 replicas successful!
    Canary deployment of v2 successful
```
