Kuberenetes Brown Bag
=====================

Notes and code snippets for the Kuberentes Brown Bags


Learn how to:

    access Kubernetes Clusters and Namespaces using Here Account OIDC authorization
    deploy Docker containers to Kuberentes
    organize Docker containers with Pods, BatchJobs, CronJobs and Deployments
    configure Docker containers with ConfigMaps and Secrets
    expose Deployments to the Kuberentes cluster and to the HERE LAN with Services
    read container logs and gain shell access to containers
    how to design portable Docker containers so they work well on Kubernetes or any other scheduler


It is highly reccomended to go through the K8S tutorials. They are well authored and useful.
https://kubernetes.io/docs/setup/ minikube is great for learning but not much else.


Why Kuberentes ?
----------------

- Fast repeatable deployments
- NFRs like autoscaling, loadbalanacing, secrets storage log routing, metrics,
  config management are all free.
- The company has dictated 70% of processing on OLP and DP end of 2020.
- OLP has very little flexibility, DP Kuberentes has a lot of flexibility.
- Industry standard that has been hardened by 100s of big companies, and it
  makes your resume look nice.
- Fully supported by HERE. Support Jira Queue and WebEx teams channel for communtiy help.
- Multi Region.
- Much more.


Kuberenetes Role Based Authorization
------------------------------------

Kuberenetes has controls access to resources via namespaces.
  https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/

  In order to Us Delivery Plaform, which is HERE's Kuberentes based offering we
  need to:
  - Request a Kuberentes Namespace from the DP Team
  - Receive the HERE Account Credentials for the namespace
  - Setup `kubectl` on our computer and configure it correctly.

Request a Namespace from the DP team
  - Read the doc https://ipaas.int-1-aws-eu-west-1.k8s.in.here.com/static/namespace.html#requesting-a-namespace
  - File a ticket on the DPSUPP queue. Example: https://saeljira.it.here.com/browse/DPSUPP-2138
  - Setup icli to mint OIDC tokens. The easiest way to do this is using the provied Docker container.
    Required files: ipaas.config credentials.properties
    ```bash
    TOKEN=$(docker run \
        -v $HOME/.here/ipaas.config:/opt/here/ipaas.config \
        -v $HOME/.here/credentials.properties:/opt/here/credentials.properties \
        hcr.data.here.com/dp-workflow/icli:f27bb15 token)
    ```
  - Setup kubectl to access the namespace
    Required files: ~/.kube.config
    https://ipaas.int-1-aws-eu-west-1.k8s.in.here.com/static/
    ```
    kubectl --token $TOKEN --kubeconfig ~/.kube/borg-dev-1-aws-eu-west-1 \
       --namespace here-olp-3dds-dev get pods
    ```


