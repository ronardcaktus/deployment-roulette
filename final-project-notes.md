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

### Step 3: Blue-green deployments

Once file was created, I ran `kubectl apply -f starter/apps/blue-green/green.yml` to create green
deployment.

New `green` pods:
```sh
    > kubectl get pods
    NAME                          READY   STATUS    RESTARTS   AGE
    blue-68f654b6f9-5t8t4         1/1     Running   0          112m
    blue-68f654b6f9-6jc97         1/1     Running   0          110m
    blue-68f654b6f9-cjpl6         1/1     Running   0          112m
    canary-v2-55647dff9d-9vzxc    1/1     Running   0          17m
    canary-v2-55647dff9d-j7zxj    1/1     Running   0          30m
    canary-v2-55647dff9d-q2n64    1/1     Running   0          30m
    canary-v2-55647dff9d-txs75    1/1     Running   0          17m
    green-7f5d485fc7-8478g        1/1     Running   0          42s
    green-7f5d485fc7-8gh47        1/1     Running   0          42s
    green-7f5d485fc7-bkjcp        1/1     Running   0          42s
    hello-world-844c8ccbb-xbtwq   1/1     Running   0          110m
```

Running `terraform apply` to create a new green service and dns record

```sh
    kubernetes_service.green: Creating...
    kubernetes_service.green: Creation complete after 4s [id=udacity/green-svc]
    aws_route53_record.green: Creating...
    aws_route53_record.green: Still creating... [10s elapsed]
    aws_route53_record.green: Creation complete after 19s [id=Z03490042152Y9ZM48PV8_blue-green_CNAME_green]

    Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

    Outputs:

    account_id = "980135452157"
    caller_arn = "arn:aws:iam::980135452157:user/rluna-class3"
    caller_user = "AIDA6INFADX6WGQUQBXO6"
```

Blue and Green Configmaps
```sh
    > kubectl get configmap
    NAME               DATA   AGE
    blue-config        1      3h39m
    canary-config-v1   1      3h39m
    canary-config-v2   1      46m
    green-config       1      3h39m
    kube-root-ca.crt   1      3h45m
```

Blue and Green services
```sh
    > kubectl get svc
    NAME          TYPE           CLUSTER-IP       EXTERNAL-IP                                                                     PORT(S)        AGE
    blue-svc      LoadBalancer   172.20.29.191    aca0a640559fe43309158e4d7810541f-7d456a54b30093ce.elb.us-east-2.amazonaws.com   80:32237/TCP   3h46m
    canary-svc    ClusterIP      172.20.76.129    <none>                                                                          80/TCP         43m
    green-svc     LoadBalancer   172.20.76.17     a911d1abc4acb4a1bb0edc713becd50e-d3531e96e2f6217b.elb.us-east-2.amazonaws.com   80:32556/TCP   9m48s
    hello-world   LoadBalancer   172.20.253.189   a4a3e8746115e487ba9b736d63a5d6ca-095e1722b9366570.elb.us-east-2.amazonaws.com   80:32217/TCP   3h40m
```

#### Solution
Culring both blue and green instances via their respective load balancers

```sh
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version BLUE</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version BLUE</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version BLUE</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version BLUE</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version BLUE</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version BLUE</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version BLUE</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version BLUE</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version BLUE</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
```

Green only, after deleting blue DNS entry from Route 53

```sh
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
    [ec2-user@ip-10-100-10-110 ~]$ curl blue-green.udacityproject
    <html>
    <h1>This is version GREEN</h1>
    </html>
```

### Step 4: Node Elasticity

Deploy by running `kubectl apply -f starter/apps/bloatware/bloatware.yml`
Before even looking into it too much, I can tell there are too many instances 😅
I'll have to create a new node for this:

Some pods are in `pending` state

