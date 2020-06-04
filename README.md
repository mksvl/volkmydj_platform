### volkmydj_platform
volkmydj Platform repository

# kubernetes-intro. HW-1

1. Установлен kubectl.
2. Установлен minikube.
3. Настроено автодополнение для zsh.
4. Рассмотрена установка кластера через kind. \
   4.1. Предварительно создаем в домашней директории пользователя файл конфигурации kind-config.yaml следующего содержания:
   ```
   kind: Cluster
   apiVersion: kind.sigs.k8s.io/v1alpha3
   nodes:
     - role: control-plane
     - role: control-plane
     - role: control-plane
     - role: worker
     - role: worker
     - role: worker
  ```
   4.2. Поднимаем кластер следущей командой:
   ```
  kind create cluster --config ~/kind-config.yaml
   ```
5. Установлена утилита визуализации консольной работы с кластером k9s. Рассмотрены команды управления.
6. Получены результаты при убитии всех pods в namespace kube-system.
  6.1. Системные поды мониторятся агентом kubelet.
  6.2. Если в манифестах поды описаны как объекты типа Deployments, то данные поды автоматически восстанавливаться до необходимого кол-ва.
7. Создан Dockerfile с описанием образа вэб-сервера.
8. Создана простейшая html страница, которая размещается в папке /app.
9. Поднят контейнер с вэб-сервером и проверена его работа. Образ запушен в личный docker registry.
10. Создан манифест для поднятия пода вэб-сервера в кластер.
11. Добавлен init container в манфест пода.
12. Создан образ фронтенда приложения hipster-shop.
    В процесе поднятия пода приложения обнаружилась ошибка. Команда kubectl logs frontend показала следующее:
```go
    panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set \
goroutine 1 [running]: \
main.mustMapEnv(0xc00039c000, 0xb03c4a, 0x1c) \
        /go/src/github.com/GoogleCloudPlatform/microservices-demo/src/frontend/main.go:248 +0x10e \
main.main() \
        /go/src/github.com/GoogleCloudPlatform/microservices-demo/src/frontend/main.go:106 +0x3e9
```

Изучив файл main.go стало понятно, что не хватает переменной, а позднее выяснилось, что нехватает нескольких переменных.

13. Создан манифест frontend-pod-healthy.yaml поднятия фронтенда с учетом недостающих параметров.


# kubernetes-controllers.HW#2

1. Создал кластер kind.
2. Создал манифест для запуска одной реплики приложения frontend. При запуске ожидаемо получил ошибку. Ошибка заключалась в том, что в коде манифеста не было важной части кода, а именно:

```yaml
  selector:
    matchLabels:
      app: frontend
```

4. Обновление ReplicaSet не повлекло за собой обновление pod. Этого не произошло по следующим причинам:

- ReplicaSet не проверяет соответствие запущенных подов шаблону;
 - ReplicaSet не умеет рестартовать запущенные поды при обновлении шаблона

5. Собрал образ для сервиса paymentservice и запушил две версии в docker hub.

6. Создал манивест для запуска 3-х реплик сервиса paymentservice версии 0.0.1
7. Создал деплоймент на основании манифеста реплики сервиса paymentservice и запустил его.
8. Обновил деплоймент до версии 0.0.2.

9. Сделал RollBack деплоймента до версии 0.0.1.

10. Создал два манифеста с технологией обновления микросервисов: аналог blue-green и reverse rolling update.

11. На основании микросервиса frontend реализовал механизм проверки работоспособности приложения при помощи probes.

12. Создал манифест DaemonSet для экспортера Node Exporter.

13. Манифест NodeExporter модернизировал так,чтобы Node Exporter разворачивался как на worker нодах, так и на master нодах. Это реализуется в следующей секции манифеста:

```yaml
      tolerations:
        - operator: "Exists"
````
Пустой `key` с оператором `Exists` соответствует всем ключам, значениям и эффектам, что означает, что это допустимо ко всему кластеру.

# kubernetes-security.HW#3

1. Создан сервисный аккаунт bob.
2. Аккаунту bob назначена роль администратора в рамках всего кластера.

3. Создан сервисный аккаунт dave.

4. Аккаунт dave не имеет доступ к кластеру.

5. Создан namespace prometheus.

6. Создан сервисный аккаунт в namespace prometheus.

7. Всем сервисным аккаунтам в namespace prometheus предоставлена возможность делать get, list, watch в отношении Pods всего кластера.

8. Создан Namespace dev.

9. Создан сервисный аккаунт jane в Namespace dev.

10. Сервисному аккаунту jane предоставлена роль admin (edit) в рамках Namespace dev.

11. Создан Service Account ken в Namespace dev.

12. Сервисному аккаунту ken предоставлена роль view в рамках Namespace dev.



# kubernetes-controllers.HW#4

### Основное ДЗ.

1. Поднял minikube: \
`minikube start`

2. Добавил `readinessProbe`

```yaml
readinessProbe:
  httpGet:
    path: /index.html
    port: 80
````

3. Задеплоил под из предыдущего задания:\
`kubectl apply -f kubernetes-intro/web-pod.yaml`
pod/web created

4. Проверил, что под запустился:\
`kubectl get pod/web`
```
NAME   READY   STATUS    RESTARTS   AGE
web    0/1     Running   0          7m43s
```

5. Просмотрел более подробную информацию по поду:\
`kubectl describe pod/web`
```
Conditions:
  Type              Status
  Initialized       True
  Ready             False
  ContainersReady   False
  PodScheduled      True
````
````
Warning  Unhealthy  48s (x60 over 10m)  kubelet, minikube  Readiness probe failed: Get http://172.17.0.3:80/index.html: dial tcp 172.17.0.3:80: connect: connection refused
````
По итогу под не запустился.

6. Добавил проверку `livenessProbe`:

```yaml
livenessProbe:
  tcpSocket: { port: 8000 }
````

7. Запустил под с новой конфигурацией:
`kubectl apply -f kubernetes-intro/web-pod.yaml --force`

Проверил:\
`Liveness:       tcp-socket :8000 delay=0s timeout=1s period=10s #success=1 #failure=3`

8. Cледующая конфигурация валидна, но не имеет смысла по следующей причине:

```yaml
livenessProbe:
  exec:
    command:
      - 'sh'
      - '-c'
      - 'ps aux | grep my_web_server_process'
````
Похожая конфигурация прописана ниже в init контейнере.
Данная конфигурация имеет смысл, если мы не используем init контейнер.

9. Создал деплоймент приложения web и применил его, предварительно удалив предыдущий под:\
`kubectl apply -f web-deploy.yaml`

Результат:
```
Name:                   web
Namespace:              default
CreationTimestamp:      Wed, 20 May 2020 23:12:12 +0300
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 1
                        kubectl.kubernetes.io/last-applied-configuration:
                          {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"name":"web","namespace":"default"},"spec":{"replicas":1,"selecto...
Selector:               app=web
Replicas:               1 desired | 1 updated | 1 total | 0 available | 1 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=web
  Init Containers:
   html-gen:
    Image:      busybox:musl
    Port:       <none>
    Host Port:  <none>
    Command:
      sh
      -c
      wget -O- https://bit.ly/otus-k8s-index-gen | sh
    Environment:  <none>
    Mounts:
      /app from app (rw)
  Containers:
   web:
    Image:        volkmydj/web:1.0
    Port:         <none>
    Host Port:    <none>
    Liveness:     tcp-socket :8000 delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get http://:8000/index.html delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:
      /app from app (rw)
  Volumes:
   app:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
    SizeLimit:  <unset>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      False   MinimumReplicasUnavailable
  Progressing    True    ReplicaSetUpdated
OldReplicaSets:  <none>
NewReplicaSet:   web-7cd5754fd8 (1/1 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  49s   deployment-controller  Scaled up replica set web-7cd5754fd8 to 1
````


10. Увеличил кол-во реплик до 3-х и применил деплоймент:

11. Добавил стратегию обновления:

```yaml
strategy:
  type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 100%
````

11. Испробывал разные стратегии обновления:
 - maxSurge=0 и maxUnavailable=0:
 `The Deployment "web" is invalid: spec.strategy.rollingUpdate.maxUnavailable: Invalid value: intstr.IntOrString{Type:0, IntVal:0, StrVal:""}: may not be 0 when `maxSurge` is 0`

 - maxSurge=100% и maxUnavailable=100%:\
 `ROLLOUT STATUS:
  - [Current rollout | Revision 2] [MODIFIED]  default/web-76c54c8f4f    ✅ ReplicaSet is available [3 Pods available of a 3 minimum]
       - [Ready] web-76c54c8f4f-rknr2
       - [Ready] web-76c54c8f4f-2xkj7
       - [Ready] web-76c54c8f4f-m5cnh`

 - maxSurge=0 и maxUnavailable=100%:\

 ```
ROLLOUT STATUS:
- [Current rollout | Revision 3] [MODIFIED]  default/web-7cd5754fd8    ⌛ Waiting for ReplicaSet to attain minimum available Pods (2 available of a 3 minimum)
- [ContainersNotReady] web-7cd5754fd8-8r6w8 containers with unready status: [web]
- [Ready] web-7cd5754fd8-pqfvd
- [Ready] web-7cd5754fd8-d42dq- [Previous ReplicaSet | Revision 2] [MODIFIED]  default/web-76c54c8f4f
    ⌛ Waiting for ReplicaSet to scale to 0 Pods (1 currently exist)
       - [Ready] web-76c54c8f4f-2xkj7
       - [Ready] web-76c54c8f4f-m5cnh
       - [Ready] web-76c54c8f4f-rknr2
```

11. Создал Service ClusterIP и применил его:
`kubectl apply -f web-svc-cip.yaml`\
`kubectl get services`
```
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
web-svc-cip   ClusterIP   10.111.64.39     <none>        80/TCP           20s
````

12. Зашел на minikube для проверки сервиса `minikube ssh` и сделал проверку `curl http://10.111.64.39/index.html`. Работает, но в тоже время `ping 10.111.64.39` не работает.

13. Прпроверил правила iptables:

`iptables --list -nv -t nat`

```
1    60 KUBE-SVC-WKCOG6KH24K26XRJ  tcp  --  *      *       0.0.0.0/0            10.111.64.39         /* default/web-svc-cip: cluster IP */ tcp dpt:80
````

14. Включил IPVS  для `kube-proxy`:\
`ipvsadm --list -n`

```
TCP  10.111.64.39:80 rr
```
Пингуем его:\
`ping -c1 10.111.64.39`
````
PING 10.111.64.39 (10.111.64.39): 56 data bytes
64 bytes from 10.111.64.39: seq=0 ttl=64 time=0.095 ms

--- 10.111.64.39 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.095/0.095/0.095 ms
`````
15. Установил манифест MetalLB:\
`kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.0/manifests/metallb.yaml`

Примечание: С версией манифеста 0.8.0 возникли проблемы. Я использовал версию 0.8.1

Проверяем:\
`kubectl --namespace metallb-system get all`
````
NAME                              READY   STATUS    RESTARTS   AGE
pod/controller-5df86965f5-kx969   1/1     Running   0          112s
pod/speaker-s6vsx                 1/1     Running   0          112s



NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
daemonset.apps/speaker   1         1         1       1            1           beta.kubernetes.io/os=linux   112s

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/controller   1/1     1            1           112s

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/controller-5df86965f5   1         1         1       112s
`````

16. Создал манифест `metallb-config.yaml`. В нем определил следующие параметры:

 - Режим L2 (анонс адресов балансировщиков с помощью ARP)
 - Создаем пул адресов 172.17.255.1-172.17.255.255 - они будут назначаться сервисам с типом `LoadBalancer`

17. Создал манифест сервиса `web-svc-lb.yaml` и применил его:\
`kubectl --namespace metallb-system logs pod/controller-5df86965f5-kx969`
````
{"caller":"service.go:98","event":"ipAllocated","ip":"172.17.255.1","msg":"IP address assigned by controller","service":"default/web-svc-lb","ts":"2020-05-21T14:29:04.239966026Z"}
`````

18. Добавил маршрут до сети в minikube:\

`sudo route add 172.17.255.0/24 192.168.64.3`

Заходим по адрессу http://172.17.255.1/index.html и видим стратовую страницу приложения.

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml

19. Создал Ingress. Т.к. команда:\

 `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml`

 вернула в ответ 404, то Ingress для mikube был активирован командой: `minikube addons enable
ingress`

20. Создал манивест `nginx-lb.yaml`
Проверяем командой: `http://<load-balancer-ip>/index.html`

21. Создал и применил манифест `web-svc-headless.yaml`.
Проверяем, что полученный манифест на получил `ClusterIP`:
`kubectl get service`
````
NAME          TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)        AGE
kubernetes    ClusterIP      10.96.0.1        <none>         443/TCP        96m
web-svc       ClusterIP      None             <none>         80/TCP         80s
web-svc-cip   ClusterIP      10.102.222.121   <none>         80/TCP         95m
web-svc-lb    LoadBalancer   10.103.113.210   172.17.255.1   80:32762/TCP   64m
`````

22. Настроил ingress-прокси, создав манифест с ресурсом `Ingress`. Манифест `web-ingress.yaml`.
Проверяем, что все правильно:

`kubectl describe ingress/web`

````
Name:             web
Namespace:        default
Address:          172.17.255.2
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host  Path  Backends
  ----  ----  --------
  *
        /web   web-svc:8000 (172.17.0.4:8000,172.17.0.5:8000,172.17.0.6:8000)
Annotations:
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"networking.k8s.io/v1beta1","kind":"Ingress","metadata":{"annotations":{"nginx.ingress.kubernetes.io/rewrite-target":"/"},"name":"web","namespace":"default"},"spec":{"rules":[{"http":{"paths":[{"backend":{"serviceName":"web-svc","servicePort":8000},"path":"/web"}]}}]}}

  nginx.ingress.kubernetes.io/rewrite-target:  /
Events:                                        <none>
````
Проверяем, что страница доступна в брауезере:

`http://<LB_IP>/web/index.html`


## ДЗ со *.

1. Сделал сервис LoadBalancer , который открывает доступ к CoreDNS снаружи кластера.
Манифест `metallb-config-coredns.yaml`.\
Если есть необходимость группировать службы на одном IP-адресе, можно включить выборочное разделение IP-адресов, добавив к службам аннотацию metallb `universe.tf/allow-shared-ip.`\
Подробнее описано в документации: https://metallb.universe.tf/usage/#ip-address-sharing

Находим нужные поды службы:

`kubectl get pods -n kube-system`

````
NAME                               READY   STATUS    RESTARTS   AGE
coredns-66bff467f8-h72g8           1/1     Running   0          27h
coredns-66bff467f8-h7vmw           1/1     Running   0          27h
````
Смотрим Labels:

`kubectl describe pods coredns-66bff467f8-h72g8 -n kube-system`

```
me:                 coredns-66bff467f8-h72g8
Namespace:            kube-system
Priority:             2000000000
Priority Class Name:  system-cluster-critical
Node:                 minikube/192.168.64.3
Start Time:           Thu, 21 May 2020 16:57:13 +0300
Labels:               k8s-app=kube-dns
````
k8s-app=kube-dns

Создаем манифест сервиса по типу LoadBalancer. В качестве селектора задаем:

```yaml
selector:
    k8s-app: kube-dns
````
Также в манифесте указываем порты TCP и UDP.\
Применяем манифест и проверяем:

`nslookup kubernetes.default.svc.cluster.local. 172.17.255.10`

````
Server:         172.17.255.10
Address:        172.17.255.10#53

Name:   kubernetes.default.svc.cluster.local
Address: 10.96.0.1
````

2. Добавил доступ к kubernetes-dashboard через Ingress-прокси. Манифест `dashboard-ingress.yaml`.\
***Скажу честно, у меня не заработал. Но судя по документации должен был...

`kubectl describe ingress kubernetes-dashboard  --namespace kube-system`

````
Name:             kubernetes-dashboard
Namespace:        kube-system
Address:          172.17.255.2
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host  Path  Backends
  ----  ----  --------
  *
        /dashboard/(.*)   kubernetes-dashboard:80 (<none>)
Annotations:
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"networking.k8s.io/v1beta1","kind":"Ingress","metadata":{"annotations":{"nginx.ingress.kubernetes.io/rewrite-target":"/$1"},"name":"kubernetes-dashboard","namespace":"kube-system"},"spec":{"rules":[{"http":{"paths":[{"backend":{"serviceName":"kubernetes-dashboard","servicePort":80},"path":"/dashboard/(.*)"}]}}]}}

  nginx.ingress.kubernetes.io/rewrite-target:  /$1