Helpful Links:
[DP Clusters](https://confluence.in.here.com/display/OLP/Delivery+Platform%3A+Clusters)
[iPaas Documentation](https://ipaas.int-1-aws-eu-west-1.k8s.in.here.com/static/)
[kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)


Kubernetes Pods and Deployments
-------------------------------

A Pod is a collectin of Docker Containers that all share the same localhost
and are all scheduled to the same kuberentes node. File paths can also be
shared via mounts.

Helpful Links:
[K8s Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod/)

Let's create a pod with 1 container and exec to the container.

pod1.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: brownbag-pod
  labels:
    app: brownbag-pod1
spec:
  containers:
  - name: client
    image: centos:centos7
    command: ['/bin/bash', '-c', 'sleep 3600']
```

```bash
qubectl -n here-olp-3dds-dev apply -f pod1.yaml
qubectl -n here-olp-3dds-dev get pods
qubectl -n here-olp-3dds-dev get pods brownbag-pod -o yaml
qubectl -n here-olp-3dds-dev exec -it brownbag-pod /bin/bash
qubectl -n here-olp-3dds-dev describe pods brownbag-pod
qubectl -n here-olp-3dds-dev delete -f pod1.yaml
```

Let's create a pod with 2 containers and exec to the container, curl the
service and view the service container log.

pod2.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: brownbag-pod
  labels:
    app: brownbag-pod
spec:
  containers:
  - name: client
    image: centos:centos7
    command: ['/bin/bash', '-c', 'sleep 3600']
  - name: server
    image: centos:centos7
    command: ['python', '-m', 'SimpleHTTPServer']
```

```bash
qubectl -n here-olp-3dds-dev apply -f pod2.yaml
qubectl -n here-olp-3dds-dev exec -it brownbag-pod --container client /bin/bash
curl localhost:8000/
exit
qubectl -n here-olp-3dds-dev logs brownbag-pod --container server
```


BatchJobs, CronJobs and Deployments
===================================

K8s offers several options to schedule pods in different ways

- BatchJobs offer a run to completion schedule for a pod.
  https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/
- CronJobs allow run to completion at intervals defined in cron format.
  https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
- Deployments allow for pods to be used as services in a highly scalable fashion.
  They also facilitate rolling updates for pods during updates for the containers
  or the underlying server instance.
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

There are more types of ways to schedule pods documented under Controllers:
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

Lets's create a deployment and service access it via kubedns.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: brownbag-deployment
  labels:
    app: brownbag-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: brownbag-deployment
  template:
    metadata:
      labels:
        app: brownbag-deployment
    spec:
      containers:
      - name: server
        image: centos:centos7
        ports:
        - containerPort: 8000
        command: ['python', '-m', 'SimpleHTTPServer']

---

apiVersion: v1
kind: Service
metadata:
  name: brownbag-service
  labels:
    app: brownbag-service
spec:
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
  selector:
    app: brownbag-deployment
```

```bash
qubectl -n here-olp-3dds-dev apply -f deployment1.yaml
qubectl -n here-olp-3dds-dev exec -it brownbag-pod --container client /bin/bash
curl http://brownbag-service/
```

Lets's create a deployment and service and configure it with a ConfigMap and a
Secret.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app: brownbag-deployment
  name: brownbag-configmap
data:
  config.txt: k8s config

---

apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: brownbag-secret
  labels:
    app: brownbag-deployment\
data:
  secret.txt: c3VwZXIgc2VjcmV0

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: brownbag-deployment
  labels:
    app: brownbag-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: brownbag-deployment
  template:
    metadata:
      labels:
        app: brownbag-deployment
    spec:
      containers:
      - name: server
        image: centos:centos7
        ports:
        - containerPort: 8000
        command: ['python', '-m', 'SimpleHTTPServer']
        volumeMounts:
        - name: config-volume
          readOnly: true
          mountPath: /config.txt
          subPath: config.txt
        - name: secret-volume
          subPath: secret.txt
          mountPath: "/secret.txt"
          readOnly: true
      volumes:
      - name: config-volume
        configMap:
          name: brownbag-configmap
      - name: secret-volume
        secret:
          secretName: brownbag-secret

---

apiVersion: v1
kind: Service
metadata:
  name: brownbag-service
  labels:
    app: brownbag-service
spec:
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
  selector:
    app: brownbag-deployment
```

```bash
# show current pods
qubectl -n here-olp-3dds-dev get pods
qubectl -n here-olp-3dds-dev apply -f deployment1.yaml
# show updated brownbag pods
qubectl -n here-olp-3dds-dev get pods
qubectl -n here-olp-3dds-dev exec -it brownbag-pod --container client /bin/bash
curl http://brownbag-service/
qubectl -n here-olp-3dds-dev exec -it brownbag-deployment-**************** /bin/bash
ls -al *.txt
ls *.txt | xargs cat
```


Docker Container Best Practices
===============================

Docker images should be portable, composable and externally configurable.

- Log to stdout. The scheduler should decide how to route logs. If special logic
  is required to route logs that the scheduler can't handle log to stdout in the
  app and have a "sidecar" container in the pod handle logs.

  TIP: if your logger is hard to change (gasp) link the files to stdout, stderr
  like the Nginx folks did:
  ```bash
  ln -sf /dev/stdout /var/log/nginx/access.log
  ln -sf /dev/stderr /var/log/nginx/error.log
  ```

- Only 1 process per container. Each container should have only a single pid 1
  process. Process managers like systemctl or supervisor should not be used, PID
  files should not be used. The scheduler should know when a process dies.
  Multi Process Applications should be composed of seperate containers just
  like abstractions in OOP or Functional programming.

- Make you containers externally configurable. Place config files with default
  values that "just work" in idoiomatic locations, or use default Environmental
  Variables. Then use the scheduler to override those values at deplo time with
  volume mounts or injected envs

- Don't reuse image tags like 'latest' or 'SNAPSHOT'. It leads to confusion when
  things change on users without warning.

  For unreleased versions use $SEMANTIC_VERSION-$TIME_IN_SECONDS-$GIT_SHORT_HAS
  hcr.data.here.com/3dds-arch/nearmap:0.0.3-1563890798-02643ee

  For release versions use just Semantic Version
  hcr.data.here.com/3dds-arch/nearmap:0.0.3

- Never run as root. Use `nobody` instead. Nobody's home is / and it makes
  things more secure.

- Keep images small. Don't copy things you don't need. Don't leave a mess of
  build artifacts and too many layers in your images. Use the builder pattern
  to leave cruft behind in the 'builder' container.

```
FROM golang:1.11.4 as builder
WORKDIR /nearmap
COPY . .
RUN make build


FROM centos:centos7

WORKDIR /
RUN yum -y install epel-release && \
    yum -y install gdal && \
    yum -y install ImageMagick.x86_64 && \
    yum -y clean all
COPY --chown=nobody:nobody --from=builder /nearmap/nearmap .
COPY --chown=nobody:nobody shapefiles /shapefiles/
COPY --chown=nobody:nobody docker_config.yaml /config.yaml
COPY --chown=nobody:nobody missingTile.jpg /missingTile.jpg
EXPOSE 1323
USER nobody:nobody
CMD ["./nearmap"]
```

Helpful links:
https://www.docker.com/blog/intro-guide-to-dockerfile-best-practices/