```sh 
    > kubectl get pods
    NAME                                 READY   STATUS    RESTARTS   AGE
    bloaty-mcbloatface-9d8f7c958-2hjmh   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-2x2lw   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-6njm5   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-6qrlb   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-b9h9x   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-llpkq   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-lpzhs   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-mmsz8   0/1     Pending   0          89s
    bloaty-mcbloatface-9d8f7c958-p26df   0/1     Pending   0          89s
    bloaty-mcbloatface-9d8f7c958-p6f9w   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-p7ph4   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-qck48   0/1     Pending   0          89s
    bloaty-mcbloatface-9d8f7c958-qn29r   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-qswvh   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-rb4j4   1/1     Running   0          89s
    bloaty-mcbloatface-9d8f7c958-rt8hz   0/1     Pending   0          89s
    bloaty-mcbloatface-9d8f7c958-vq7r8   0/1     Pending   0          89s
    blue-68f654b6f9-5t8t4                1/1     Running   0          160m
    blue-68f654b6f9-6jc97                1/1     Running   0          158m
    blue-68f654b6f9-cjpl6                1/1     Running   0          160m
    canary-v2-55647dff9d-9vzxc           1/1     Running   0          65m
    canary-v2-55647dff9d-j7zxj           1/1     Running   0          77m
    canary-v2-55647dff9d-q2n64           1/1     Running   0          77m
    canary-v2-55647dff9d-txs75           1/1     Running   0          65m
    green-7f5d485fc7-8478g               1/1     Running   0          48m
    green-7f5d485fc7-8gh47               1/1     Running   0          48m
    green-7f5d485fc7-bkjcp               1/1     Running   0          48m
    hello-world-844c8ccbb-xbtwq          1/1     Running   0          158m
```

The reason is insufficient CPU

```sh
    > kubectl describe pod bloaty-mcbloatface-9d8f7c958-rt8hz -n udacity
    Events:
    Type     Reason            Age    From               Message
    ----     ------            ----   ----               -------
    Warning  FailedScheduling  4m46s  default-scheduler  0/2 nodes are available: 2 Insufficient cpu. preemption: 0/2 nodes are available: 2 No preemption victims found for incoming pod.
```

I spun up a new node

```sh
    > kubectl get nodes
    NAME                                         STATUS     ROLES    AGE    VERSION
    ip-10-100-1-44.us-east-2.compute.internal    Ready      <none>   170m   v1.31.5-eks-5d632ec
    ip-10-100-2-9.us-east-2.compute.internal     NotReady   <none>   19s    v1.31.5-eks-5d632ec
    ip-10-100-3-145.us-east-2.compute.internal   Ready      <none>   172m   v1.31.5-eks-5d632ec

    Ready

    > kubectl get nodes
    NAME                                         STATUS   ROLES    AGE    VERSION
    ip-10-100-1-44.us-east-2.compute.internal    Ready    <none>   171m   v1.31.5-eks-5d632ec
    ip-10-100-2-9.us-east-2.compute.internal     Ready    <none>   59s    v1.31.5-eks-5d632ec
    ip-10-100-3-145.us-east-2.compute.internal   Ready    <none>   173m   v1.31.5-eks-5d632ec
```

#### Solution

After spinning up the new node, everything us running

```sh
    > kubectl get pods --all-namespaces
    NAMESPACE     NAME                                 READY   STATUS    RESTARTS   AGE
    kube-system   aws-node-kxcb4                       2/2     Running   0          96s
    kube-system   aws-node-v2w99                       2/2     Running   0          172m
    kube-system   aws-node-zwhp8                       2/2     Running   0          174m
    kube-system   coredns-6b94694fcb-7mh2x             1/1     Running   0          168m
    kube-system   coredns-6b94694fcb-qhk8p             1/1     Running   0          168m
    kube-system   kube-proxy-cmd75                     1/1     Running   0          174m
    kube-system   kube-proxy-mn4w6                     1/1     Running   0          172m
    kube-system   kube-proxy-r5vv4                     1/1     Running   0          96s
    udacity       bloaty-mcbloatface-9d8f7c958-2hjmh   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-2x2lw   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-6njm5   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-6qrlb   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-b9h9x   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-llpkq   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-lpzhs   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-mmsz8   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-p26df   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-p6f9w   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-p7ph4   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-qck48   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-qn29r   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-qswvh   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-rb4j4   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-rt8hz   1/1     Running   0          15m
    udacity       bloaty-mcbloatface-9d8f7c958-vq7r8   1/1     Running   0          15m
    udacity       blue-68f654b6f9-5t8t4                1/1     Running   0          174m
    udacity       blue-68f654b6f9-6jc97                1/1     Running   0          172m
    udacity       blue-68f654b6f9-cjpl6                1/1     Running   0          174m
    udacity       canary-v2-55647dff9d-9vzxc           1/1     Running   0          79m
    udacity       canary-v2-55647dff9d-j7zxj           1/1     Running   0          91m
    udacity       canary-v2-55647dff9d-q2n64           1/1     Running   0          91m
    udacity       canary-v2-55647dff9d-txs75           1/1     Running   0          79m
    udacity       green-7f5d485fc7-8478g               1/1     Running   0          62m
    udacity       green-7f5d485fc7-8gh47               1/1     Running   0          62m
    udacity       green-7f5d485fc7-bkjcp               1/1     Running   0          62m
    udacity       hello-world-844c8ccbb-xbtwq          1/1     Running   0          172m
```