Events:
  Type    Reason  Age                  From                      Message
  ----    ------  ----                 ----                      -------
  Normal  UPDATE  12s (x2 over 7h56m)  nginx-ingress-controller  Ingress kube-system/kubernetes-dashboard
  ````
По адрессу `http://172.17.255.2/dashboard/` получаю:

````
503 Service Temporarily Unavailable

nginx/1.17.8
````

3. Реализованно канареечное развертывание с помощью
ingress-nginx.

 - Создаем production namespace для проекта:\
 `kubectl apply -f echo-production-ns.yaml`

 - Разворачиваем приложение. Для этого используем пример из репозитория Kubernetes. Разворачиваем тестовый echo-сервер в созданном namespace:

 `kubectl apply -f http-svc.yaml -n echo-production`

 - Создаем файл конфигурации Ingress и применяем его к namespace echo-production:

 `kubectl apply -f http-svc-ingress.yaml -n echo-production`

 В результате сервер будет реагировать на все запросы от хоста echo.com.

 - Создаем Canary-версию namespace приложения:

 `kubectl apply -f echo-canary-ns.yaml`

 - Разворачиваем Canary-версию приложения:

 `kubectl apply -f http-svc.yaml -n echo-canary`

 - Создаем Canary-версию файла конфигурации Ingress и применяем его к namespace echo-canary:

 `kubectl apply -f http-svc-ingress-canary.yaml -n echo-canary`

 Примечание:

 ````
nginx.ingress.kubernetes.io/canary: "true" означает, что Kubernetes не будет рассматривать этот Ingress как самостоятельный и пометит его как Canary, связав с основным Ingress;

nginx.ingress.kubernetes.io/canary-weight: "10" означает, что на Canary будет приходиться примерно 50% всех запросов
````

- Проверку, что запросы распределяются в соответствии с  конфигурационным файлом реализована через скрипт на Ruby:

````ruby
counts = Hash.new(0)
1000.times do
  output = `curl -s -H "Host: echo.com" http://172.17.255.2 | grep 'pod namespace'`
  counts[output.strip.split.last] += 1
end
puts counts
````
(Скрипт не мой, а честно найден на просторах интернета)

В результате вывод будет примерно такой:

````
{"echo-canary"=>509, "echo-prod"=>491}
`````

# kubernetes-volumes.HW#5

1. Установил `kind`:

`kind create cluster --config ~/kind-config.yaml`

2. Развернул StatefulSet c MinIO:

`kubectl apply -f minio-statefulset.yaml`
````
NAME      READY   STATUS    RESTARTS   AGE
minio-0   1/1     Running   0          13m
````


3. Для того, чтобы наш StatefulSet был доступен изнутри кластера, создал Headless Service и задеплоил:

`kubectl apply -f minio-statefulset.yaml`

## Задание со *.

Данные в StatefulSet передаются в открытом виде. Нужно это исправить.

1. Кодируем `MINIO_ACCESS_KEY`и `MINIO_SECRET_KEY` в формат base64:

`echo -n 'minio' | base64`

bWluaW8=

`echo -n 'minio123' | base64`

bWluaW8xMjM=

2. Создаем манифест Secret с полученными данными и применяем его:

`kubectl apply -f minio-secret.yaml`

3. Правим манифест StateFullSet:

```yaml
    spec:
      containers:
        - name: minio
          envFrom:
            - secretRef:
                name: minio-secret
````

4. Применяем манифест и проверяем, что изменения применились:

`kubectl describe pod minio-0`

````
Name:           minio-0
Namespace:      default
Priority:       0
Node:           kind-worker/172.18.0.3
Start Time:     Sun, 24 May 2020 13:43:29 +0300
Labels:         app=minio
                controller-revision-hash=minio-f997965b5
                statefulset.kubernetes.io/pod-name=minio-0
Annotations:    <none>
Status:         Running
IP:             10.244.5.6
Controlled By:  StatefulSet/minio
Containers:
  minio:
    Container ID:  containerd://76f7a72c4ee6a215cf85748e98a9999f51e4edd863ec7cc1cd4a7cbcd4894e09
    Image:         minio/minio:RELEASE.2019-07-10T00-34-56Z
    Image ID:      docker.io/minio/minio@sha256:ccdbb297318f763dc1110d5168c8d45863c98ff1f0d7095a90be3b31a150ac6f
    Port:          9000/TCP
    Host Port:     0/TCP
    Args:
      server
      /data
    State:          Running
      Started:      Sun, 24 May 2020 13:43:30 +0300
    Ready:          True
    Restart Count:  0
    Liveness:       http-get http://:9000/minio/health/live delay=120s timeout=1s period=20s #success=1 #failure=3
    Environment Variables from:
      minio-secret  Secret  Optional: false
````


## kubernetes-templating

1. Поднял кластер в GCP, спомощью `terraform`

`terraform init`

`terraform apply`

````
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
````

2. Настроил kubectl на локальной машине:

`gcloud container clusters get-credentials my-gke-cluster --region europe-west4-a --project otus-kuber-278507`

````
Fetching cluster endpoint and auth data.
kubeconfig entry generated for my-gke-cluster.
````

 3. Добавил репозиторий stable:

`helm repo add stable https://kubernetes-charts.storage.googleapis.com`

`helm repo list`

````
NAME            URL
gitlab          https://charts.gitlab.io
nginx-stable    https://helm.nginx.com/stable
incubator       http://storage.googleapis.com/kubernetes-charts-incubator
stable          https://kubernetes-charts.storage.googleapis.com
````

4. Создал namespace и release nginx-ingress:

`kubectl create ns nginx-ingress`

````
helm upgrade --install nginx-ingress stable/nginx-ingress --wait \
--namespace=nginx-ingress \
--version=1.11.1
````

````yaml
NAME: nginx-ingress
LAST DEPLOYED: Wed May 27 19:07:48 2020
NAMESPACE: nginx-ingress
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The nginx-ingress controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace nginx-ingress get services -o wide -w nginx-ingress-controller'

An example Ingress that makes use of the controller:

  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    annotations:
      kubernetes.io/ingress.class: nginx
    name: example
    namespace: foo
  spec:
    rules:
      - host: www.example.com
        http:
          paths:
            - backend:
                serviceName: exampleService
                servicePort: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
        - hosts:
            - www.example.com
          secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
````


5. Добавил репозиторий, в котором хранится актуальный helm chart cert-manager:

`helm repo add jetstack https://charts.jetstack.io`

6. Создал в кластере некоторые CRD:

`kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.crds.yaml`

````
customresourcedefinition.apiextensions.k8s.io/certificates.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/certificaterequests.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/challenges.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/clusterissuers.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/issuers.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/orders.certmanager.k8s.io created
````
Еще одна подготовка:

`kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"`

7. Установил cert-manager:

`helm ugrade --install cert-manager jetstack/cert-manager --namespace cert-manager --version v0.15.0`

````
Release "cert-manager" does not exist. Installing it now.
NAME: cert-manager
LAST DEPLOYED: Wed May 27 19:35:17 2020
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://docs.cert-manager.io/en/latest/reference/issuers.html

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://docs.cert-manager.io/en/latest/reference/ingress-shim.html
````

Для cert-manager также необходимо создать namespace cert-manager. Добавил манифест создания namespace.

Также необходимо создать `ClusterIssuer`. Подробное описание можно найти здесь:

<https://cert-manager.io/docs/configuration/>

Создал ACME Issuer для создания сертификатов Letsencrypt.

9. Кастомизировал установку chartmuseum

````
helm upgrade --install chartmuseum stable/chartmuseum \
--wait --namespace=chartmuseum --version=2.3.2 \
-f kubernetes-templating/chartmuseum/values.yaml
````

Проверим, что release chartmuseum установился:

`helm ls -n chartmuseum`

````
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
chartmuseum     chartmuseum     8               2020-05-29 02:16:14.744343 +0300 MSK    deployed        chartmuseum-2.3.2       0.8.2
````

10. Установил `Harbor`:

````
helm upgrade --install harbor-release harbor/harbor \
--wait --namespace=harbor --version=1.1.2 \
-f kubernetes-templating/harbor/values.yaml
````

11. Инициализировал средствами helm структуру директории с содержимым будущего helm chart:

`helm create kubernetes-templating/hipster-shop`

12. Перенес файл `all-hipster-shop.yaml` в директорию templates.

13. Задеплоил чарт:

````
kubectl create ns hipster-shop
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
````

14. Отделил `frontend` от всего приложения:

`helm create kubernetes-templating/frontend`

15. В директории templates чарта frontend создал файлы:

 - deployment.yaml (содержить соответствующую часть из файла all-hipster-shop.yaml)
 - service.yaml (содержить соответствующую часть из файла all-hipster-shop.yaml)
 - ingress.yaml (разворачивает ingress с доменным именем shop.34.91.63.42.nip.io)

16. Установил chart `frontend` в namespace `hipster-shop`:

`helm upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop`

17. Шаблонизировал chart `frontend`.

18. Добавил chart frontend как зависимость:

```yaml
dependencies:
- name: frontend
  version: 0.1.0
  repository: "file://../frontend"
````

19. Обновил зависимости:

`helm dep update kubernetes-templating/hipster-shop`

20. Изменил NodePort для frontend в release, не меняя его в самом chart:

````
helm upgrade --install hipster-shop \ kubernetes-templating/hipster-shop \
--namespace hipster-shop \
--set frontend.service.NodePort=31234
````

21. Установил плагин для работы c `helm-secret`:

````
brew install sops
brew install gnupg2
brew install gnu-getopt
helm plugin install https://github.com/futuresimple/helm-secrets --version 2.0.2
````

22. Сгенерировал ключи:

`g --full-generate-key`

23. Создал `secrets.yaml` в директории `kubernetes- templating/frontend`` и зашифровал его:

`sops -e -i --pgp <$ID> secrets.yaml`

Содержание изменилось:

```yaml
visibleKey: ENC[AES256_GCM,data:yIsTDNosywhsw8M=,iv:y+2MIMp0rnmdiUz4XJdRccgHQ8jxmWmJxJUdP9cERWY=,tag:Jj7iNNO1IKqKNE/5pO+beg==,type:str]
sops:
    kms: []
    gcp_kms: []
    azure_kv: []
    lastmodified: '2020-06-01T10:56:42Z'
    mac: ENC[AES256_GCM,data:awAyeNNDfHguoH0nnRxDbYOqknY6qxI2aJvyormjTc+dssCLBdR5yLzuTOhrweLB3OkNBb6CTVmURQGokcfJRNTHYC9FDh6+XzRrMsjApMJF0a1QN8R15vcH2MvlNavxPTt2RiEAz7x+nc+zTCZJDzt4zAWyGW1Xkg9MEYHx7eM=,iv:poJiYpZfzExTAPXxGPne+zYRIhX+Pk8Ag4ilCT0WrDw=,tag:3SSZuNNoQbQH7N6V6DubmA==,type:str]
    pgp:
    -   created_at: '2020-06-01T10:56:41Z'
        enc: |
            -----BEGIN PGP MESSAGE-----

            hQEMA3Rf9rajW18EAQf+P4AuwThQpkeR40VniIqzKaK8ui242DNN7tHO9UbrcHgE
            b1LGD/26rFdbxMTSnchRYKsaMgpIqJgXcDOqWYuPpzlBg6SZEEV3UL9aoZW1P0Ke
            OJNqZOZa6FwNGUzna94uipFIncXMzrUjvE0DPuyOcILJbNe+wiyA0xvF6KwuE40I
            XuL94pB9GSsAPtxxnOS97CnF3+PDJ3ULWG35BbNn2zgSs7So7usgjZUVex3+O7VZ
            PmhXmzI3H73LHDvTIX+ML1e6Au2KoglKb5cbd/BoZbuphiUR4yRimR8x/7mC1BZC
            ncO5glYTs90i6Fz2s+zQGDv5pI4emDyh/VhieOJbS9JcAZADFhV5x6boOZmzXyu6
            D8yR3d7/YpZAwzxLamdgeuTbNJ7nmJh76lCOleZtJvDWv2HRAV0mb7SNXnPJSnjK
            hkSnWDH2Za5VjvpxeT6CoykZMO6BhETMWmtLL4s=
            =hyvb
            -----END PGP MESSAGE-----
        fp: 7A03AF80B5B370F807A0936E3137BF39439690DD
    unencrypted_suffix: _unencrypted
    version: 3.5.0
````

24. Создал в директории kubernetes- templating/frontend/templates еще один файл ]`secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret
type: Opaque
data:
  visibleKey: {{ .Values.visibleKey | b64enc | quote }}
````

25. Запустил установку:

````
helm secrets upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop \
-f kubernetes-templating/frontend/values.yaml \ -f kubernetes-templating/frontend/secrets.yaml
````
Проверил, что secrets создался и работает:

`kubectl get secrets secret -n hipster-shop -o yaml`

````
apiVersion: v1
data:
  visibleKey: aGlkZGVuVmFsdWU=
kind: Secret
metadata:
  annotations:
    meta.helm.sh/release-name: frontend
    meta.helm.sh/release-namespace: hipster-shop
  creationTimestamp: "2020-06-01T11:38:42Z"
  labels:
    app.kubernetes.io/managed-by: Helm
  name: secret
  namespace: hipster-shop
  resourceVersion: "411209"
  selfLink: /api/v1/namespaces/hipster-shop/secrets/secret
  uid: 87689fb7-c3d8-4cbf-bc3f-5ed1b445e6b4
type: Opaque
````

- В CI/CD можно использовать helm-secrets для авторизации.

26. Поместил все получившиеся helm chart's в установленный harbor в публичный проект:

````
cat repo.sh
#!/bin/bash
helm repo add templating https://harbor.34.91.63.42.nip.io/chartrepo/library
helm push --username admin --password Harbor12345  frontend/ templating
helm push --username admin --password Harbor12345  hipster-shop/ templating
````

27. Вынесите манифесты описывающие service и deployment для этих микросервисов из файла all-hipster- shop.yaml в директорию kubernetes-templating/kubecfg.

28. Установил kubeconfig:

`brew install kubecfg`

29. Импортировал libsonnet библиотеку:

`local kube = import "https://github.com/bitnami-labs/kube- libsonnet/raw/52ba963ca44f7a4960aeae9ee0fbee44726e481f/kube.libsonnet";`

30. Проверил, что манифесты генерируются корректно:

`kubecfg show services.jsonnet`

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations: {}
  labels:
    name: paymentservice
  name: paymentservice
spec:
  minReadySeconds: 30
  replicas: 1
  selector:
    matchLabels:
      name: paymentservice
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      annotations: {}
      labels:
        name: paymentservice
    spec:
      containers:
      - args: []
        env:
        - name: PORT
          value: "50051"
        image: gcr.io/google-samples/microservices-demo/paymentservice:v0.1.3
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:50051
          initialDelaySeconds: 20
          periodSeconds: 15
        name: server
        ports:
        - containerPort: 50051
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:50051
          initialDelaySeconds: 20
          periodSeconds: 15
        securityContext:
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
        stdin: false
        tty: false
        volumeMounts: []
      imagePullSecrets: []
      initContainers: []
      terminationGracePeriodSeconds: 30
      volumes: []
---
apiVersion: v1
kind: Service
metadata:
  annotations: {}
  labels:
    name: paymentservice
  name: paymentservice
spec:
  ports:
  - port: 50051
    targetPort: 50051
  selector:
    name: paymentservice
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations: {}
  labels:
    name: shippingservice
  name: shippingservice
spec:
  minReadySeconds: 30
  replicas: 1
  selector:
    matchLabels:
      name: shippingservice
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      annotations: {}
      labels:
        name: shippingservice
    spec:
      containers:
      - args: []
        env:
        - name: PORT
          value: "50051"
        image: gcr.io/google-samples/microservices-demo/shippingservice:v0.1.3
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:50051
          initialDelaySeconds: 20
          periodSeconds: 15
        name: server
        ports:
        - containerPort: 50051
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:50051
          initialDelaySeconds: 20
          periodSeconds: 15
        securityContext:
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
        stdin: false
        tty: false
        volumeMounts: []
      imagePullSecrets: []
      initContainers: []
      terminationGracePeriodSeconds: 30
      volumes: []
---
apiVersion: v1
kind: Service
metadata:
  annotations: {}
  labels:
    name: shippingservice
  name: shippingservice
spec:
  ports:
  - port: 50051
    targetPort: 50051
  selector:
    name: shippingservice
  type: ClusterIP
````

31. Установил их:

`kubecfg update services.jsonnet --namespace hipster-shop`

````
INFO  Validating services paymentservice
INFO  validate object "/v1, Kind=Service"
INFO  Validating deployments paymentservice
INFO  validate object "apps/v1, Kind=Deployment"
INFO  Validating deployments shippingservice
INFO  validate object "apps/v1, Kind=Deployment"
INFO  Validating services shippingservice
INFO  validate object "/v1, Kind=Service"
INFO  Fetching schemas for 4 resources
INFO  Updating deployments paymentservice
INFO  Updating deployments shippingservice
````

32. Установил kustomize:

`brew install kustomize`

Проверяем для namespace hipster-shop:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: currencyservice
  namespace: hipster-shop
spec:
  ports:
  - name: grpc
    port: 7000
    targetPort: 7000
  selector:
    app: currencyservice
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: currencyservice
  namespace: hipster-shop
spec:
  selector:
    matchLabels:
      app: currencyservice
  template:
    metadata:
      labels:
        app: currencyservice
    spec:
      containers:
      - env:
        - name: REDDIS_ADR
          value: redis-cart-master:6379
        - name: PORT
          value: "7000"
        image: gcr.io/google-samples/microservices-demo/currencyservice:v0.1.3
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:7000
        name: server
        ports:
        - containerPort: 7000
          name: grpc
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:7000
        resources:
          limits:
            cpu: 200m
            memory: 128Mi
          requests:
            cpu: 100m
            memory: 64Mi
````
Создаем две среды выкатки: dev и prod.

Проверяем для dev:

````yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    environment: dev
  name: dev-currencyservice
  namespace: hipster-shop-dev
spec:
  ports:
  - name: grpc
    port: 7000
    targetPort: 7000
  selector:
    app: currencyservice
    environment: dev
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    environment: dev
  name: dev-currencyservice
  namespace: hipster-shop-dev
spec:
  selector:
    matchLabels:
      app: currencyservice
      environment: dev
  template:
    metadata:
      labels:
        app: currencyservice
        environment: dev
    spec:
      containers:
      - env:
        - name: REDIS_ADDR
          value: redis-cart:6379
        - name: REDDIS_ADR
          value: redis-cart-master:6379
        - name: PORT
          value: "7000"
        image: gcr.io/google-samples/microservices-demo/currencyservice:v0.1.3
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:7000
        name: server
        ports:
        - containerPort: 7000
          name: grpc
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:7000
        resources:
          limits:
            cpu: 200m
            memory: 128Mi
          requests:
            cpu: 100m
            memory: 64Mi
````
Для prod:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    environment: prod
  name: prod-currencyservice
  namespace: hipster-shop-prod
spec:
  ports:
  - name: grpc
    port: 7000
    targetPort: 7000
  selector:
    app: currencyservice
    environment: prod
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    environment: prod
  name: prod-currencyservice
  namespace: hipster-shop-prod
spec:
  selector:
    matchLabels:
      app: currencyservice
      environment: prod
  template:
    metadata:
      labels:
        app: currencyservice
        environment: prod
    spec:
      containers:
      - env:
        - name: REDDIS_ADR
          value: redis-cart-master:6379
        - name: PORT
          value: "7000"
        image: gcr.io/google-samples/microservices-demo/currencyservice:v0.1.3
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:7000
        name: server
        ports:
        - containerPort: 7000
          name: grpc
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:7000
        resources:
          limits:
            cpu: 200m
            memory: 128Mi
          requests:
            cpu: 100m
            memory: 64Mi
````
Вкатываем:

`kustomize build . | kubectl apply -f -`

````
service/cartservice created
deployment.apps/cartservice created
````

### ДЗ со *

1. Установка nginx-ingress, cert-manager и harbor в helmfile.

Устанавливаем необходимые пакеты:

`brew install helmfile`

Создаем `helmfile`:

````yaml
repositories:
  - name: stable
    url: https://kubernetes-charts.storage.googleapis.com
  - name: jetstack
    url: https://charts.jetstack.io
  - name: harbor
    url: https://helm.goharbor.io
  - name: incubator
    url: https://kubernetes-charts-incubator.storage.googleapis.com

helmDefaults:
  wait: true

releases:
  - name: nginx-ingress
    namespace: nginx-ingress
    chart: stable/nginx-ingress

  - name: cert-manager
    namespace: cert-manager
    chart: jetstack/cert-manager
    version: v0.15.1

  - name: cert-manager-issuers
    needs:
      - cert-manager/cert-manager
    namespace: cert-manager
    chart: incubator/raw
    version: 0.2.3
    values:
      - ./cert-manager/values.yaml

  - name: harbor
    needs:
      - cert-manager/cert-manager
    namespace: harbor
    chart: harbor/harbor
    version: 1.3.2
    values:
      - ./harbor/values.yaml

  - name: chartmuseum
    needs:
      - cert-manager/cert-manager
    namespace: chartmuseum
    chart: stable/chartmuseum
    version: 2.13.0
    values:
      - ./chartmuseum/values.yaml
````
Проверяем:

`helmfile lint`

````
Adding repo stable https://kubernetes-charts.storage.googleapis.com
"stable" has been added to your repositories

Adding repo jetstack https://charts.jetstack.io
"jetstack" has been added to your repositories

Adding repo harbor https://helm.goharbor.io
"harbor" has been added to your repositories

Adding repo incubator https://kubernetes-charts-incubator.storage.googleapis.com
"incubator" has been added to your repositories

Updating repo
Hang tight while we grab the latest from your chart repositories...
...Unable to get an update from the "chartmusem" chart repository (https://chartmuseum.34.91.164.106.nip.io/):
        Get https://chartmuseum.34.91.164.106.nip.io/index.yaml: dial tcp 34.91.164.106:443: connect: connection refused
...Successfully got an update from the "nginx-stable" chart repository
...Successfully got an update from the "templating" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "incubator" chart repository
...Successfully got an update from the "kubernetes-incubator" chart repository
...Successfully got an update from the "gitlab" chart repository
...Successfully got an update from the "bitnami" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈

Fetching stable/nginx-ingress
Fetching jetstack/cert-manager
Fetching incubator/raw
Fetching harbor/harbor
Fetching stable/chartmuseum
Building dependency release=nginx-ingress, chart=/var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/nginx-ingress/latest/stable/nginx-ingress/nginx-ingress
Building dependency release=cert-manager, chart=/var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/cert-manager/v0.15.1/jetstack/cert-manager/cert-manager
Building dependency release=cert-manager-issuers, chart=/var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/cert-manager-issuers/0.2.3/incubator/raw/raw
Building dependency release=harbor, chart=/var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/harbor/1.3.2/harbor/harbor/harbor
Building dependency release=chartmuseum, chart=/var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/chartmuseum/2.13.0/stable/chartmuseum/chartmuseum
Linting release=nginx-ingress, chart=/var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/nginx-ingress/latest/stable/nginx-ingress/nginx-ingress
==> Linting /var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/nginx-ingress/latest/stable/nginx-ingress/nginx-ingress

1 chart(s) linted, 0 chart(s) failed

Linting release=cert-manager, chart=/var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/cert-manager/v0.15.1/jetstack/cert-manager/cert-manager
==> Linting /var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/cert-manager/v0.15.1/jetstack/cert-manager/cert-manager

1 chart(s) linted, 0 chart(s) failed

Linting release=cert-manager-issuers, chart=/var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/cert-manager-issuers/0.2.3/incubator/raw/raw
==> Linting /var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/cert-manager-issuers/0.2.3/incubator/raw/raw
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

Linting release=harbor, chart=/var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/harbor/1.3.2/harbor/harbor/harbor
==> Linting /var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/harbor/1.3.2/harbor/harbor/harbor

1 chart(s) linted, 0 chart(s) failed

Linting release=chartmuseum, chart=/var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/chartmuseum/2.13.0/stable/chartmuseum/chartmuseum
==> Linting /var/folders/1x/s6sbmsqs47jdq5xzfkcglg380000gn/T/860827977/chartmuseum/2.13.0/stable/chartmuseum/chartmuseum

1 chart(s) linted, 0 chart(s) failed
````

Вкатываем:

`helmfile sync`


2. Добавление helm chart's:

- Для примера будем добавлять chart mysql:

   `git clone https://github.com/stakater/chart-mysql.git`

 - Переходим в директорию чарта. Опциональ проверяем линтом:

   `helm lint`

 - Упаковываем чарт в архив:

   `helm package .`

  - Отправляем архив в chartmuseum:

    `curl -L --data-binary "@mysql-1.0.3.tgz" https://chartmuseum.34.91.63.42.nip.io/api/charts`

    `{"saved":true}`

 - Обновляем репозиторий:

   `helm repo update`

 - Устанавливаем чарт:

   `helm install chartmuseum/mysql --name mysql`

3. Установил Redis как зависимость,используя community chart's.

Предварительно удаляем часть манифеста, где описывается redis:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cart
spec:
  selector:
    matchLabels:
      app: redis-cart
  template:
    metadata:
      labels:
        app: redis-cart
    spec:
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
        readinessProbe:
          periodSeconds: 5
          tcpSocket:
            port: 6379
        livenessProbe:
          periodSeconds: 5
          tcpSocket:
            port: 6379
        volumeMounts:
        - mountPath: /data
          name: redis-data
        resources:
          limits:
            memory: 256Mi
            cpu: 125m
          requests:
            cpu: 70m
            memory: 200Mi
      volumes:
      - name: redis-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: redis-cart
spec:
  type: ClusterIP
  selector:
    app: redis-cart
  ports:
  - name: redis
    port: 6379
    targetPort: 6379
````
Добавляем репозиторий с redis.

````
helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories
````

Добавляем зависимость в hipster-shop/Charts.yaml:

```yaml
- name: redis
  version: 10.6.17
  repository: https://charts.bitnami.com/bitnami
````

 - Необходимо изменить значение переменной окружения REDIS_ADDR (redis-cart > redis-cart-master) в cartservice Deployment.


Обновляем зависимости: `helm dep update kubernetes-templating/hipster-shop`

Вкатываем обновление релиза:

`helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop`


## kubernetes-operators

1. Поднял minikube:

`minikube start`

2. Cоздал CustomResource deploy/cr.yml

Пробуем применить его:

`kubectl apply -f deploy/cr.yml`

````
error: unable to recognize "deploy/cr.yml": no matches for kind "MySQL" in version "otus.homework/v1"
````
Ошибка связана с отсутсвием объектов типа MySQL в API kubernetes.

3. Создал `CustomResourceDefinition` - это ресурс для определения других ресурсов (далее CRD)

Применяем его:

`kubectl apply -f deploy/crd.yml`

`customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework created`

Применяем CR:

`ubectl apply -f deploy/cr.yml`

`mysql.otus.homework/mysql-instance created`

4. Пробуем взаимодейтсвовать с объектами:

````
$ kubectl get crd
NAME                   CREATED AT
mysqls.otus.homework   2020-06-01T17:30:55Z
````

````
> kubectl get mysqls.otus.homework
NAME             AGE
mysql-instance   91s
````

````
> kubectl describe mysqls.otus.homework mysql-instance
Name:         mysql-instance
Namespace:    default
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"otus.homework/v1","kind":"MySQL","metadata":{"annotations":{},"name":"mysql-instance","namespace":"default"},"spec":{"datab...
API Version:  otus.homework/v1
Kind:         MySQL
Metadata:
  Creation Timestamp:  2020-06-01T17:37:52Z
  Generation:          1
  Managed Fields:
    API Version:  otus.homework/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        .:
        f:database:
        f:image:
        f:password:
        f:storage_size:
      f:usless_data:
    Manager:         kubectl
    Operation:       Update
    Time:            2020-06-01T17:37:52Z
  Resource Version:  2022
  Self Link:         /apis/otus.homework/v1/namespaces/default/mysqls/mysql-instance
  UID:               fb9a8a3c-6a64-4ead-89a1-82ee657c8b06
Spec:
  Database:      otus-database
  Image:         mysql:5.7
  Password:      otuspassword
  storage_size:  1Gi
usless_data:     useless info
Events:          <none>
````

5. Использовал validation.

Для начала удаляем CR mysql-instance:

````
> kubectl delete mysqls.otus.homework mysql-instance
mysql.otus.homework "mysql-instance" deleted
````

Добавляем в спецификацию CRD ( `spec` ) параметры `validation` и применяем их снова:

````
kubectl apply -f deploy/crd.yml
kubectl apply -f deploy/cr.yml
````

```
error: error validating "deploy/cr.yml": error validating data: ValidationError(MySQL): unknown field "usless_data" in homework.otus.v1.MySQL; if you choose to ignore these errors, turn validation off with --validate=false
````
6. Убираем из cr.yml:

`usless_data: "useless info"`

Применяем:

`kubectl apply -f deploy/cr.yml`

Ошибок больше нет.

7. Из описания mysql убрал строчку из спецификации и манифест был принят API сервером. Для того, чтобы этого избежать, добавил описание обязательный полей в CustomResourceDefinition:

````
required: ["spec"]
required: ["image", "database", "password", "storage_size"]
````

8. Создал MySQL Operstor.

Удалим все ресурсы, созданные контроллером:

````
kubectl delete mysqls.otus.homework mysql-instance
kubectl delete deployments.apps mysql-instance
kubectl delete pvc mysql-instance-pvc
kubectl delete pv mysql-instance-pv
kubectl delete svc mysql-instance
````
Для удаления ресурсов, сделаем deployment,svc,pv,pvc дочерними ресурсами к mysql, для этого в тело функции mysql_on_create , после генерации json манифестов добавим:

````python
    # Определяем, что созданные ресурсы являются дочерними к управляемому
CustomResource:
kopf.append_owner_reference(persistent_volume, owner=body) kopf.append_owner_reference(persistent_volume_claim, owner=body) # addopt
kopf.append_owner_reference(service, owner=body) kopf.append_owner_reference(deployment, owner=body)
    # ^ Таким образом при удалении CR удалятся все, связанные с ним pv,pvc,svc,deployments
````
В конец файла добавим обработку события удаления ресурса mysql:

```python
@kopf.on.delete('otus.homework', 'v1', 'mysqls')
def delete_object_make_backup(body, **kwargs):
return {'message': "mysql and its children resources deleted"}
````

Запускаем оператор:

`kopf run mysql-operator.py`

````
[2020-06-02 23:23:37,597] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'mysql_on_create' succeeded.
[2020-06-02 23:23:37,597] kopf.objects         [INFO    ] [default/mysql-instance] All handlers succeeded for creation.
````
Проверяем что появились pvc:

````
NAME                        STATUS   VOLUME                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
backup-mysql-instance-pvc   Bound    backup-mysql-instance-pv   1Gi        RWO                           5s
mysql-instance-pvc          Bound    mysql-instance-pv          1Gi        RWO                           5s
````

`kubectl get pv`

````
NAME                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS   REASON   AGE
backup-mysql-instance-pv   1Gi        RWO            Retain           Bound    default/backup-mysql-instance-pvc                           7s
mysql-instance-pv          1Gi        RWO            Retain           Bound    default/mysql-instance-pvc                                  7s
````

Добавим создание pv, pvc для backup и restore job. Для этого после создания deployment добавим следующий код:

```python
    # Cоздаем PVC  и PV для бэкапов:
    try:
        backup_pv = render_template('backup-pv.yml.j2', {'name': name})
        api = kubernetes.client.CoreV1Api()
        print(api.create_persistent_volume(backup_pv))
        api.create_persistent_volume(backup_pv)
    except kubernetes.client.rest.ApiException:
        pass

    try:
        backup_pvc = render_template('backup-pvc.yml.j2', {'name': name})
        api = kubernetes.client.CoreV1Api()
        api.create_namespaced_persistent_volume_claim('default', backup_pvc)
    except kubernetes.client.rest.ApiException:
        pass
````
Далее реализуем создание бэкапов и восстановление из них. Для этого будут использоваться Job. Поскольку при запуске Job, повторно ее запустить нельзя, нам нужно реализовать логику удаления успешно законченных jobs c определенным именем.

Для этого выше всех обработчиков событий (под функций render_template) добавим следующую функцию:

```python
def delete_success_jobs(mysql_instance_name):
    print("start deletion")
    api = kubernetes.client.BatchV1Api()
    jobs = api.list_namespaced_job('default')
    for job in jobs.items:
        jobname = job.metadata.name
        if (jobname == f"backup-{mysql_instance_name}-job") or \
                (jobname == f"restore-{mysql_instance_name}-job"):
            if job.status.succeeded == 1:
                api.delete_namespaced_job(jobname,
                                          'default',
                                          propagation_policy='Background')
````

Также нам понадобится функция, для ожидания пока наша backup job завершится, чтобы дождаться пока backup выполнится перед удалением mysql deployment, svc, pv, pvc.
Опишем ее:

```python
def wait_until_job_end(jobname):
    api = kubernetes.client.BatchV1Api()
    job_finished = False
    jobs = api.list_namespaced_job('default')
    while (not job_finished) and \
            any(job.metadata.name == jobname for job in jobs.items):
        time.sleep(1)
        jobs = api.list_namespaced_job('default')
        for job in jobs.items:
            if job.metadata.name == jobname:
                print(f"job with { jobname }  found,wait untill end")
                if job.status.succeeded == 1:
                    print(f"job with { jobname }  success")
                    job_finished = True
````

Добавим запуск backup-job и удаление выполненных jobs в функцию delete_object_make_backup:

```python
    name = body['metadata']['name']
    image = body['spec']['image']
    password = body['spec']['password']
    database = body['spec']['database']

    delete_success_jobs(name)

    # Cоздаем backup job:
    api = kubernetes.client.BatchV1Api()
    backup_job = render_template('backup-job.yml.j2', {
        'name': name,
        'image': image,
        'password': password,
        'database': database})
    api.create_namespaced_job('default', backup_job)
    wait_until_job_end(f"backup-{name}-job")
````

Добавим генерацию json из шаблона для restore-job:

```python
restore_job = render_template('restore-job.yml.j2', {
        'name': name,
        'image': image,
        'password': password,
        'database': database})
````

Добавим попытку восстановиться из бэкапов после deployment mysql:

```python
    try:
        api = kubernetes.client.BatchV1Api()
        api.create_namespaced_job('default', restore_job)
    except kubernetes.client.rest.ApiException:
        pass
````

Добавим зависимость restore-job от объектов mysql (возле других owner_reference):

```python
kopf.append_owner_reference(restore_job, owner=body)
````

Запускаем оператор (из директории build):

`kopf run mysql-operator.py`

`kubectl apply -f deploy/cr.yml`

Проверяем что появились pvc:

`kubectl get pvc`

````
NAME                        STATUS   VOLUME                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
backup-mysql-instance-pvc   Bound    backup-mysql-instance-pv   1Gi        RWO                           29m
mysql-instance-pvc          Bound    mysql-instance-pv          1Gi        RWO                           14s
````
Проверим, что все работает, для этого заполним базу созданного mysqlinstance:

````
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")

kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test (id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.

kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name) VALUES ( null, 'some data' );" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.

kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name) VALUES ( null, 'some data-2' );" otus-database


kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name) VALUES ( null, 'some data-2' );" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.


kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
````
Удалим mysql-instance:

````
kubectl delete mysqls.otus.homework mysql-instance
mysql.otus.homework "mysql-instance" deleted
````
Создадим заново mysql-instance:

````
kubectl apply -f cr.yml
mysql.otus.homework/mysql-instance created
````
После выполняем:

````
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")

kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
````
Создаем `Dockerfile`и пушим все в свой репозиторий:

```
FROM python:3.7
COPY templates ./templates
COPY mysql-operator.py ./mysql-operator.py
RUN pip install kopf kubernetes pyyaml jinja2
CMD kopf run /mysql-operator.py
````

Создадим и применим манифесты в папке kubernetes-operator/deploy:

 - service-account.yml
 - role.yml
 - role-binding.yml
 - deploy-operator.yml

Применним манифесты:
 - service-account.yml
 - role.yml role-binding.yml
 - deploy-operator.yml


Проверяем что появились pvc.

Заполняем базу созданного mysql-instance:

````
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")

kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
````
Удалим mysql-instance:

````
kubectl delete mysqls.otus.homework mysql-instance
mysql.otus.homework "mysql-instance" deleted
````
Создадим заново:

`kubectl apply -f deploy/cr.yml`

````
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
````
