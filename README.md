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


## kubernetes-monitoring

1. Поднял minikube:

`minikube start`

2. Установил prometheus-operator:

`helm repo add stable https://kubernetes-charts.storage.googleapis.com`

`helm upgrade --install prometheus-operator stable/prometheus-operator --create-namespace --namespace monitoring --version 8.13.12`

3. Инициализировал helm chart:

`helm init custom-nginx`

 В чарте удалил все лишние и доавил манифесты приложения nginx.

 Шаблонизировал чарты.

4. Установил chart nginx:

`helm upgrade --install custom-nginx kubernetes-monitoring/custom-nginx`

5. Проверяем работу приложения:

`kubectl get pods`

````
NAME                     READY   STATUS    RESTARTS   AGE
nginx-869f7cf565-524lv   2/2     Running   0          90m
nginx-869f7cf565-9csnm   2/2     Running   0          90m
nginx-869f7cf565-fh75r   2/2     Running   0          90m
````

Делаем пробросов портов:

`kubectl port-forward service/nginx 9113:9113`

````
Forwarding from 127.0.0.1:9113 -> 9113
Forwarding from [::1]:9113 -> 9113
````
`curl http://127.0.0.1:9113/metrics`

````
# HELP nginx_connections_accepted Accepted client connections
# TYPE nginx_connections_accepted counter
nginx_connections_accepted 4
# HELP nginx_connections_active Active client connections
# TYPE nginx_connections_active gauge
nginx_connections_active 1
# HELP nginx_connections_handled Handled client connections
# TYPE nginx_connections_handled counter
nginx_connections_handled 4
# HELP nginx_connections_reading Connections where NGINX is reading the request header
# TYPE nginx_connections_reading gauge
nginx_connections_reading 0
# HELP nginx_connections_waiting Idle client connections
# TYPE nginx_connections_waiting gauge
nginx_connections_waiting 0
# HELP nginx_connections_writing Connections where NGINX is writing the response back to the client
# TYPE nginx_connections_writing gauge
nginx_connections_writing 1
# HELP nginx_http_requests_total Total http requests
# TYPE nginx_http_requests_total counter
nginx_http_requests_total 172
# HELP nginx_up Status of the last metric scrape
# TYPE nginx_up gauge
nginx_up 1
# HELP nginxexporter_build_info Exporter build information
# TYPE nginxexporter_build_info gauge
nginxexporter_build_info{gitCommit="a2910f1",version="0.7.0"} 1
````

6. Пробрасываем порты для prometheus:

`kubectl port-forward service/prometheus-operator-prometheus -n monitoring 9090:9090`

Заходим на: `http://127.0.0.1:9090/targets `
Смотрим, что 3 репики нашего приложения поднялись и работают.

7. Пробрасываем порты для `Grafana`:

`kubectl port-forward service/prometheus-operator-grafana  -n monitoring 8000:80`

8. Строим график для запросов в 1 мин:

![альт](https://github.com/otus-kuber-2020-04/volkmydj_platform/blob/kubernetes-monitoring/kubernetes-monitoring/grafana.png?raw=true "описание при наведении")


kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo



## kubernetes-logging
---
==Подготовка Kubernetes кластера==

1. Поднимаем кластер с 2 пулами нод и проверяем подключение:

`terraform apply` (ждем примерно 6-7 мин.)

````
Apply complete! Resources: 4 added, 0 changed, 0 dest
````
`gcloud container clusters get-credentials my-gke-cluster --region europe-west4-a --project otus-kuber-278507`

`kubectl get nodes`

````
NAME                                            STATUS   ROLES    AGE     VERSION
gke-my-gke-cluster-default-pool-5458d676-d28h   Ready    <none>   4m13s   v1.15.11-gke.13
gke-my-gke-cluster-infra-pool-4afaa6fe-1v9k     Ready    <none>   9m50s   v1.15.11-gke.13
gke-my-gke-cluster-infra-pool-4afaa6fe-4tg4     Ready    <none>   9m51s   v1.15.11-gke.13
gke-my-gke-cluster-infra-pool-4afaa6fe-scld     Ready    <none>   9m50s   v1.15.11-gke.13
````
### ==Установка hipster-shop==

* Самый простой способ сделать это - применить подготовленный манифест:

`kubectl create ns microservices-demo`


`kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo`

````
deployment.apps/emailservice created
service/emailservice created
deployment.apps/checkoutservice created
service/checkoutservice created
deployment.apps/recommendationservice created
service/recommendationservice created
deployment.apps/frontend created
service/frontend created
service/frontend-external created
deployment.apps/paymentservice created
service/paymentservice created
deployment.apps/productcatalogservice created
service/productcatalogservice created
deployment.apps/cartservice created
service/cartservice created
deployment.apps/loadgenerator created
deployment.apps/currencyservice created
service/currencyservice created
deployment.apps/shippingservice created
service/shippingservice created
deployment.apps/redis-cart created
service/redis-cart created
deployment.apps/adservice created
service/adservice created
````

* Проверяем, что все pod развернулись на ноде из default-pool:

`kubectl get pods -n microservices-demo -o wide`

````
NAME                                     READY   STATUS    RESTARTS   AGE     IP           NODE                                            NOMINATED NODE   READINESS GATES
adservice-9679d5b56-n498g                1/1     Running   0          2m48s   10.32.0.19   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
cartservice-66b4c7d59-vxrqd              1/1     Running   2          2m49s   10.32.0.14   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
checkoutservice-6cb96b65fd-9wrws         1/1     Running   0          2m52s   10.32.0.9    gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
currencyservice-68df8c8788-977wd         1/1     Running   0          2m49s   10.32.0.16   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
emailservice-6fc9c98fd-6fwc6             1/1     Running   0          2m52s   10.32.0.8    gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
frontend-5559967bcd-9hh5n                1/1     Running   0          2m51s   10.32.0.11   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
loadgenerator-674846f899-clmcb           1/1     Running   4          2m49s   10.32.0.15   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
paymentservice-6cb4db7678-nvbpn          1/1     Running   0          2m50s   10.32.0.12   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
productcatalogservice-768b67d968-zm9sf   1/1     Running   0          2m50s   10.32.0.13   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
recommendationservice-f45c4979d-hdk88    1/1     Running   0          2m51s   10.32.0.10   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
redis-cart-cfcbcdf6c-59bvp               1/1     Running   0          2m48s   10.32.0.18   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
shippingservice-5d68c4f8d4-8g2bv         1/1     Running   0          2m48s   10.32.0.17   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
````

### ==Установка EFK стека | Helm charts==

* Рекомендуемый репозиторий с Helm chart для ElasticSearch и Kibana на текущий момент - https://github.com/elastic/helm-charts

Добавим его:

`helm repo add elastic https://helm.elastic.co`

`helm repo update`

````
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "nginx-stable" chart repository
...Successfully got an update from the "kubernetes-incubator" chart repository
...Successfully got an update from the "incubator" chart repository
...Successfully got an update from the "elastic" chart repository
...Successfully got an update from the "gitlab" chart repository
...Successfully got an update from the "loki" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "bitnami" chart repository
...Successfully got an update from the "stable" chart repository
...Unable to get an update from the "chartmusem" chart repository
Update Complete. ⎈ Happy Helming!⎈
````

* Установим нужные нам компоненты, для начала - без какой- либо дополнительной настройки:

`kubectl create ns observability`

 ElasticSearch \
`helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability`

````
Release "elasticsearch" does not exist. Installing it now.
NAME: elasticsearch
LAST DEPLOYED: Wed Jun 10 17:18:05 2020
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
1. Watch all cluster members come up.
  $ kubectl get pods --namespace=observability -l app=elasticsearch-master -w
2. Test cluster health using Helm test.
  $ helm test elasticsearch --cleanup
````
Kibana \
`helm upgrade --install kibana elastic/kibana --namespace observability`
````
Release "kibana" does not exist. Installing it now.
NAME: kibana
LAST DEPLOYED: Wed Jun 10 17:19:06 2020
NAMESPACE: observability
STATUS: deployed
REVISION: 1
TEST SUITE: None
````

Fluent Bit \
`helm upgrade --install fluent-bit stable/fluent-bit --namespace observability`

````
Release "fluent-bit" does not exist. Installing it now.
NAME: fluent-bit
LAST DEPLOYED: Wed Jun 10 17:21:11 2020
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
fluent-bit is now running.

It will forward all container logs to the svc named fluentd on port: 24284
````

* Создаем в директории kubernetes-logging файл `elasticsearch.values.yaml`, будем указывать в этом файле нужные нам values.

* Разрешим ElasticSearch запускаться на данных нодах:

```yaml
tolerations:
  - key: node-role
      operator: Equal
      value: infra
      effect: NoSchedule
````
* Обновляем установку:

`helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability -f elasticsearch.values.yaml`

Теперь ElasticSearch может запускаться на нодах из infra-pool, но это не означает, что он должен это делать.

Исправим этот момент и добавим в `elasticsearch.values.yaml` `NodeSelector`, определяющий, на каких нодах мы можем запускать наши pod.

```yaml
nodeSelector:
  cloud.google.com/gke-nodepool: infra-pool
````

* Обновляем установку:

`helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability -f elasticsearch.values.yaml`

Через некоторое время мы сможем наблюдать следующую картину:

`kubectl get pods -n observability -o wide -l chart=elasticsearch`


````
NAME                     READY   STATUS    RESTARTS   AGE    IP           NODE                                            NOMINATED NODE   READINESS GATES
elasticsearch-master-0   1/1     Running   0          14m    10.32.0.20   gke-my-gke-cluster-default-pool-5458d676-d28h   <none>           <none>
elasticsearch-master-1   0/1     Running   0          50s    10.32.2.3    gke-my-gke-cluster-infra-pool-4afaa6fe-scld     <none>           <none>
elasticsearch-master-2   1/1     Running   0          2m2s   10.32.3.3    gke-my-gke-cluster-infra-pool-4afaa6fe-1v9k     <none>           <none>
````

==Установка nginx-ingress==

* Устанавливаем nginx-ingress. Разворачиваем три реплики controller, по одной, на каждую ноду из infra-pool:

`ingress.values.yaml`:

````yaml
controller:
  replicaCount: 3

  tolerations:
    - key: node-role
      operator: Equal
      value: infra
      effect: NoSchedule

  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
                - key: app
                  operator: In
                  values:
                    - nginx-ingress
            topologyKey: kubernetes.io/hostname

  nodeSelector:
    cloud.google.com/gke-nodepool: infra-pool
````
Вкатываем:

`helm upgrade --install nginx-ingress stable/nginx-ingress --namespace=nginx-ingress --version=1.39.0 -f nginx-ingress.values.yaml --create-namespace`

````
Release "nginx-ingress" does not exist. Installing it now.
NAME: nginx-ingress
LAST DEPLOYED: Wed Jun 10 17:39:27 2020
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

### ==Установка EFK стека | Kibana==

* Создаем файл kibana.values.yaml в директории kubernetes-logging и добавляем туда конфигурацию для создания ingress:

````yaml
ingress:
  enabled: true
  annotations: { kubernetes.io/ingress.class: nginx }
  path: /
  hosts:
    - kibana.34.90.81.164.xip.io
````
Обновляем релиз:

`helm upgrade --install kibana elastic/kibana --namespace observability -f kibana.values.yaml`

````
Release "kibana" has been upgraded. Happy Helming!
NAME: kibana
LAST DEPLOYED: Wed Jun 10 17:45:34 2020
NAMESPACE: observability
STATUS: deployed
REVISION: 2
TEST SUITE: None
````

* Попробуем создать `index pattern`, и увидим, что в ElasticSearch пока что не обнаружено никаких данных:

![alt text](screenshots/kibana-1.png "Описание будет тут")​

* Посмотрим в логи решения, которое отвечает за отправку логов (Fluent Bit) и увидим следующие строки:

`kubectl logs fluent-bit-xnknh -n observability --tail 2`

````
[2020/06/10 14:58:19] [error] [out_fw] no upstream connections available
[2020/06/10 14:58:19] [ warn] [engine] failed to flush chunk '1-1591798878.183008011.flb', retry in 1090 seconds: task_id=14, input=tail.0 > output=forward.0
````

* Попробуем исправить проблему. Создадим файл fluent- bit.values.yaml и добавим туда:

````yaml
backend:
  type: es
  es:
    host: elasticsearch-master
````
Обновляем релиз:

`helm upgrade --install fluent-bit stable/fluent-bit --namespace observability -f fluent-bit.values.yaml`

````
Release "fluent-bit" has been upgraded. Happy Helming!
NAME: fluent-bit
LAST DEPLOYED: Wed Jun 10 18:30:57 2020
NAMESPACE: observability
STATUS: deployed
REVISION: 2
NOTES:
fluent-bit is now running.
````

Попробуем повторно создать index pattern. В этот раз ситуация изменилась, и какие-то индексы в ElasticSearch уже есть:

![alt text](screenshots/kibana-2.png )​


После установки можно заметить, что в ElasticSearch попадают
далеко не все логи нашего приложения.
Причину можно найти в логах pod с Fluent Bit, он пытается обработать JSON, отдаваемый приложением, и находит там дублирующиеся поля time и timestamp.

(GitHub [issue], с более подробным описанием проблемы)

[issue]: https://github.com/fluent/fluent-bit/issues/628

* Воспользуемся фильтром [Modify],
который позволит удалить из логов "лишние" ключи:

[Modify]: https://docs.fluentbit.io/manual/pipeline/filters/modify

`fluent-bit.values.yaml`:

````yaml
backend:
  type: es
  es:
    host: elasticsearch-master
rawConfig: |
  @INCLUDE fluent-bit-service.conf
  @INCLUDE fluent-bit-input.conf
  @INCLUDE fluent-bit-filter.conf
  @INCLUDE fluent-bit-output.conf

  [FILTER]
      Name     modify
      Match    *
      Remove   time
      Remove   @timestamp
`````

Обновляем релиз:

`helm upgrade --install fluent-bit stable/fluent-bit --namespace observability -f fluent-bit.values.yaml`

````
Release "fluent-bit" has been upgraded. Happy Helming!
NAME: fluent-bit
LAST DEPLOYED: Wed Jun 10 18:48:07 2020
NAMESPACE: observability
STATUS: deployed
REVISION: 4
NOTES:
fluent-bit is now running.
````

#### Задание со ⭐

Попробуем другое решение проблемы.

* Удалим строки в секции:

````
  [FILTER]
      Name     modify
      Match    *
      Remove   time
      Remove   @timestamp
`````

* Добавим префикс к полям из json:

````
filter:
  mergeLogKey: "app"
````

Обновляем релиз:

`helm upgrade --install fluent-bit stable/fluent-bit --namespace observability -f fluent-bit.values.yaml`


### ==Мониторинг ElasticSearch==


* Для мониторинга ElasticSearch будем использовать следующий [Prometheus exporter].

[Prometheus exporter]: https://github.com/justwatchcom/elasticsearch_exporter

Устанавливаем его (см `prometheus.values.yaml`):

`helm upgrade --install  prometheus-operator stable/prometheus-operator -n observability --create-namespace -f prometheus.values.yaml`

````
NAME: prometheus-operator
LAST DEPLOYED: Wed Jun 10 19:05:41 2020
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
The Prometheus Operator has been installed. Check its status by running:
  kubectl --namespace observability get pods -l "release=prometheus-operator"

Visit https://github.com/coreos/prometheus-operator for instructions on how
to create & configure Alertmanager and Prometheus instances using the Operator.
````

* Устанавливаем exporter:

`helm upgrade --install elasticsearch-exporter stable/elasticsearch-exporter --set es.uri=http://elasticsearch-master:9200 --set serviceMonitor.enabled=true --namespace=observability`

````
Release "elasticsearch-exporter" does not exist. Installing it now.
NAME: elasticsearch-exporter
LAST DEPLOYED: Wed Jun 10 19:10:29 2020
NAMESPACE: observability
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace observability -l "app=elasticsearch-exporter" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:9108/metrics to use your application"
  kubectl port-forward $POD_NAME 9108:9108 --namespace observability
````

* Устанавливаем один из популярных дашбордов:

![alt text](screenshots/grafana-1.png )​

* Сделаем drain одной из нод infra-pool

`kubectl drain gke-my-gke-cluster-infra-pool-4afaa6fe-1v9k --ignore-daemonsets`

````
node/gke-my-gke-cluster-infra-pool-4afaa6fe-1v9k cordoned
WARNING: ignoring DaemonSet-managed Pods: observability/prometheus-operator-prometheus-node-exporter-srn5p
evicting pod "nginx-ingress-controller-75b44fddff-tcsqk"
evicting pod "elasticsearch-master-2"
pod/elasticsearch-master-2 evicted
````
Статус Cluster Health остался зеленым, но количество нод в кластере уменьшилось до двух штук. При этом, кластер сохранил полную работоспособность:

![alt text](screenshots/grafana-2.png )​

Попробуем сделать drain второй ноды из infra-pool, и увидим что [PDB] не дает этого сделать:

[PDB]: https://kubernetes.io/docs/tasks/run-application/configure-pdb/

`kubectl drain gke-my-gke-cluster-infra-pool-4afaa6fe-4tg4 --ignore-daemonsets`

````
WARNING: ignoring DaemonSet-managed Pods: observability/prometheus-operator-prometheus-node-exporter-rpgnh
evicting pod "elasticsearch-master-0"
evicting pod "nginx-ingress-controller-75b44fddff-qp44k"
evicting pod "nginx-ingress-controller-75b44fddff-dwv9p"
error when evicting pod "elasticsearch-master-0" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod "elasticsearch-master-0"
error when evicting pod "elasticsearch-master-0" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod "elasticsearch-master-0"
error when evicting pod "elasticsearch-master-0" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
````
Удалим под той ноды, которую хотели удалить:

`kubectl delete pods elasticsearch-master-0 -n observability`

Оставшийся под перешел в статус Pending:

````
observability        elasticsearch-master-2     0/1     Pending   0          36m
````


## ==EFK | nginx ingress==

Попробуем найти в Kibana логи nginx-ingress (например, полнотекстовым поиском по слову nginx) и обнаружим, что они отсутствуют.

* Разрешим запуск fluent-bit на infra нодах в `fluent-bit.values.yaml`:

````yaml
tolerations:
  - key: node-role
    operator: Equal
    value: infra
    effect: NoSchedule
````
Обновляем релиз:

`helm upgrade --install fluent-bit stable/fluent-bit --namespace observability -f fluent-bit.values.yaml`

* После появления логов nginx у нас возникнет следующая проблема:

![alt text](screenshots/kibana-3.png )​

Сейчас лог представляет из себя строку, с которой сложно
работать.
Мы можем использовать полнотекстовый поиск, но лишены возможности:
- Задействовать функции KQL
- Полноценно проводить аналитику
- Создавать Dashboard по логам
- ...

* Добавим ключ [log-format-escape-json], в nginx-ingress.values.yaml

[log-format-escape-json]: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#log-format-escape-json

Также добавим [log-format-upstream]:

[log-format-upstream]: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#log-format-escape-json


```yaml
  config:
    log-format-escape-json: "true"
    log-format-upstream: '{"remote_addr": "$proxy_protocol_addr", "x-forward-for": "$proxy_add_x_forwarded_for", "request_id": "$req_id", "remote_user": "$remote_user", "bytes_sent": $bytes_sent, "request_time": $request_time, "status":$status, "vhost": "$host", "request_proto": "$server_protocol", "path": "$uri", "request_query": "$args", "request_length": $request_length, "duration": $request_time,"method": "$request_method", "http_referrer": "$http_referer", "http_user_agent": "$http_user_agent" }'
```

Обновим релиз:

`helm upgrade --install nginx-ingress stable/nginx-ingress --namespace=nginx-ingress --version=1.39.0 -f nginx-ingress.values.yaml --create-namespace`

Проверяем:

`kubectl get  configmaps nginx-ingress-controller -n nginx-ingress -o yaml`

````yaml
apiVersion: v1
data:
  log-format-escape-json: "true"
  log-format-upstream: '{"remote_addr": "$proxy_protocol_addr", "x-forward-for": "$proxy_add_x_forwarded_for",
    "request_id": "$req_id", "remote_user": "$remote_user", "bytes_sent": $bytes_sent,
    "request_time": $request_time, "status":$status, "vhost": "$host", "request_proto":
    "$server_protocol", "path": "$uri", "request_query": "$args", "request_length":
    $request_length, "duration": $request_time,"method": "$request_method", "http_referrer":
    "$http_referer", "http_user_agent": "$http_user_agent" }'
kind: ConfigMap
metadata:
  annotations:
    meta.helm.sh/release-name: nginx-ingress
    meta.helm.sh/release-namespace: nginx-ingress
  creationTimestamp: "2020-06-10T17:23:19Z"
  labels:
    app: nginx-ingress
    app.kubernetes.io/managed-by: Helm
    chart: nginx-ingress-1.39.0
    component: controller
    heritage: Helm
    release: nginx-ingress
  name: nginx-ingress-controller
  namespace: nginx-ingress
  resourceVersion: "65309"
  selfLink: /api/v1/namespaces/nginx-ingress/configmaps/nginx-ingress-controller
  uid: 1868ce3e-5617-4e3a-b163-dac1829f305b
````

Формат логов изменился:

````
"_source": {
  x-forward-for": "10.128.0.35",
  "request_id": "bfcee33afe75c099f7887d7e70b1ab00",
  "bytes_sent": 19087,
  "request_time": 1.168,
  "status": 200,
````

* Создаем новую визуализацию с типом TSVB:

Для начала, создадим визуализацию, показывающую общее количество запросов к nginx-ingress. Для этого нам понадобится применить следующий KQL фильтр:

`kubernetes.labels.app : nginx-ingress`

Добавляем данный фильтр в Panel options нашей визуализации.

* Cоздаем визуализации для отображения запросов к nginx-ingress со статусами:

 - 200-299
 - 300-399
 - 400-499
 - 500+

Создаем Dashboard и добавляем на него свои визуализации.

Экспортируем получившиеся визуализации и Dashboard,добавляем файл `export.ndjson`.


## ==Loki==

* Установливаме Loki в namespace observability
* Модифицируем конфигурацию prometheus-operator таким образом, чтобы datasource Loki создавался сразу после установки оператора
* Включаем метрики для nginx-ingress

Обновляем релизы:

`helm upgrade --install nginx-ingress stable/nginx-ingress --namespace=nginx-ingress --version=1.39.0 -f nginx-ingress.values.yaml --create-namespace`

`helm upgrade --install  prometheus-operator stable/prometheus-operator -n observability --create-namespace -f prometheus.values.yaml`

Устанавливаем Loki:

`helm repo add loki https://grafana.github.io/loki/charts`

`helm repo update`

`helm upgrade --install loki --namespace=observability loki/loki-stack  -f loki.values.yaml`

Проверяем:

`kubectl get pods -n observability`

````
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-operator-alertmanager-0          2/2     Running   0          115m
elasticsearch-exporter-7787cf7bf4-z7fmd                  1/1     Running   0          111m
elasticsearch-master-0                                   1/1     Running   0          70m
elasticsearch-master-1                                   1/1     Running   0          138m
elasticsearch-master-2                                   1/1     Running   0          104m
fluent-bit-26wsl                                         1/1     Running   0          55m
fluent-bit-49k77                                         1/1     Running   0          55m
fluent-bit-dhc96                                         1/1     Running   0          55m
fluent-bit-sgl6h                                         1/1     Running   0          54m
kibana-kibana-9bd8f8cb9-b7htc                            1/1     Running   0          3h43m
loki-0                                                   0/1     Running   0          46s
loki-promtail-2gs46                                      1/1     Running   0          46s
loki-promtail-8qtvc                                      1/1     Running   0          46s
loki-promtail-mnfsr                                      1/1     Running   0          46s
loki-promtail-tj9b2                                      1/1     Running   0          46s
prometheus-operator-grafana-6678fc5cd5-46n67             2/2     Running   0          115m
prometheus-operator-kube-state-metrics-5c4649546-jdjhv   1/1     Running   0          115m
prometheus-operator-operator-dc6fbb584-4vhrh             2/2     Running   0          115m
prometheus-operator-prometheus-node-exporter-lzfz6       1/1     Running   0          115m
prometheus-operator-prometheus-node-exporter-rpgnh       1/1     Running   0          115m
prometheus-operator-prometheus-node-exporter-srn5p       1/1     Running   0          115m
prometheus-operator-prometheus-node-exporter-w7z9r       1/1     Running   0          115m
prometheus-prometheus-operator-prometheus-0              3/3     Running   1          115m
````


````
Release "loki" does not exist. Installing it now.
NAME: loki
LAST DEPLOYED: Wed Jun 10 21:01:21 2020
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
The Loki stack has been deployed to your cluster. Loki can now be added as a datasource in Grafana.

See http://docs.grafana.org/features/datasources/loki/ for more detail.
````

## ==Loki | nginx ingress==

До недавнего времени, единственным способом визуализации логов в Loki была функция Explore.

Loki, аналогично ElasticSearch умеет разбирать JSON лог по ключам, но, к сожалению, фильтрация по данным ключам на текущий момент не работает.


## ==Loki | Визуализация==

* Создаем Dashboard, на котором одновременно выведем
метрики nginx-ingress и его логи:

`nginx.json`

* Добавим панель с логами и укажем для нее следующие настройки Query:

`{app="nginx-ingress"}`

* Добавим в Dashboard дополнительные панели с метриками, отслеживание которых может быть важным.

* Выгрузим из Grafana JSON с финальным Dashboard и поместим его в файл kubernetes-logging/nginx-ingress.json

## ==Event logging | k8s-event-logger==

* Установим еще одну небольшую, но очень полезную [утилиту], позволяющую получить и сохранить event'ы Kubernetes в выбранном решении для логирования:

[утилиту]: https://github.com/max-rocket-internet/k8s-event-logger

`git clone https://github.com/max-rocket-internet/k8s-event-logger.git`

`helm upgrade --install event-logger -n observability chart/`

````
Release "event-logger" does not exist. Installing it now.
NAME: event-logger
LAST DEPLOYED: Wed Jun 10 21:23:36 2020
NAMESPACE: observability
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
To verify that the k8s-event-logger pod has started, run:

  kubectl --namespace=observability get pods -l "app.kubernetes.io/name=k8s-event-logger,app.kubernetes.io/instance=event-logger"
````


## kubbernetes-vault

### ==Инсталляция hashicorp vault HA в k8s==

+ Поднимаем кластер (минимум 3 ноды):

`terraform apply`

+ Инициализируем кластер:

`gcloud container clusters get-credentials my-gke-cluster --region europe-west4-a --project otus-kuber-278507`

+ Добавим репозиторий

````
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
````


+ Установим consul:

`helm upgrade --install consul hashicorp/consul`

### ==Отредактируем параметры установки в values.yaml==

```yaml
standalone:
enabled: false ....
ha:
enabled: true ...
ui:
enabled: true
  serviceType: "ClusterIP"
````


### ==Установим vault

`helm upgrade --install vault hashicorp/vault -f vault.values.yaml`

`get po `

````
NAME                                   READY   STATUS    RESTARTS   AGE
consul-consul-rz6mv                    1/1     Running   0          4m19s
consul-consul-s7ln5                    1/1     Running   0          4m19s
consul-consul-server-0                 1/1     Running   0          4m19s
consul-consul-server-1                 1/1     Running   0          4m19s
consul-consul-server-2                 1/1     Running   0          4m19s
consul-consul-zt25r                    1/1     Running   0          4m19s
vault-0                                0/1     Running   0          3m49s
vault-1                                0/1     Running   0          3m49s
vault-2                                0/1     Running   0          3m49s
vault-agent-injector-cc48fcc8c-tvpwv   1/1     Running   0          3m49s
````
+ Проверим статус:

`helm status vault `

````
NAME: vault
LAST DEPLOYED: Mon Jun 29 23:48:16 2020
NAMESPACE: ame
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get vault
````

+ Проведем инициализацию черерз любой под vault'а kubectl:

`kubectl exec -it vault-0  -- vault operator init --key-shares=1 --key-threshold=1`

````
Unseal Key 1: vQeoXTQxtHjZgXoBbDyomf+GCCwFNfYwTgjWil1JHmo=

Initial Root Token: s.vpKIYWXsrGKl6L69oKQxGEsM

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 1 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
````

## ==Проверим состояние vault:

`kubectl exec -it vault-0 -- vault status`

````
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.4.2
HA Enabled         true
command terminated with exit code 2
````

## ==Распечатаем vault:

`kubectl exec -it vault-0  env | grep VAULT_ADDR`

````
VAULT_ADDR=http://127.0.0.1:8200
````
+ Распечатаем каждый pod:

kubectl exec -it vault-0  -- vault operator unseal 'vQeoXTQxtHjZgXoBbDyomf+GCCwFNfYwTgjWil1JHmo='
````
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.4.2
Cluster Name    vault-cluster-a3619f9c
Cluster ID      ad16dd4e-bc92-64f5-0735-2f2e0b203ce3
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active

`kubectl exec -it vault-1 -n ame -- vault operator unseal 'vQeoXTQxtHjZgXoBbDyomf+GCCwFNfYwTgjWil1JHmo='`

````
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.2
Cluster Name           vault-cluster-a3619f9c
Cluster ID             ad16dd4e-bc92-64f5-0735-2f2e0b203ce3
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
````


> kubectl exec -it vault-0 -- vault operator unseal
Unseal Key (will be hidden):
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.2
Cluster Name           vault-cluster-64aa5a17
Cluster ID             48400883-7e5d-2848-a241-0ac1cdb3a0d1
HA Enabled             true
HA Cluster             https://vault-1.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.123.1.7:8200
````
`kubectl exec -it vault-2 -n ame -- vault operator unseal 'vQeoXTQxtHjZgXoBbDyomf+GCCwFNfYwTgjWil1JHmo='`


````
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.2
Cluster Name           vault-cluster-a3619f9c
Cluster ID             ad16dd4e-bc92-64f5-0735-2f2e0b203ce3
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.0.1.11:8200
````
+ Выполним `kubectl exec -it vault-0 -n ame -- vault auth list`.

+ Получим ошибку:

```
Error listing enabled authentications: Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/auth
Code: 400. Errors:

* missing client token
command terminated with exit code 2
````
## ==Залогинимся в vault:

`kubectl exec -it vault-0 -- vault login`

````
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.vpKIYWXsrGKl6L69oKQxGEsM
token_accessor       DeCFWBhWjmn3OKGwDJbwP6nq
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
````

+ Повторно запросим список авторизаций:

`kubectl exec -it vault-0  -- vault auth list`

````
Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_8652be1a    token based credentials
````
## ==Заведем секреты:

`kubectl exec -it vault-0  -- vault secrets enable --path=otus kv`

````
Success! Enabled the kv secrets engine at: otus/
````
`kubectl exec -it vault-0  -- vault secrets list --detailed`

````
Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----
cubbyhole/    cubbyhole    cubbyhole_a4c98e6d    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           d09e0fd9-ca83-f4a4-5f18-6f9b6325e2ef
identity/     identity     identity_bc533430     system         system     false             replicated     false        false                      map[]      identity store                                             bc06bf2d-6427-13ad-221b-e989b363d1d1
otus/         kv           kv_abd03cf8           system         system     false             replicated     false        false                      map[]      n/a                                                        919f3a49-ecaa-a208-ff02-5df1f4b6c012
sys/          system       system_6d20c580       n/a            n/a        false             replicated     false        false                      map[]      system endpoints used for control, policy and debugging    ab82236b-a259-29d6-7b83-8643fce2126e
````

`kubectl exec -it vault-0  -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'`


````
Success! Data written to: otus/otus-ro/config
````

`exec -it vault-0  -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'`

````
Success! Data written to: otus/otus-rw/config
````

`kubectl exec -it vault-0  -- vault read otus/otus-ro/config`

````
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus
````

`kubectl exec -it vault-0  -- vault kv get otus/otus-rw/config`

````
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus
````
## ==Включим авторизацию черерз k8s:


`kubectl exec -it vault-0 -- vault auth enable kubernetes`

````
Success! Enabled kubernetes auth method at: kubernetes/
````


`kubectl exec -it vault-0  -- vault auth list`

````
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_17d55492    n/a
token/         token         auth_token_e50bea17         token based credentials
````
## ==Создадим yaml для ClusterRoleBinding:

`vault-auth-service-account.yml`

````yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: vault-auth
    namespace: default
````
## ==Создадим Service Account vault-auth и применим ClusterRoleBinding:

`kubectl create serviceaccount vault-auth`

````
serviceaccount/vault-auth created
`````
`kubectl apply -f vault-auth-service-account.yml`

````
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
````

## ==Подготовим переменные для записи в конфиг кубер авторизации:

````
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')
````
## ==Запишем конфиг в vault:

````
kubectl exec -it vault-0  -- vault write auth/kubernetes/config \
token_reviewer_jwt="$SA_JWT_TOKEN" \
kubernetes_host="$K8S_HOST" \
kubernetes_ca_cert="$SA_CA_CRT"
Success! Data written to: auth/kubernetes/config
````

## ==Создадим файл политики:

`otus-policy.hcl`

````json
path "otus/otus-ro/*" {
  capabilities = ["read", "list",]
}
path "otus/otus-rw/*" {
  capabilities = ["read", "create", "list",]
}
````

## ==Создадим политку и роль в vault:

`kubectl cp otus-policy.hcl  vault-0:/home/vault`

`kubectl exec -it vault-0  -- vault policy write otus-policy /home/vault/otus-policy.hcl`

````
kubectl exec -it vault-0  -- vault policy write otus-policy /home/vault/otus-policy.hcl
````

````
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy ttl=24h
````
````
Success! Data written to: auth/kubernetes/role/otus
````

## =Создадим роль и политику

````
kubectl exec -it vault-0 -- vault write auth/kubernetes/config \ token_reviewer_jwt="$SA_JWT_TOKEN" \
kubernetes_host="$K8S_HOST" \
kubernetes_ca_cert="$SA_CA_CRT"
````
`Success! Data written to: auth/kubernetes/config`

```hcl
path "otus/otus-ro/*" {
  capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
  capabilities = ["read", "create", "list"]
}
````

````
> kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
Success! Uploaded policy: otus-policy
````

## Проверяем как работает авторизация

 - Создадим под с привязанным сервис аккоунтом и установим туда curl и jq

````
kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image alpine:3.7
apk add curl jq
````

- Логинимся и получаем клиентский токен:

````
curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
{
  "request_id": "2af65405-1324-9b34-cd1a-77f2d8e9badb",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": null,
  "wrap_info": null,
  "warnings": null,
  "auth": {
    "client_token": "s.q8YHiRZd6mkfByRn4BcpB6mm",
    "accessor": "pB3VsxHkPnISD82QQtbIImCz",
    "policies": [
      "default",
      "otus-policy"
    ],
    "token_policies": [
      "default",
      "otus-policy"
    ],
    "metadata": {
      "role": "otus",
      "service_account_name": "vault-auth",
      "service_account_namespace": "default",
      "service_account_secret_name": "vault-auth-token-rmwxz",
      "service_account_uid": "615c6a4f-8885-446c-ac78-c5026d718dca"
    },
    "lease_duration": 86400,
    "renewable": true,
    "entity_id": "188b9a87-f440-bcdf-0da7-165865147264",
    "token_type": "service",
    "orphan": true
  }
}

TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')
````

## ==Прочитаем записанные ранее секреты и попробуем их обновить

- Используем свой клиентский токен.
- Проверим чтение

````
curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config | jq
{
  "request_id": "3a29647c-8e75-4d56-7ed9-d641819c2dda",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}

curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq
{
  "request_id": "48e1eab4-ebd5-b109-4fe7-ac080e7118c3",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
````
- Проверим запись в otus-ro/config:

````
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.SCbMdIL61rqmyqrCUldd1ocw" $VAULT_ADDR/v1/otus/otus-ro/config | jq

{
  "errors": [
    "1 error occurred:\n\t* permission denied\n\n"
  ]
}
````

- Проверим запись в otus-ro/config1:

`curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq`

````
curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq
{
  "request_id": "922fb606-f383-ecf6-6173-06ef2e9c3fcc",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
````

- Проверим запись в otus-ro/config1:

````
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq

{
  "errors": [
    "1 error occurred:\n\t* permission denied\n\n"
  ]
}
````
Доступ запрещен, так как у нас нет прав на обновление `otus/otus-ro/*`

Обновим otus-policy.hcl

- Применим новые политики:

````
kubectl cp otus-policy.hcl vault-0:/home/vault
kubectl exec -it vault-0 -- vault policy write otus-policy /home/vault/otus-policy.hcl
Success! Uploaded policy: otus-policy
````

- Пробуем снова записать:

````
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq

curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq
{
  "request_id": "509645a1-bd6a-704e-c663-2d94ef465176",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
````
OK!

## ==Use case использования авторизации через кубер

- Авторизуемся через vault-agent и получим клиентский токен

- Через consul-template достанем секрет и положим его в nginx

- Итог - nginx получил секрет из волта, не зная ничего про vault


## ==Заберем репозиторий с примерами

`git clone https://github.com/hashicorp/vault-guides.git``

`cd vault-guides/identity/vault-agent-k8s-demo`

- В каталоге configs-k8s скорректируем конфиги с учетом ранее созданых ролей и секретов

- Проверим и скорректируем конфиг example-k8s-spec.yml

## ==Запускаем

````
kubectl apply -f configmap.yaml
configmap/example-vault-agent-config created
````

````
kubectl get configmap example-vault-agent-config -o yaml
apiVersion: v1
data:
  consul-template-config.hcl: |
    vault {
        renew_token = false
        vault_agent_token_file = "/home/vault/.vault-token"
        retry {
            backoff = "1s"
        }
    }

    template {
    destination = "/etc/secrets/index.html"
    contents = <<EOT
    <html>
    <body>
    <p>Some secrets:</p>
    {{- with secret "otus/otus-ro/config" }}
    <ul>
    <li><pre>username: {{ .Data.data.username }}</pre></li>
    <li><pre>password: {{ .Data.data.password }}</pre></li>
    </ul>
    {{ end }}
    </body>
    </html>
    EOT
    }
  vault-agent-config.hcl: |
    # Comment this out if running as sidecar instead of initContainer
    exit_after_auth = true

    pid_file = "/home/vault/pidfile"

    auto_auth {
        method "kubernetes" {
            mount_path = "auth/kubernetes"
            config = {
                role = "otus"
            }
        }

        sink "file" {
            config = {
                path = "/home/vault/.vault-token"
            }
        }
    }
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"consul-template-config.hcl":"vault {\n    renew_token = false\n    vault_agent_token_file = \"/home/vault/.vault-token\"\n    retry {\n        backoff = \"1s\"\n    }\n}\n\ntemplate {\ndestination = \"/etc/secrets/index.html\"\ncontents = \u003c\u003cEOT\n\u003chtml\u003e\n\u003cbody\u003e\n\u003cp\u003eSome secrets:\u003c/p\u003e\n{{- with secret \"otus/otus-ro/config\" }}\n\u003cul\u003e\n\u003cli\u003e\u003cpre\u003eusername: {{ .Data.data.username }}\u003c/pre\u003e\u003c/li\u003e\n\u003cli\u003e\u003cpre\u003epassword: {{ .Data.data.password }}\u003c/pre\u003e\u003c/li\u003e\n\u003c/ul\u003e\n{{ end }}\n\u003c/body\u003e\n\u003c/html\u003e\nEOT\n}\n","vault-agent-config.hcl":"# Comment this out if running as sidecar instead of initContainer\nexit_after_auth = true\n\npid_file = \"/home/vault/pidfile\"\n\nauto_auth {\n    method \"kubernetes\" {\n        mount_path = \"auth/kubernetes\"\n        config = {\n            role = \"otus\"\n        }\n    }\n\n    sink \"file\" {\n        config = {\n            path = \"/home/vault/.vault-token\"\n        }\n    }\n}\n"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"example-vault-agent-config","namespace":"default"}}
  creationTimestamp: "2020-07-05T13:47:17Z"
  name: example-vault-agent-config
  namespace: default
  resourceVersion: "20217"
  selfLink: /api/v1/namespaces/default/configmaps/example-vault-agent-config
  uid: 0a3d745d-bec6-11ea-ba06-42010aa40094
````

````
kubectl apply -f example-k8s-spec.yaml
pod/vault-agent-example created
````

## == Сделаем проверку

- Законнектимся к поду nginx и вытащим оттуда index.html

````
kubectl exec -ti vault-agent-example -c nginx-container  -- cat /usr/share/nginx/html/index.html
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>
````


## ==Создадим CA на базе vault

- Включим pki secrets

````
kubectl exec -it vault-0 -- vault secrets enable pki
Success! Enabled the pki secrets engine at: pki/
````

````
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
Success! Tuned the secrets engine at: pki/
````

`kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="example.ru" ttl=87600h > CA_cert.crt`

## ==Пропишем урлы для ca и отозванных сертификатов

````
kubectl exec -it vault-0 -- vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"
Success! Data written to: pki/config/urls
````

## ==Создадим промежуточный сертификат

````
exec -it vault-0 -- vault secrets enable --path=pki_int pki
Success! Enabled the pki secrets engine at: pki_int/
````

````
exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
Success! Tuned the secrets engine at: pki_int/
````

`kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr`


## ==Пропишем промежуточный сертификат в vault

````
kubectl cp pki_intermediate.csr vault-0:./tmp/

kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem

kubectl cp intermediate.cert.pem vault-0:./tmp/

kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
Success! Data written to: pki_int/intermediate/set-signed
````

## ==Создадим и отзовем новые сертификаты

- Создадим роль для выдачи сертификатов

````
kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru \
allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"

Success! Data written to: pki_int/roles/example-dot-ru
````

- Создадим сертификат

````
kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="test.example.ru" ttl="24h"
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUbs1EMMtsCfGi2jGitWn72jXprjcwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDA2MTYxNjQzNDhaFw0yNTA2
MTUxNjQ0MThaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALhxdC24BpMK
/tkUdItpGgxQsRpp7tTf/6o/RXCblZjHMKsHRhhAdW/Ww57jdCI91Sx30VR4dr6P
0dXLJ/c0VY7PyiH/91j5cmnJGj8fKIKodMei9vNdI+hYKoe4FNc/a1kfKEsUHfGf
QRr2ORwXmEMUyYros+DHUrYoeIMQP+8XJtQQjHCEByWYM6Tgpt4y6pzaRGN97yFs
UlMQmhyh7daRXKX/A4Tx1h/qhbCAjjGTtOKcssaWX6mu+uaY3zNVaWsbPgrL6erD
XEII8Ojh9Mx1StSKjwJfyOCJMVbY5t5xCZfYkOTXGOmuZ4mp3wj5ufgce21NQXwt
vujWMuPrZGECAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUWRZvC2QKvzWdmOhtPRKElhpzywkwHwYDVR0jBBgwFoAU
6RO2+EqqFpHyVMR0ya+hy3a7nF4wNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
cXHrM3Cji8lGKIn7O6CnnEnPiiyTxw7QTxJqBZJcGjL5SU/sqDp1cXXupRwHo7Gv
NdqM47HGGpixSekUGqjrlPdKX7/vylFGsh/F8MMOPhIXibBGASL3od+r5fhDVcdk
89Va80qpXx1rNfhphN3YrvNKj6DQSqh4dvlQNkJdj5v+65/vSK52aSilO8h7MIDd
RDc3Hew6dn5URDYueKHzcQ5rn0hg65W+9qeDhdRgcwz9GPJG0adC+RzJGlJE3GKN
aE4fj0ibnC6YJ++1GEPfAmkVuY7YUyUXNK1N3T1B4dzNFqeJ/Mr+pbIssGg9kQ2Z
DjHb8ySUM3JfZp2nQw5/iA==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDYzCCAkugAwIBAgIUU1UayYucW3SW43Etoz1kACntbucwDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIwMDYxNjE2NDg1MVoXDTIwMDYxNzE2NDkyMVowGjEYMBYGA1UEAxMPdGVz
dC5leGFtcGxlLnJ1MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAt+GI
RVjssgZgL240kXg+52zE9Yt6ToJI+gXs4wi7BSo68OJHGg8txN2lEOyMNx3Km64B
+Yxs3VGqXorMJgXcaYvbW+wgXFb+zqm6BN3jhVDiAOkmzJaaUtU0E6na/41olOX6
X1wLbkyU2bnV4K4J7KNjVXsGY0e0XZWu6nbfCy1vE5wtcrr8/9I723h6HW26g4cE
MPTXva2sTb/OBoPOozra/aPIYyJsgnPzNbC9SomqrSExXD7XyPzW6QsBOz3xotBZ
lQArT7GxK5BHBo2+Y94E7yGaGUKhfzjKDBVhOziAN3ZczUj/hlmIpB9+ptb140h3
dwuR8sOSQkZNP3XoPQIDAQABo4GOMIGLMA4GA1UdDwEB/wQEAwIDqDAdBgNVHSUE
FjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwHQYDVR0OBBYEFOV6+X88HiFwdYKR6YER
bQWmXSxyMB8GA1UdIwQYMBaAFFkWbwtkCr81nZjobT0ShJYac8sJMBoGA1UdEQQT
MBGCD3Rlc3QuZXhhbXBsZS5ydTANBgkqhkiG9w0BAQsFAAOCAQEAF1E87BGiE67a
8bgbAmAMBZl4tY0XxB9NwO3fqCEVMvgxY4xT3SSQFVJPdN3ZOgOeCxtQ3k88lv0s
I9mZ44uZREDbLx9kMBfWpMwi3JsOjaSjwo/qMbyOUwOkkpSMtoBgolhsXii0PMe2
LRGZbEM4qCTgdgayVDvMUMA1zXUAaIrNRl3GHvWJiNCjtOYDyQFZ+Py+cTuogrPo
pHNAXrvM+ImnsNBHh9iWTN4MJP3rUHEZl4mb7ndy1s7YQjZxd6cCcX6m4fpt0m/e
tbobikyARh248etGSEaoUAjF+9WnMk1fihzRVRhpqV/W/Ix5wiDxfJXTFf7csZub
XZIV134kyg==
-----END CERTIFICATE-----
expiration          1592412561
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUbs1EMMtsCfGi2jGitWn72jXprjcwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDA2MTYxNjQzNDhaFw0yNTA2
MTUxNjQ0MThaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALhxdC24BpMK
/tkUdItpGgxQsRpp7tTf/6o/RXCblZjHMKsHRhhAdW/Ww57jdCI91Sx30VR4dr6P
0dXLJ/c0VY7PyiH/91j5cmnJGj8fKIKodMei9vNdI+hYKoe4FNc/a1kfKEsUHfGf
QRr2ORwXmEMUyYros+DHUrYoeIMQP+8XJtQQjHCEByWYM6Tgpt4y6pzaRGN97yFs
UlMQmhyh7daRXKX/A4Tx1h/qhbCAjjGTtOKcssaWX6mu+uaY3zNVaWsbPgrL6erD
XEII8Ojh9Mx1StSKjwJfyOCJMVbY5t5xCZfYkOTXGOmuZ4mp3wj5ufgce21NQXwt
vujWMuPrZGECAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUWRZvC2QKvzWdmOhtPRKElhpzywkwHwYDVR0jBBgwFoAU
6RO2+EqqFpHyVMR0ya+hy3a7nF4wNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
cXHrM3Cji8lGKIn7O6CnnEnPiiyTxw7QTxJqBZJcGjL5SU/sqDp1cXXupRwHo7Gv
NdqM47HGGpixSekUGqjrlPdKX7/vylFGsh/F8MMOPhIXibBGASL3od+r5fhDVcdk
89Va80qpXx1rNfhphN3YrvNKj6DQSqh4dvlQNkJdj5v+65/vSK52aSilO8h7MIDd
RDc3Hew6dn5URDYueKHzcQ5rn0hg65W+9qeDhdRgcwz9GPJG0adC+RzJGlJE3GKN
aE4fj0ibnC6YJ++1GEPfAmkVuY7YUyUXNK1N3T1B4dzNFqeJ/Mr+pbIssGg9kQ2Z
DjHb8ySUM3JfZp2nQw5/iA==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAt+GIRVjssgZgL240kXg+52zE9Yt6ToJI+gXs4wi7BSo68OJH
Gg8txN2lEOyMNx3Km64B+Yxs3VGqXorMJgXcaYvbW+wgXFb+zqm6BN3jhVDiAOkm
zJaaUtU0E6na/41olOX6X1wLbkyU2bnV4K4J7KNjVXsGY0e0XZWu6nbfCy1vE5wt
crr8/9I723h6HW26g4cEMPTXva2sTb/OBoPOozra/aPIYyJsgnPzNbC9SomqrSEx
XD7XyPzW6QsBOz3xotBZlQArT7GxK5BHBo2+Y94E7yGaGUKhfzjKDBVhOziAN3Zc
zUj/hlmIpB9+ptb140h3dwuR8sOSQkZNP3XoPQIDAQABAoIBABXe8mllKUoHbhtW
HVSMG9dE3axi+Zoq7ukmGUXrvOrhWf9auqBD2+rFfiOkLw1DMt0PdlarOCue0gfK
tHt1SQEYzG+Dh1nUUxxbna+EgNJTi34WPTIqW5KsnzQTiOPKevzy2bPL6+QjobS/
4MuHh9CoomEBcAIQ/kf/TL3Ag8j9W8dEe/lFz6n2f7PnbXCWV0bQa7b2mc73F5sC
xWhATeR0QAKJtPUmgPuHNio1+vvVYu62ulEEJgxRrwcqejSAJyRbNi4qPnwzN0nI
x4MEFlzuF7V21oGkovlMPwLybnFSQ+A4FGaiBObEb6IxSRHh2CYwP/t74efiQvzD
gVNwYDUCgYEA4lJDO1C2XOc2ANvrACYEVwXl6+ZVQOwZTN2sMDa4+T/6MQu8ED3j
3LQ4NrQUv5CSsi0ru3g/uIbIZmsVl9KVdWibBiflH3XcGK0Gmuydj26+32sMn1IL
B1cPl4ovlFjDB82D/w8jirdp5bcrAhZhys7uKnaglzaWTxURioG4RqMCgYEAz/6F
zKsr5+2VHWUPx8zsAQbRhNH8aCpBTDjbisuyVDrR6CdhafRUAL8nFs6E/uHKFX7i
3wZdzV6F6G8yON6laO7CdhgyPnH3X6VBeg64NX4OV/E6tyyo+9zZFiinD2Wa1mxg
4/nF1kGblOoZuGVnvCwmVv6EfAo8V0ZYuCKbY58CgYEA3sZWw4Y5W82DjOjss2K4
luiJX+GEPbmpVc5F9deH0GE3ZxvD7MDfEJqdUsuEOOSYYaaxC4HcR0j07kuuH5n7
4GwtXKvcj1E2a1u1yr3qggti+wymihT6IimCgYpWN1H/+ChGK8S9GYhdRu87+HwL
mtSB/25xuSbUYde9QndZ6r0CgYBw1MIApVrMFjYuHATTfncIl4pRYxhp6YJCtxVh
1d6HkuEL71EJCWIIhanO1XmQSyw1PQAVvH5mSkCaNrgn4aAZrGwRZE7dUTXAzQUY
EaQcYKWnT1VqyO9isguR2bvGvnegmmp1Qanw8OZVgikxvtDnY4vo5Wk5YNQbBC5c
tWlWQQKBgQCc77OYAbK6STzcnq3Y5lbGEbPilsZFW9j4mJueOdIJ+zVABagjcdRj
O2ES9nYeeE2H9026Z4KFhCwH3EXEsuDNBDAOiJtt2G9Jyd2uHfsp5J/m7BIKo9Sa
qdWT93qzqGlKeeqeO9M60kupzxJ+piAR4R0TpiS4FnL4qJLnL70now==
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       53:55:1a:c9:8b:9c:5b:74:96:e3:71:2d:a3:3d:64:00:29:ed:6e:e7
````

- Отзовем сертификат

````
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="53:55:1a:c9:8b:9c:5b:74:96:e3:71:2d:a3:3d:64:00:29:ed:6e:e7"
Key                        Value
---                        -----
revocation_time            1592326196
revocation_time_rfc3339    2020-06-16T16:49:56.117712099Z
````

## ==Включим TLS

- Создим CSR

openssl genrsa -out vault_gke.key 4096

`openssl req -config vault_gke_csr.cnf -new -key vault_gke.key -nodes -out vault.csr``

`openssl req -config vault_gke_csr.cnf -new -key vault_gke.key -nodes -out vault.csr`

- Применяем

````
kubectl apply -f vault_csr.yaml
certificatesigningrequest.certificates.k8s.io/vaultcsr created

kubectl certificate approve vaultcsr
certificatesigningrequest.certificates.k8s.io/vaultcsr approved

kubectl get csr vaultcsr -o jsonpath='{.status.certificate}' | base64 --decode > vault.crt

kubectl create secret tls vault-certs --cert=vault.crt --key=vault_gke.key
````


- Пересоздадим vault с новым vault-tls.values.yaml

````
helm upgrade --install vault hashicorp/vault -f vault-tls.values.yaml
Release "vault" does not exist. Installing it now.
NAME: vault
LAST DEPLOYED: Tue Jun 16 23:56:52 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get vault
````

Проверяем:

````
kubectl get secret $(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}") -o jsonpath="{.data['ca\.crt']}" | base64 --decode  > ca.crt

kubectl port-forward vault-0 8200:8200

curl --cacert ca.crt  -H "X-Vault-Token: s.Q4JOojZtdGgfiwoxJ4L3v75w" -X GET https://localhost:8200/v1/otus/otus-ro/config | jq
{
  "request_id": "ecda370b-4696-43b5-d7ad-158736974806",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
````

## ==Настроим автообновление сертификатов

 - Запустим nginx
 - Реализуем автообнвление сертификатов для nginx c помощью vault-inject

Подготовим policy:

````hcl
path "pki_int/issue/*" {
    capabilities = ["create", "read", "update", "list"]
}
````

Применим:

````
kubectl cp nginx/nginx-policy.hcl vault-0:/home/vault
kubectl exec -it vault-0 -- vault policy write nginx-policy /home/vault/nginx-policy.hcl
Success! Uploaded policy: pki-policy

kubectl exec -it vault-0 -- vault write auth/kubernetes/role/nginx-role \
        bound_service_account_names=vault-auth \
        bound_service_account_namespaces=default policies=nginx-policy ttl=24h
````


Добавим анотации в поду:

````
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-status: "update"
        vault.hashicorp.com/role: "nginx-role"
        vault.hashicorp.com/agent-inject-secret-server.cert: "pki_int/issue/example-dot-ru"
        vault.hashicorp.com/agent-inject-template-server.cert: |
          {{- with secret "pki_int/issue/example-dot-ru" "common_name=nginx.example.ru" "ttl=2m" -}}
          {{ .Data.certificate }}
          {{- end }}
        vault.hashicorp.com/agent-inject-secret-server.key: "pki_int/issue/example-dot-ru"
        vault.hashicorp.com/agent-inject-template-server.key: |
          {{- with secret "pki_int/issue/example-dot-ru" "common_name=nginx.example.ru" "ttl=2m" -}}
          {{ .Data.private_key }}
          {{- end }}
        vault.hashicorp.com/service: "http://vault:8200"
        vault.hashicorp.com/agent-inject-command-server.key: "/bin/sh -c 'pkill -HUP nginx || true'"
````

Применим:

````
kubectl apply -f nginx/nginx-configMap.yaml -f nginx/nginx-service.yaml -f nginx/nginx-deployment.yaml
configmap/nginx-config created
service/nginx created
deployment.apps/nginx created
````

## kuberenetes-gitops

### ==Подготовка GitLab репозитория==

 - Переместим в проект microservices-demo код из GitHub репозитория:

````
git clone https://github.com/GoogleCloudPlatform/microservices-democd microservices-demogit remote add gitlab git@gitlab.com:volkmydj/microservices-demo.gitgit remote remove origingit push gitlab master
`````

### ==Создание Helm чартов==

 - Подготовим Helm чарты для каждого микросервиса.

 - Во всех манифестах, описывающих deployment, обязательно параметризуем  название образа и его тег:

 ````yaml
image:
  repository: frontend
  tag: v0.0.1
`````

- Получаем следующий результат:

````
tree -L 1 deploy/charts
deploy/charts
├── adservice
├── cartservice
├── checkoutservice
├── currencyservice
├── emailservice
├── frontend
├── loadgenerator
├── paymentservice
├── productcatalogservice
├── recommendationservice
└── shippingservice
````

### ==Подготовка Kubernetes кластера==

- Развернем managed Kubernetes кластер в GCP с Istio как аддон GKE:

`terraform init && terraform apply`

````
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

dev_output = {
  "cluster_endpoint" = "35.195.131.29"
  "external_ip_address" = "35.240.72.173"
}
````

## ==Continuous Integration==

- Соберем Docker образы для всех микросервисов и поместим данныеобразы в Docker Hub.

`make build && make push`

 - При тегировании образов используем подход `semver` , например, первому собранному образу логично выставить тег `v0.0.1`

 ## ==Подготовка==

 - Произведем установку Flux в кластер, в namespace flux:

````
helm upgrade --install flux fluxcd/flux -f flux.values.yaml --namespace flux --create-namespace
Release "flux" does not exist. Installing it now.
NAME: flux
LAST DEPLOYED: Tue Jul 14 11:54:49 2020
NAMESPACE: flux
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Get the Git deploy key by either (a) running

  kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2

or by (b) installing fluxctl through
https://docs.fluxcd.io/en/latest/references/fluxctl#installing-fluxctl
and running:

  fluxctl identity --k8s-fwd-ns flux
````

 - Установим Helm operator:

`helm upgrade --install helm-operator fluxcd/helm-operator -f helm-operator.values.yaml --namespace flux`

````
helm upgrade --install helm-operator fluxcd/helm-operator -f helm-operator.values.yaml --namespace flux
Release "helm-operator" does not exist. Installing it now.
NAME: helm-operator
LAST DEPLOYED: Tue Jul 14 11:59:23 2020
NAMESPACE: flux
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Flux Helm Operator docs https://docs.fluxcd.io

Example:

AUTH_VALUES=$(cat <<-END
usePassword: true
password: "redis_pass"
usePasswordFile: true
END
)

kubectl create secret generic redis-auth --from-literal=values.yaml="$AUTH_VALUES"

cat <<EOF | kubectl apply -f -
apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: redis
  namespace: default
spec:
  releaseName: redis
  chart:
    repository: https://kubernetes-charts.storage.googleapis.com
    name: redis
    version: 10.5.7
  valuesFrom:
  - secretKeyRef:
      name: redis-auth
  values:
    master:
      persistence:
        enabled: false
    volumePermissions:
      enabled: true
    metrics:
      enabled: true
    cluster:
      enabled: false
EOF

watch kubectl get hr
````

- Установим fluxctl на локальную машину для управления нашим CDинструментом. Руководство по установке

````
brew install fluxctl
export FLUX_FORWARD_NAMESPACE=flux
````

- Добавим в свой профиль GitLab публичный ssh-ключ,при помощи которого flux получит доступ к нашему git-репозиторию:

Значение ключа можно получить командой:

`fluxctl identity --k8s-fwd-ns flux`

 Пришло время проверить корректность работы Flux. Как мы уже знаем, Flux умеет автоматически синхронизировать состояние кластера и репозитория. Это касается не только сущностей HelmRelease, которыми мы будем оперировать для развертывания приложения, но и обыкновенных манифестов.

Поместим манифест, описывающий namespace microservices-demo в директорию deploy/namespaces и сделаем push в GitLab:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: microservices-demo
````

Если все предыдущие шаги проделаны верно - в кластере через некоторое время будет создан namespace microservices-demo:

````
kubectl get ns
NAME                 STATUS   AGE
default              Active   61m
flux                 Active   19m
istio-system         Active   60m
kube-node-lease      Active   61m
kube-public          Active   61m
kube-system          Active   61m
microservices-demo   Active   55s
````

Также  в  логах  pod  с  flux  должна  появиться  строка,  описывающаядействия данного инструмента:

````
kubectl logs -n flux flux-5f56548c47-tmddx | grep "kubectl apply -f"
ts=2020-07-14T09:13:29.652807422Z caller=sync.go:606 method=Sync cmd="kubectl apply -f -" took=1.213519592s err=null output="namespace/microservices-demo created"
````

### ==HelmRelease==

Мы  подобрались  к  сущностям,  которыми  управляет  helm-operator - `HelmRelease`. \
Для описания сущностей такого вида создадим отдельную директорию `deploy/releases`  и  поместим  туда  файл `frontend.yaml`  с  описанием конфигурации релиза.

Опишем некоторые части манифеста HelmRelease:

1. Аннотация разрешает автоматическое обновление релиза в Kubernetes кластере в случае изменения версии Docker образа в Registry.

2. Указываем Flux следить за обновлениями конкретных Docker образовв Registry.

Новыми считаются только образы, имеющие версию выше текущей и отвечающие маске семантического версионирования ~0.0 (например,0.0.1, 0.0.72, но не 1.0.0).

3. Helm chart, используемый для развертывания релиза. В нашем случае указываем git-репозиторий, и директорию с чартом внутри него.

4. Переопределяем переменные Helm chart. В дальнейшем Flux может сампереписывать эти значения и делать commit в git-репозиторий (например,изменять тег Docker образа при его обновлении в Registry)


### ==HelmRelease | Проверка==

 - Убедимся  что  HelmRelease  для  микросервиса  frontend  появился  вкластере:

````
kubectl get helmrelease -n microservices-demo
NAME       RELEASE   PHASE       STATUS   MESSAGE                                                                       AGE
frontend             Succeeded            Release was successful for Helm release 'frontend' in 'microservices-demo'.   73s
````
 - По статусу мы можем понять, что релиз применился успешно, и frontendзапущен. Дополнительно проверим это:

````
helm list -n microservices-demo
NAME            NAMESPACE               REVISION        UPDATED                                 STATUS          CHART           APP VERSION
frontend        microservices-demo      1               2020-07-14 18:40:11.033116958 +0000 UTC deployed        frontend-0.21.0 1.16.0
````
>  Командой  `fluxctl --k8s-fwd-ns flux sync`   можно инициировать синхронизацию вручную.


### ==Обновление образа==

1. Внесем изменение в исходный код микросервиса frontend и пересоберем образ, при этом инкрементирова в версию тега (до v0.0.2)

2. Дождемся автоматического обновления релиза в Kubernetes кластере(для просмотра ревизий релиза можно использовать команду `helm history frontend -n microservices-demo``

````
helm history frontend -n microservices-demo
REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
1               Tue Jul 14 18:40:11 2020        superseded      frontend-0.21.0 1.16.0          Install complete
2               Tue Jul 14 18:57:17 2020        deployed        frontend-0.21.0 1.16.0          Upgrade complete
````

3. Проверим, изменилось ли что-либо в git-репозитории (в частности, в файле `deploy/releases/frontend.yaml`)

````yaml
  values:
    image:
      repository: volkmydj/frontend
      tag: v0.0.2
````

### ==Обновление Helm chart==

 - Попробуем внести изменения в Helm chart `frontend` и поменять имя `deployment` на `frontend-hipster`

 - Сделаем push измененного Helm chart в GitLab и понаблюдаем за процессом

> Найдем в логах helm-operator строки, указывающие на механизм проверки изменений в Helm chart и определения необходимости обновить релиз. Приложим данные строки к описанию PR.

```
ts=2020-07-14T19:19:55.354921513Z caller=helm.go:69 component=helm version=v3 info="preparing upgrade for frontend" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:19:55.360631247Z caller=helm.go:69 component=helm version=v3 info="resetting values to the chart's original version" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:19:55.885389378Z caller=helm.go:69 component=helm version=v3 info="performing update for frontend" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:19:55.914393614Z caller=helm.go:69 component=helm version=v3 info="creating upgraded release for frontend" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:19:55.932189265Z caller=helm.go:69 component=helm version=v3 info="checking 4 resources for changes" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:19:55.942262228Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for Service \"frontend\"" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:19:55.961311866Z caller=helm.go:69 component=helm version=v3 info="Created a new Deployment called \"frontend\" in microservices-demo\n" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:19:55.975967644Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for Gateway \"frontend\"" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:19:55.999913696Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for VirtualService \"frontend\"" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:19:56.026395866Z caller=helm.go:69 component=helm version=v3 info="updating status for upgraded release for frontend" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:19:56.10520717Z caller=release.go:309 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="upgrade succeeded" revision=bc50fcfe093048c5e7879c2b160745f7c222aa60 phase=upgrade
ts=2020-07-14T19:20:36.42813845Z caller=release.go:75 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="starting sync run"
ts=2020-07-14T19:20:36.688995131Z caller=release.go:251 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="running dry-run upgrade to compare with release version '4'" action=dry-run-compare
ts=2020-07-14T19:20:36.692345569Z caller=helm.go:69 component=helm version=v3 info="preparing upgrade for frontend" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:20:36.698738803Z caller=helm.go:69 component=helm version=v3 info="resetting values to the chart's original version" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:20:37.191880904Z caller=helm.go:69 component=helm version=v3 info="performing update for frontend" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:20:37.203999765Z caller=helm.go:69 component=helm version=v3 info="dry run for frontend" targetNamespace=microservices-demo release=frontend
ts=2020-07-14T19:20:37.228984538Z caller=release.go:273 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="no changes" phase=dry-run-compare
````

### ==Самостоятельное задание==

 - Добавьте манифесты HelmRelease для всех микросервисов входящих всостав HipsterShop
 - Проверим, что все микросервисы успешно развернулись в Kubernetes кластере

````
kubectl get helmrelease -n microservices-demo
NAME                    RELEASE                 PHASE       STATUS     MESSAGE                                                                                    AGE
adservice               adservice               Succeeded   deployed   Release was successful for Helm release 'adservice' in 'microservices-demo'.               62s
cartservice             cartservice             Succeeded   deployed   Release was successful for Helm release 'cartservice' in 'microservices-demo'.             62s
checkoutservice         checkoutservice         Succeeded   deployed   Release was successful for Helm release 'checkoutservice' in 'microservices-demo'.         62s
currencyservice         currencyservice         Succeeded   deployed   Release was successful for Helm release 'currencyservice' in 'microservices-demo'.         62s
emailservice            emailservice            Succeeded   deployed   Release was successful for Helm release 'emailservice' in 'microservices-demo'.            62s
frontend                frontend                Succeeded   deployed   Release was successful for Helm release 'frontend' in 'microservices-demo'.                61m
loadgenerator           loadgenerator           Succeeded   deployed   Release was successful for Helm release 'loadgenerator' in 'microservices-demo'.           62s
paymentservice          paymentservice          Succeeded   deployed   Release was successful for Helm release 'paymentservice' in 'microservices-demo'.          62s
productcatalogservice   productcatalogservice   Succeeded   deployed   Release was successful for Helm release 'productcatalogservice' in 'microservices-demo'.   62s
recommendationservice   recommendationservice   Succeeded   deployed   Release was successful for Helm release 'recommendationservice' in 'microservices-demo'.   62s
shippingservice         shippingservice         Succeeded   deployed   Release was successful for Helm release 'shippingservice' in 'microservices-demo'.         62s
````

````
kubectl get po -n microservices-demo
NAME                                     READY   STATUS     RESTARTS   AGE
adservice-55f877744c-khl7s               1/1     Running    0          24m
cartservice-d8b7586f8-xzg5h              1/1     Running    1          24m
cartservice-redis-master-0               1/1     Running    0          24m
checkoutservice-69d884b5f7-l7fmh         1/1     Running    0          24m
currencyservice-77fd6f945-l6ptn          1/1     Running    0          24m
emailservice-665ccb9557-j8pgp            1/1     Running    0          24m
frontend-b6f7c8f8f-l8sst                 1/1     Running    0          44m
loadgenerator-6fcbb4ffdd-9qwxx           0/1     Init:0/1   0          51s
paymentservice-7f74787749-bj8c4          1/1     Running    0          24m
productcatalogservice-6c9989c6b9-wg4w8   1/1     Running    0          24m
recommendationservice-554ccc4c5f-9zjsk   1/1     Running    0          24m
shippingservice-65558c8477-d7vbt         1/1     Running    0          24m
````

### ==Установка Istio==

Т.к. Istio у нас устанавливается как аддон к кластеру GKE, то этот шаг нам не понадобиться и мы можем установить просто утилиту:

`brew install istioctl`

### ==Установка Flagger==

1. Добавляем helm-репозиторий flagger:

````
helm repo add flagger https://flagger.app
"flagger" has been added to your repositories
````

2. Устанавливаем CRD для Flagger:

````
kubectl apply -fhttps://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml
customresourcedefinition.apiextensions.k8s.io/canaries.flagger.app created
customresourcedefinition.apiextensions.k8s.io/metrictemplates.flagger.app created
customresourcedefinition.apiextensions.k8s.io/alertproviders.flagger.app created
````

3. Установливаем flagger с указанием использовать Istio:

````
helm upgrade --install flagger flagger/flagger \
--namespace=istio-system \
--set crd.create=false \
--set meshProvider=istio \
--set metricsServer=http://prometheus:9090
````

````
Release "flagger" does not exist. Installing it now.
NAME: flagger
LAST DEPLOYED: Tue Jul 14 23:54:05 2020
NAMESPACE: istio-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Flagger installed
````

### ==Istio | Sidecar Injection==

 - Изменим созданное ранее описание namespace `microservices-demo`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: microservices-demo
  labels:
    istio-injection: enabled
````

Выделенная строка указывает на необходимость добавить в каждый podsidecar контейнер с envoy proxy.

> После  синхронизации  проверку  можно  выполнить  командой `kubectl get ns microservices-demo --show-labels``

````
kubectl get ns microservices-demo --show-labels
NAME                 STATUS   AGE   LABELS
microservices-demo   Active   11h   fluxcd.io/sync-gc-mark=sha256.nR39Qg0XG0r3h4OKBshXoTK_gbhpeoAzKUK1fUzNmNg,istio-injection=enabled
````

 - Самый простой способ добавить sidecar контейнер в уже запущенныеpod - удалить их:

````
kubectl delete pods --all -n microservices-demo
pod "adservice-55f877744c-khl7s" deleted
pod "cartservice-d8b7586f8-xzg5h" deleted
pod "cartservice-redis-master-0" deleted
pod "checkoutservice-69d884b5f7-l7fmh" deleted
pod "currencyservice-77fd6f945-l6ptn" deleted
pod "emailservice-665ccb9557-j8pgp" deleted
pod "frontend-b6f7c8f8f-8xf9n" deleted
pod "loadgenerator-694489f785-8zthq" deleted
pod "paymentservice-7f74787749-bj8c4" deleted
pod "productcatalogservice-6c9989c6b9-wg4w8" deleted
pod "recommendationservice-554ccc4c5f-9zjsk" deleted
pod "shippingservice-65558c8477-d7vbt" deleted
````

 - После  этого  можно  проверить,  что  контейнер  с  названием istio-proxy появился внутри каждого pod:

````
kubectl describe pod -l app=frontend -n microservices-demo
Name:           frontend-b6f7c8f8f-6mnbh
Namespace:      microservices-demo
Priority:       0
Node:           gke-dev-dev-ca0df695-5c1z/10.132.0.16
Start Time:     Wed, 15 Jul 2020 00:01:41 +0300
Labels:         app=frontend
                pod-template-hash=b6f7c8f8f
                security.istio.io/tlsMode=istio
Annotations:    cni.projectcalico.org/podIP: 10.8.3.16/32
                sidecar.istio.io/status:
                  {"version":"e08c22464c16dcd08d4d59263d2012385a58bd5e7871a19f2ea2ef2de85ceba3","initContainers":["istio-init"],"containers":["istio-proxy"]...
Status:         Running
IP:             10.8.3.16
Controlled By:  ReplicaSet/frontend-b6f7c8f8f
Init Containers:
  istio-init:
    Container ID:  docker://4745f25ed7cd8f8bbbd70eb36e4bc7c64aabc93b613a4f17b2f26f0a030b8cc5
    Image:         gke.gcr.io/istio/proxyv2:1.4.10-gke.4
    Image ID:      docker-pullable://gke.gcr.io/istio/proxyv2@sha256:4b40d7dd5401de80569c76c1d4aa8353d844f4d16b8153ebc125d37fad498e17
    Port:          <none>
    Host Port:     <none>
    Command:
      istio-iptables
      -p
      15001
      -z
      15006
      -u
      1337
      -m
      REDIRECT
      -i
      *
      -x

      -b
      *
      -d
      15020
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Wed, 15 Jul 2020 00:01:45 +0300
      Finished:     Wed, 15 Jul 2020 00:01:45 +0300
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     100m
      memory:  50Mi
    Requests:
      cpu:        10m
      memory:     10Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-cr9jm (ro)
Containers:
  server:
    Container ID:   docker://eb0cfe13aa07b50deee35a5bd2c141142d1641378be1720cb6835ac5f58e1980
    Image:          volkmydj/frontend:v0.0.2
    Image ID:       docker-pullable://volkmydj/frontend@sha256:9e2e159530bfcb46b4e403c84bb17683e4cbb1e99841ad3c4fb6a9cfcd5e9633
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Wed, 15 Jul 2020 00:01:50 +0300
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     200m
      memory:  128Mi
    Requests:
      cpu:      100m
      memory:   64Mi
    Liveness:   http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Environment:
      PORT:                          8080
      PRODUCT_CATALOG_SERVICE_ADDR:  productcatalogservice:3550
      CURRENCY_SERVICE_ADDR:         currencyservice:7000
      CART_SERVICE_ADDR:             cartservice:7070
      RECOMMENDATION_SERVICE_ADDR:   recommendationservice:8080
      SHIPPING_SERVICE_ADDR:         shippingservice:50051
      CHECKOUT_SERVICE_ADDR:         checkoutservice:5050
      AD_SERVICE_ADDR:               adservice:9555
      JAEGER_SERVICE_ADDR:           jaeger-collector.observability.svc.cluster.local:14268
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-cr9jm (ro)
  istio-proxy:
    Container ID:  docker://48e2e90a197bebf1f91b26f80c7808b90e45bb6155b79970f2ccdc932fe386aa
    Image:         gke.gcr.io/istio/proxyv2:1.4.10-gke.4
    Image ID:      docker-pullable://gke.gcr.io/istio/proxyv2@sha256:4b40d7dd5401de80569c76c1d4aa8353d844f4d16b8153ebc125d37fad498e17
    Port:          15090/TCP
    Host Port:     0/TCP
    Args:
      proxy
      sidecar
      --domain
      $(POD_NAMESPACE).svc.cluster.local
      --configPath
      /etc/istio/proxy
      --binaryPath
      /usr/local/bin/envoy
      --serviceCluster
      frontend.$(POD_NAMESPACE)
      --drainDuration
      45s
      --parentShutdownDuration
      1m0s
      --discoveryAddress
      istio-pilot.istio-system:15010
      --zipkinAddress
      zipkin.istio-system:9411
      --dnsRefreshRate
      300s
      --connectTimeout
      10s
      --proxyAdminPort
      15000
      --concurrency
      2
      --controlPlaneAuthPolicy
      NONE
      --statusPort
      15020
      --applicationPorts
      8080
    State:          Running
      Started:      Wed, 15 Jul 2020 00:01:51 +0300
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     2
      memory:  1Gi
    Requests:
      cpu:      100m
      memory:   128Mi
    Readiness:  http-get http://:15020/healthz/ready delay=1s timeout=1s period=2s #success=1 #failure=30
    Environment:
      POD_NAME:                          frontend-b6f7c8f8f-6mnbh (v1:metadata.name)
      ISTIO_META_POD_PORTS:              [
                                             {"name":"http","containerPort":8080,"protocol":"TCP"}
                                         ]
      ISTIO_META_CLUSTER_ID:             Kubernetes
      POD_NAMESPACE:                     microservices-demo (v1:metadata.namespace)
      INSTANCE_IP:                        (v1:status.podIP)
      SERVICE_ACCOUNT:                    (v1:spec.serviceAccountName)
      ISTIO_META_POD_NAME:               frontend-b6f7c8f8f-6mnbh (v1:metadata.name)
      ISTIO_META_CONFIG_NAMESPACE:       microservices-demo (v1:metadata.namespace)
      SDS_ENABLED:                       false
      ISTIO_META_INTERCEPTION_MODE:      REDIRECT
      ISTIO_META_INCLUDE_INBOUND_PORTS:  8080
      ISTIO_METAJSON_LABELS:             {"app":"frontend","pod-template-hash":"b6f7c8f8f"}

      ISTIO_META_WORKLOAD_NAME:          frontend
      ISTIO_META_OWNER:                  kubernetes://apis/apps/v1/namespaces/microservices-demo/deployments/frontend
    Mounts:
      /etc/certs/ from istio-certs (ro)
      /etc/istio/proxy from istio-envoy (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-cr9jm (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-cr9jm:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-cr9jm
    Optional:    false
  istio-envoy:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     Memory
    SizeLimit:  <unset>
  istio-certs:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  istio.default
    Optional:    true
QoS Class:       Burstable
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason     Age    From                                Message
  ----     ------     ----   ----                                -------
  Normal   Scheduled  2m29s  default-scheduler                   Successfully assigned microservices-demo/frontend-b6f7c8f8f-6mnbh to gke-dev-dev-ca0df695-5c1z
  Normal   Pulled     2m26s  kubelet, gke-dev-dev-ca0df695-5c1z  Container image "gke.gcr.io/istio/proxyv2:1.4.10-gke.4" already present on machine
  Normal   Created    2m26s  kubelet, gke-dev-dev-ca0df695-5c1z  Created container istio-init
  Normal   Started    2m25s  kubelet, gke-dev-dev-ca0df695-5c1z  Started container istio-init
  Normal   Pulling    2m25s  kubelet, gke-dev-dev-ca0df695-5c1z  Pulling image "volkmydj/frontend:v0.0.2"
  Normal   Pulled     2m20s  kubelet, gke-dev-dev-ca0df695-5c1z  Successfully pulled image "volkmydj/frontend:v0.0.2"
  Normal   Created    2m20s  kubelet, gke-dev-dev-ca0df695-5c1z  Created container server
  Normal   Started    2m20s  kubelet, gke-dev-dev-ca0df695-5c1z  Started container server
  Normal   Pulled     2m20s  kubelet, gke-dev-dev-ca0df695-5c1z  Container image "gke.gcr.io/istio/proxyv2:1.4.10-gke.4" already present on machine
  Normal   Created    2m19s  kubelet, gke-dev-dev-ca0df695-5c1z  Created container istio-proxy
  Normal   Started    2m19s  kubelet, gke-dev-dev-ca0df695-5c1z  Started container istio-proxy
  Warning  Unhealthy  2m18s  kubelet, gke-dev-dev-ca0df695-5c1z  Readiness probe failed: HTTP probe failed with statuscode: 503
````

### == Доступ к frontend==

На  текущий  момент  у  нас  отсутствует  ingress  и  мы  не  можем  получитьдоступ к frontend снаружи кластера.

В  то  же  время  Istio  в  качестве  альтернативы  классическому  ingressпредлагает свой набор абстракций.

Чтобы   настроить   маршрутизацию   трафика   к   приложению   сиспользованием  Istio,  нам  необходимо  добавить  ресурсы   и

 - Создаем  директорию `deploy/istio`  и  помещаем в нее  следующие манифесты:

- `frontend-vs.yaml`
- `frontend-gw.yaml`



### ==Istio | VirtualService==

`frontend-vs.yaml`

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend
  namespace: microservices-demo
spec:
  hosts:
    - "*"
  gateways:
    - frontend
  http:
    - route:
        - destination:
            host: frontend
            port:
              number: 80
````

### ==Istio | Gateway==

`frontend-gw.yaml`

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: frontend
  namespace: microservices-demo
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - "*"
````

 - Созданный Gateway можно увидеть следующим образом:

````
kubectl get gateway -n microservices-demo
NAME       AGE
frontend   46m
````

 - Для  доступа  снаружи  нам  понадобится  EXTERNAL-IP  сервиса `istio-ingressgateway`

````
kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                                                                                      AGE
istio-ingressgateway   LoadBalancer   10.11.251.158   104.199.16.158   15020:31756/TCP,80:30858/TCP,443:31456/TCP,31400:31469/TCP,15029:30773/TCP,15030:31894/TCP,15031:30644/TCP,15032:32562/TCP,15443:31236/TCP   13h
````

### ==Istio | Самостоятельное задание ==

В  нашей  ситуации  ресурсы `Gateway`  и `VirtualService`  логическия вляются  частью  инфраструктурного  кода,  описывающего  окружение микросервиса `frontend`.   Поэтому,   оправданно   будет   перенести манифесты в Helm chart.

Дополним  Helm  chart `frontend`  манифестами `gateway.yaml`  и `virtualService.yaml`.  Оригинальные  манифесты  удалим вместе  с директорией `deploy/istio`.

### ==Flagger | Canary==

Перейдем  непосредственно  к  настройке  канареечных  релизов.

 - Добавьте в Helm chart frontend еще один файл - `canary.yaml`

В  нем  будем  хранить  описание  стратегии,  по  которой  необходимообновлять данный микросервис.

`canary.yaml``

```yaml
apiVersion: flagger.app/v1alpha3
kind: Canary
metadata:
  name: frontend
  namespace: microservices-demo
spec:
  provider: istio
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend
  service:
    port: 80
    targetPort: 8080
    gateways:
    - frontend
    hosts:
    - "*"
    trafficPolicy:
      tls:
        mode: DISABLE
  analysis:
    interval: 30s
    threshold: 5
    maxWeight: 30
    stepWeight: 5
    metrics:
    - name: request-success-rate
      threshold: 99
      interval: 30s
````

Проверим, что Flagger:
 - Успешно инициализировал canary ресурс `frontend`:

````
NAME       STATUS        WEIGHT   LASTTRANSITIONTIME
frontend   Initialized   0        2020-07-14T22:15:05Z
````

- Обновил pod, добавив ему к названию постфикс `primary`:

````
kubectl get pods -n microservices-demo -l app=frontend-primary
NAME                                READY   STATUS    RESTARTS   AGE
frontend-primary-8665f87f76-pmzsv   2/2     Running   0          4m38s
````

 - Попробуем  провести  релиз.  Соберем  новый  образ  frontend  с  тегом v0.0.3 и сделаем push в Docker Hub.

Через  некоторое  время  в  выводе kubectl describe canaryfrontend -n  microservices-demo  мы  сможет  наблюдать  следующую картину:

`fluxctl list-images -n microservices-demo`

````
kubectl get canaries -n microservices-demo
NAME               STATUS        WEIGHT   LASTTRANSITIONTIME
frontend-boutique   Progressing   30       2020-07-14T18:49:40Z
````

````
kubectl get canaries -n microservices-demo
NAME               STATUS      WEIGHT   LASTTRANSITIONTIME
frontend-boutique   Succeeded   0        2020-07-14T18:51:09Z
````

````
microservices-demo:helmrelease/frontend                  chart-image        volkmydj/frontend
                                                                            '-> v0.0.6                      14 Jul 20 18:52 UTC
                                                                                v0.0.5                      14 Jul 20 18:52 UTC
                                                                                v0.0.4                      14 Jul 20 18:52 UTC
                                                                                v0.0.3                      14 Jul 20 18:52 UTC
                                                                                v0.0.2                      14 Jul 20 18:52 UTC
                                                                                v0.0.1                      14 Jul 20 07:09 UTC
````
`kubectl describe canary frontend -n microservices-demo`

````
  Normal   Synced  7m24s (x2 over 18m)    flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  5m54s                  flagger  New revision detected! Restarting analysis for frontend.microservices-demo
  Normal   Synced  5m24s (x3 over 18m)    flagger  Advance frontend.microservices-demo canary weight 5
  Normal   Synced  5m24s (x3 over 18m)    flagger  Starting canary analysis for frontend.microservices-demo
  Normal   Synced  4m54s (x2 over 6m23s)  flagger  Advance frontend.microservices-demo canary weight 10
  Normal   Synced  4m24s                  flagger  Advance frontend.microservices-demo canary weight 15
  Normal   Synced  3m53s                  flagger  Advance frontend.microservices-demo canary weight 20
  Normal   Synced  3m24s                  flagger  Advance frontend.microservices-demo canary weight 25
  Normal   Synced  2m53s                  flagger  Advance frontend.microservices-demo canary weight 30
  Normal   Synced  84s (x3 over 2m24s)    flagger  (combined from similar events): Promotion completed! Scaling down frontend.microservices-demo
````


### == Flagger | Задание со ⭐==

 - Реализуем канареечное развертывание для одного из оставшихся микросервисов, например `checkoutservice`

````
NAME              STATUS        WEIGHT   LASTTRANSITIONTIME
checkoutservice   Progressing   0        2020-07-15T18:16:22Z
frontend          Succeeded     0        2020-07-15T16:28:42Z
> kubectl get canary -n microservices-demo
NAME              STATUS        WEIGHT   LASTTRANSITIONTIME
checkoutservice   Progressing   5        2020-07-15T18:16:52Z
frontend          Succeeded     0        2020-07-15T16:28:42Z
> kubectl get canary -n microservices-demo
NAME              STATUS        WEIGHT   LASTTRANSITIONTIME
checkoutservice   Progressing   20       2020-07-15T18:18:22Z
frontend          Succeeded     0        2020-07-15T16:28:42Z
> kubectl get canary -n microservices-demo
NAME              STATUS        WEIGHT   LASTTRANSITIONTIME
checkoutservice   Progressing   25       2020-07-15T18:18:52Z
frontend          Succeeded     0        2020-07-15T16:28:42Z
> kubectl get canary -n microservices-demo
NAME              STATUS        WEIGHT   LASTTRANSITIONTIME
checkoutservice   Progressing   25       2020-07-15T18:18:52Z
frontend          Succeeded     0        2020-07-15T16:28:42Z
> kubectl get canary -n microservices-demo
NAME              STATUS      WEIGHT   LASTTRANSITIONTIME
checkoutservice   Promoting   0        2020-07-15T18:19:52Z
frontend          Succeeded   0        2020-07-15T16:28:42Z
> kubectl get canary -n microservices-demo
NAME              STATUS       WEIGHT   LASTTRANSITIONTIME
checkoutservice   Finalising   0        2020-07-15T18:20:22Z
frontend          Succeeded    0        2020-07-15T16:28:42Z
> kubectl get canary -n microservices-demo
NAME              STATUS      WEIGHT   LASTTRANSITIONTIME
checkoutservice   Succeeded   0        2020-07-15T18:20:52Z
frontend          Succeeded   0        2020-07-15T16:28:42Z
````

 - Реализуем получение нотификаций о релизах в Slack.

```
helm upgrade -i flagger flagger/flagger \
--namespace=istio-system \
--set crd.create=false \
--set meshProvider=istio \
--set metricsServer=http://prometheus:9090 \
--set slack.url=https://hooks.slack.com/services/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 \
--set slack.channel=flagger-notification \
--set slack.user=flagger
````


![alt text](screenshots/slack.png "Slack notification")​


### == Distributed Tracing | Задание со ⭐ ==

 - Установим Jaeger и научимся собирать трейсы:
   - Непосредственно с микросервисов
   - С sidecar контейнеров istio-proxy


Установим Jaeger с помощью istio оператора и профиля demo

````
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istio
spec:
  profile: demo
EOF
````

 - Трейсы с istio-proxy sidecar контейнеров доступны в стоке.

 - Для получения трейсов непосредственно из микросервисов следует указать в   `templates` манифестов деплойментов значение переменной окружения:

```yaml
env:
          - name: JAEGER_SERVICE_ADDR
            value: "jaeger-collector.observability.svc.cluster.local:14268"
````

 - `istioctl dashboard jaeger`

 - Переходим в UI jaeger и выбираем сервисы:
   - для istio-proxy: `<servicename>.microservice.demo`
   - для микросервисов: `<servicename>`

![alt text](screenshots/jaegger-1.png "Slack notification")​


![alt text](screenshots/jaegger-2.png "Slack notification")​


### == УстановкаIstio|Заданиесо⭐==

Используем istio-operator

`istioctl operator init`

`kubectl create ns istio-system`

````
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istio
spec:
  profile: demo
EOF

namespace/istio-system created
istiooperator.install.istio.io/istio created
````
 - Проверяем:

````
kubectl get po -n istio-system
NAME                                             READY   STATUS      RESTARTS   AGE
flagger-b969c54b8-xbntg                          1/1     Running     0          104m
grafana-5dc4b4676c-6lfnm                         1/1     Running     0          3h59m
istio-citadel-78b9b5b589-twmk9                   1/1     Running     0          7h47m
istio-egressgateway-57b9c7d65b-nttbx             0/1     Running     0          3h25m
istio-galley-79bd448645-5ntkz                    1/1     Running     0          7h47m
istio-ingressgateway-b4f8986c4-mblc9             1/1     Running     0          7h47m
istio-pilot-dc558d859-5v4fv                      2/2     Running     1          7h47m
istio-policy-8664dd6c4-lxcjf                     2/2     Running     3          7h47m
istio-security-post-install-1.4.10-gke.4-529pg   0/1     Completed   0          7h47m
istio-sidecar-injector-7f85d7f7c4-j4w5s          1/1     Running     0          7h47m
istio-telemetry-69b6477c5f-fswvt                 2/2     Running     4          7h47m
istio-tracing-8584b4d7f9-79z45                   1/1     Running     0          3h59m
istiod-7968744c5b-8tlj4                          1/1     Running     0          3h59m
kiali-6f457f5964-cblrm                           1/1     Running     0          3h59m
prometheus-7c4b6d955-qvtbq                       2/2     Running     0          3h59m
promsd-696bcc5b96-pjs2v                          2/2     Running     1          7h47m
````

````
kubectl get svc -n istio-system
NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                                                                                      AGE
grafana                     ClusterIP      10.11.243.71    <none>           3000/TCP                                                                                                                                     4h
istio-citadel               ClusterIP      10.11.247.234   <none>           8060/TCP,15014/TCP                                                                                                                           7h47m
istio-egressgateway         ClusterIP      10.11.251.0     <none>           80/TCP,443/TCP,15443/TCP                                                                                                                     4h
istio-galley                ClusterIP      10.11.243.29    <none>           443/TCP,15014/TCP,9901/TCP                                                                                                                   7h47m
istio-ingressgateway        LoadBalancer   10.11.255.207   104.155.29.231   15020:30675/TCP,80:31091/TCP,443:32711/TCP,31400:30430/TCP,15029:31296/TCP,15030:30199/TCP,15031:30021/TCP,15032:30114/TCP,15443:31830/TCP   7h47m
istio-pilot                 ClusterIP      10.11.254.170   <none>           15010/TCP,15011/TCP,8080/TCP,15014/TCP                                                                                                       7h47m
istio-policy                ClusterIP      10.11.240.19    <none>           9091/TCP,15004/TCP,15014/TCP                                                                                                                 7h47m
istio-sidecar-injector      ClusterIP      10.11.245.141   <none>           443/TCP,15014/TCP                                                                                                                            7h47m
istio-telemetry             ClusterIP      10.11.240.70    <none>           9091/TCP,15004/TCP,15014/TCP,42422/TCP                                                                                                       7h47m
istiod                      ClusterIP      10.11.248.83    <none>           15010/TCP,15012/TCP,443/TCP,15014/TCP,853/TCP                                                                                                4h
jaeger-agent                ClusterIP      None            <none>           5775/UDP,6831/UDP,6832/UDP                                                                                                                   4h
jaeger-collector            ClusterIP      10.11.253.132   <none>           14267/TCP,14268/TCP,14250/TCP                                                                                                                4h
jaeger-collector-headless   ClusterIP      None            <none>           14250/TCP                                                                                                                                    4h
jaeger-query                ClusterIP      10.11.253.203   <none>           16686/TCP                                                                                                                                    4h
kiali                       ClusterIP      10.11.245.148   <none>           20001/TCP                                                                                                                                    4h
prometheus                  ClusterIP      10.11.250.54    <none>           9090/TCP                                                                                                                                     4h
promsd                      ClusterIP      10.11.240.196   <none>           9090/TCP                                                                                                                                     7h47m
tracing                     ClusterIP      10.11.245.29    <none>           80/TCP                                                                                                                                       4h
zipkin                      ClusterIP      10.11.252.234   <none>           9411/TCP                                                                                                                                     4h
````


## kubernetes-storage

### Установка CSI драйвер и тестирование функционала snapshots:

1. Разворачиваем кластер kind:

`kind create cluster --config cluster/cluster.yaml `

2. Скачиваем репозиторий с CSI драйвером:

`git clone https://github.com/kubernetes-csi/csi-driver-host-path.git`

3. Устанавливаем VolumeSnapshot CRD и Snapshot controller. Применяем CRD:

```
export SNAPSHOTTER_VERSION=v2.0.1
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$SNAPSHOTTER_VERSION/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$SNAPSHOTTER_VERSION/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$SNAPSHOTTER_VERSION/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$SNAPSHOTTER_VERSION/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$SNAPSHOTTER_VERSION/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
```

4. Устанавливаем CSI драйвер:

`./csi-driver-host-path/deploy/kubernetes-1.18/deploy.sh`

5. Запускаем приложение:

`k apply -f hw/`

```
persistentvolumeclaim/storage-pvc unchanged
storageclass.storage.k8s.io/csi-hostpath-sc unchanged
volumesnapshot.snapshot.storage.k8s.io/snapshot unchanged
```

Проверяем:

```
kubectl get sc

NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
csi-hostpath-sc      hostpath.csi.k8s.io     Delete          Immediate              true                   89s
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  23m

kubectl get pvc

NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
storage-pvc   Bound    pvc-f8276ace-6060-43a8-a0d7-317e6eafbdfc   1Gi        RWO            csi-hostpath-sc   2m1s
kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS      REASON   AGE
pvc-f8276ace-6060-43a8-a0d7-317e6eafbdfc   1Gi        RWO            Delete           Bound    default/storage-pvc   csi-hostpath-sc            2m17s

kubectl get volumeattachment

NAME                                                                   ATTACHER              PV                                         NODE           ATTACHED   AGE
csi-54aa4d690d146fc9f2e2d38a887d01a67fe56bf2cd7015a25d758b29d20ccf79   hostpath.csi.k8s.io   pvc-f8276ace-6060-43a8-a0d7-317e6eafbdfc   kind-worker3   true       2m34s
```

```
kubectl describe pods/storage-pod
Name:         storage-pod
Namespace:    default
Priority:     0
Node:         kind-worker3/172.18.0.3
Start Time:   Sun, 16 Aug 2020 13:57:03 +0300
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"name":"storage-pod","namespace":"default"},"spec":{"containers":[{"image":"n...
Status:       Running
IP:           10.244.5.8
Containers:
  nginx:
    Container ID:   containerd://e3f02ae6ef90826be8d6e5fc7903aaaf7c8d7af19b86b663f6abba6126e95de8
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:b0ad43f7ee5edbc0effbc14645ae7055e21bc1973aee5150745632a24a752661
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Sun, 16 Aug 2020 13:57:19 +0300
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /data from custom-csi-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-xj5z8 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  custom-csi-volume:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  storage-pvc
    ReadOnly:   false
  default-token-xj5z8:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-xj5z8
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason                  Age        From                     Message
  ----     ------                  ----       ----                     -------
  Warning  FailedScheduling        <unknown>  default-scheduler        persistentvolumeclaim "storage-pvc" not found
  Warning  FailedScheduling        <unknown>  default-scheduler        running "VolumeBinding" filter plugin for pod "storage-pod": pod has unbound immediate PersistentVolumeClaims
  Warning  FailedScheduling        <unknown>  default-scheduler        running "VolumeBinding" filter plugin for pod "storage-pod": pod has unbound immediate PersistentVolumeClaims
  Normal   Scheduled               <unknown>  default-scheduler        Successfully assigned default/storage-pod to kind-worker3
  Normal   SuccessfulAttachVolume  20m        attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-f8276ace-6060-43a8-a0d7-317e6eafbdfc"
  Normal   Pulling                 20m        kubelet, kind-worker3    Pulling image "nginx"
  Normal   Pulled                  20m        kubelet, kind-worker3    Successfully pulled image "nginx"
  Normal   Created                 20m        kubelet, kind-worker3    Created container nginx
  Normal   Started                 20m        kubelet, kind-worker3    Started container nginx
```

6. Создаем тестовые данные:

```
kubectl exec -ti storage-pod bash
root@storage-pod:/# cd data
root@storage-pod:/data# echo 'Hello Otus!' > index.html
root@storage-pod:/data# cat index.html
Hello Otus!
```
7. Создаем shapshot:

```
kubectl apply -f hw/snapshot.yaml
volumesnapshot.snapshot.storage.k8s.io/snapshot created
```
Проверяем:

```
kubectl get volumesnapshot
NAME       AGE
snapshot   20s
```

```
kubectl describe volumesnapshot snapshot
Name:         snapshot
Namespace:    default
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"snapshot.storage.k8s.io/v1beta1","kind":"VolumeSnapshot","metadata":{"annotations":{},"name":"snapshot","namespace":"defaul...
API Version:  snapshot.storage.k8s.io/v1beta1
Kind:         VolumeSnapshot
Metadata:
  Creation Timestamp:  2020-08-16T11:28:29Z
  Finalizers:
    snapshot.storage.kubernetes.io/volumesnapshot-as-source-protection
    snapshot.storage.kubernetes.io/volumesnapshot-bound-protection
  Generation:  1
  Managed Fields:
    API Version:  snapshot.storage.k8s.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        f:creationTime:
        f:readyToUse:
        f:restoreSize:
    Manager:         snapshot-controller
    Operation:       Update
    Time:            2020-08-16T11:28:41Z
  Resource Version:  11693
  Self Link:         /apis/snapshot.storage.k8s.io/v1beta1/namespaces/default/volumesnapshots/snapshot
  UID:               4db5bfbf-191f-44b0-aed7-8127bb39cae1
Spec:
  Source:
    Persistent Volume Claim Name:  storage-pvc
  Volume Snapshot Class Name:      csi-hostpath-snapclass
Status:
  Bound Volume Snapshot Content Name:  snapcontent-4db5bfbf-191f-44b0-aed7-8127bb39cae1
  Creation Time:                       2020-08-16T11:28:41Z
  Ready To Use:                        true
  Restore Size:                        1Gi
Events:                                <none>
```

```
kubectl get volumesnapshotcontents.snapshot.storage.k8s.io
NAME                                               AGE
snapcontent-4db5bfbf-191f-44b0-aed7-8127bb39cae1   4m9s
```

```
k describe volumesnapshotcontents.snapshot.storage.k8s.io snapcontent-4db5bfbf-191f-44b0-aed7-8127bb39cae1
Name:         snapcontent-4db5bfbf-191f-44b0-aed7-8127bb39cae1
Namespace:
Labels:       <none>
Annotations:  <none>
API Version:  snapshot.storage.k8s.io/v1beta1
Kind:         VolumeSnapshotContent
Metadata:
  Creation Timestamp:  2020-08-16T11:28:29Z
  Finalizers:
    snapshot.storage.kubernetes.io/volumesnapshotcontent-bound-protection
  Generation:  1
  Managed Fields:
    API Version:  snapshot.storage.k8s.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:finalizers:
          .:
          v:"snapshot.storage.kubernetes.io/volumesnapshotcontent-bound-protection":
    Manager:      snapshot-controller
    Operation:    Update
    Time:         2020-08-16T11:28:29Z
    API Version:  snapshot.storage.k8s.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        .:
        f:creationTime:
        f:readyToUse:
        f:restoreSize:
        f:snapshotHandle:
    Manager:         csi-snapshotter
    Operation:       Update
    Time:            2020-08-16T11:28:41Z
  Resource Version:  11692
  Self Link:         /apis/snapshot.storage.k8s.io/v1beta1/volumesnapshotcontents/snapcontent-4db5bfbf-191f-44b0-aed7-8127bb39cae1
  UID:               216d0047-d046-4bf5-b66a-ccce0a85e281
Spec:
  Deletion Policy:  Delete
  Driver:           hostpath.csi.k8s.io
  Source:
    Volume Handle:             36b4835a-dfaf-11ea-8144-a697fca2c3c3
  Volume Snapshot Class Name:  csi-hostpath-snapclass
  Volume Snapshot Ref:
    API Version:       snapshot.storage.k8s.io/v1beta1
    Kind:              VolumeSnapshot
    Name:              snapshot
    Namespace:         default
    Resource Version:  11644
    UID:               4db5bfbf-191f-44b0-aed7-8127bb39cae1
Status:
  Creation Time:    1597577321708866976
  Ready To Use:     true
  Restore Size:     1073741824
  Snapshot Handle:  a31f2481-dfb3-11ea-8144-a697fca2c3c3
Events:             <none>
```

Проверяем snapshot непосредственно на ноде:

```
docker exec -ti kind-worker3 bash
root@kind-worker3:/# cd /var/lib/csi-hostpath-data/
root@kind-worker3:/var/lib/csi-hostpath-data# ls -lah
total 16K
drwxr-xr-x  3 root root 4.0K Aug 16 11:28 .
drwxr-xr-x 13 root root 4.0K Aug 16 10:47 ..
drwxr-xr-x  2 root root 4.0K Aug 16 11:23 36b4835a-dfaf-11ea-8144-a697fca2c3c3
-rw-r--r--  1 root root  146 Aug 16 11:28 a31f2481-dfb3-11ea-8144-a697fca2c3c3.snap
```

8. Удаляем pod,pvc,pv:

```
kubectl delete pod storage-pod
pod "storage-pod" deleted

kubectl delete pvc storage-pvc
persistentvolumeclaim "storage-pvc" deleted

kubectl get pv
No resources found.

kubectl get pvc
No resources found.
```

9. Выполняем восстановление:

```
kubectl apply -f hw/restore.yaml
persistentvolumeclaim/storage-pvc created
```

```
kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
storage-pvc   Bound    pvc-e7b36e89-0c09-40d9-8ba5-1c2fe66f8aec   1Gi        RWO            csi-hostpath-sc   39s
```

```
kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS      REASON   AGE
pvc-e7b36e89-0c09-40d9-8ba5-1c2fe66f8aec   1Gi        RWO            Delete           Bound    default/storage-pvc   csi-hostpath-sc            2m1s
```
Проверяем наличие восстановленных данных:

```
kubectl apply -f hw/pod.yaml
pod/storage-pod created
```

```
kubectl exec storage-pod -- ls -l /data
total 4
-rw-r--r-- 1 root root 12 Aug 16 11:23 index.html
```


### Задание со 🌟. Развернуть k8s-кластер,к которому добавить хранилище на iSCSI

Задание выполнялось на заранее развернутом кластере на голом железе, с помощью kubespray. В качестве хранилища была поднята ВМ на OS Centos 7 в той же подсети.

1. На хосте ISCSI отключаем SELinux
2. Также отключаем firewall:

```
systemctl disable firewalld
systemctl stop firewalld
```
3. Устанавливаем taregtd и targetcli:

```
yum install targetd targetcli -y
```
4. Создаем volume group для targetd:

```
pvcreate /dev/sdb
vgcreate vg-targetd /dev/sdb
```
5. Разрешаем доступ RPC для targetd, редактированием файла `/etc/target/targetd.yaml`

```
# See http://www.yaml.org/spec/1.2/spec.html for more on YAML.
#
# A sample /etc/target/targetd.yaml file.
#

# No default password, please pick a good one.

password: 123qweASD

# defaults below; uncomment and edit
#block_pools: [vg-targetd/thin_pool] # just 1 by default, but can be more
#fs_pools: []  # Path to btrfs FS, eg. /my_btrfs_mount
target_name: iqn.2020-09.org.linux-iscsi.kuber:targetd
pool_name: vg-targetd
user: admin

# log level (debug, info, warning, error, critical)
#log_level: info

ssl: false
# if ssl is activated:
#ssl_cert: /etc/target/targetd_cert.pem
#ssl_key: /etc/target/targetd_key.pem
```

6. Запускаем и активируем targetd:

```
systemctl enable --now targetd
```
Проверяем:

```
[root@iscs ~]# systemctl status targetd
● targetd.service - targetd storage array API daemon
   Loaded: loaded (/usr/lib/systemd/system/targetd.service; enabled; vendor preset: disabled)
   Active: active (running) since Вс 2020-09-06 07:04:19 EDT; 3h 14min ago
 Main PID: 1646 (targetd)
   CGroup: /system.slice/targetd.service
           └─1646 targetd

сен 06 07:04:19 iscs.lanit systemd[1]: Started targetd storage array API daemon.
сен 06 07:04:20 iscs.lanit targetd[1646]: INFO:root:started server (TLS no)
```

7. На каждой рабочей ноде кластера устанавливаем iscsi-initiator-utils:

`yum install -y iscsi-initiator-utils`

8. Меняем имя инициаора в файле `/etc/iscsi/initiatorname.iscsi`

`InitiatorName=iqn.1994-05.com.redhat:node1`

9. Перезапускаем сервис:

`systemctl restart iscsid`

10. Создаем secret:

`kubectl create secret generic targetd-account --from-literal=username=admin --from-literal=password=superpassword`

11. Скачиваем манифест и правим в нем версию API и целевой аддресс:

`wget https://raw.githubusercontent.com/ansilh/kubernetes-the-hardway-virtualbox/master/config/iscsi-provisioner-d.yaml`

```yaml
kind: Deployment
apiVersion: apps/v1
```

```yaml
- name: TARGETD_ADDRESS
```
Также добавляем права RBAC на создание endpoint:

```yaml
- apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "delete", "update"]
```

10. Применяем манифест:

`kubectl apply -f iscsi-provisioner-d.yaml`

11. Скачиваем манифесты PersistentVolumeClaim и StorageClass. Меняем в них значения на свои:

```
wget https://raw.githubusercontent.com/ansilh/kubernetes-the-hardway-virtualbox/master/config/iscsi-provisioner-class.yaml

wget https://raw.githubusercontent.com/ansilh/kubernetes-the-hardway-virtualbox/master/config/iscsi-provisioner-pvc.yaml
```

`iscsi-provisioner-class.yaml`

```yaml
parameters:
  # this id where the iscsi server is running
  targetPortal: 172.30.24.176:3260

  # this is the iscsi server iqn
  iqn: iqn.2020-09.org.linux-iscsi.kuber:targetd

  # this is the iscsi interface to be used, the default is default
  # iscsiInterface: default

  # this must be on eof the volume groups condifgured in targed.yaml, the default is vg-targetd
  # volumeGroup: vg-targetd

  # this is a comma separated list of initiators that will be give access to the created volumes, they must correspond to what you have configured in your nodes.
  initiators: iqn.1994-05.com.redhat:node1,iqn.1994-05.com.redhat:node2,iqn.1994-05.com.redhat:node3
```
12. Применяем манифесты:

```
kubectl apply -f iscsi-provisioner-class.yaml
kubectl apply -f iscsi-provisioner-pvc.yaml
```
13. Проверяем созданный pvc и pv:

```
kubectl get pvc
NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS               AGE
myclaim   Bound    pvc-1a439b94-8d4c-4374-a035-d02736cf7128   100Mi      RWO            iscsi-targetd-vg-targetd   135m
```

```
kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS               REASON   AGE
postgres-pv-volume                         5Gi        RWX            Retain           Bound    ncc/postgres-pv-claim   manual                              44d
pvc-1a439b94-8d4c-4374-a035-d02736cf7128   100Mi      RWO            Delete           Bound    default/myclaim         iscsi-targetd-vg-targetd            72s
```

14. На хосте с scsi проверяем:

```
targetcli ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 1]
  | | o- vg-targetd:pvc-1a439b94-8d4c-4374-a035-d02736cf7128  [/dev/vg-targetd/pvc-1a439b94-8d4c-4374-a035-d02736cf7128 (100.0MiB) write-thru activated]
  | |   o- alua ................................................................................................... [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 1]
  | o- iqn.2020-09.org.linux-iscsi.kuber:targetd ......................................................................... [TPGs: 1]
  |   o- tpg1 ............................................................................................... [no-gen-acls, no-auth]
  |     o- acls .......................................................................................................... [ACLs: 3]
  |     | o- iqn.1994-05.com.redhat:node1 ......................................................................... [Mapped LUNs: 1]
  |     | | o- mapped_lun0 ................................... [lun0 block/vg-targetd:pvc-1a439b94-8d4c-4374-a035-d02736cf7128 (rw)]
  |     | o- iqn.1994-05.com.redhat:node2 ......................................................................... [Mapped LUNs: 1]
  |     | | o- mapped_lun0 ................................... [lun0 block/vg-targetd:pvc-1a439b94-8d4c-4374-a035-d02736cf7128 (rw)]
  |     | o- iqn.1994-05.com.redhat:node3 ......................................................................... [Mapped LUNs: 1]
  |     |   o- mapped_lun0 ................................... [lun0 block/vg-targetd:pvc-1a439b94-8d4c-4374-a035-d02736cf7128 (rw)]
  |     o- luns .......................................................................................................... [LUNs: 1]
  |     | o- lun0  [block/vg-targetd:pvc-1a439b94-8d4c-4374-a035-d02736cf7128 (/dev/vg-targetd/pvc-1a439b94-8d4c-4374-a035-d02736cf7128) (default_tg_pt_gp)]
  |     o- portals .................................................................................................... [Portals: 1]
  |       o- 0.0.0.0:3260 ..................................................................................................... [OK]
  o- loopback ......................................................................................................... [Targets: 0]
```

```
[root@iscs ~]# lvs
  LV                                       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  home                                     centos     -wi-ao---- <25,12g
  root                                     centos     -wi-ao----  50,00g
  swap                                     centos     -wi-ao----  <3,88g
  pvc-1a439b94-8d4c-4374-a035-d02736cf7128 vg-targetd -wi-ao---- 100,00m
```

## kubernetes-debug

1. Разворачиваем GKE кластер:

`terraform init && terraform apply`

```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

dev_output = {
  "cluster_endpoint" = "34.76.232.151"
  "external_ip_address" = "35.240.2.228"
}
```

2. Устанвливаем в кластер kubectl debug

``

3. Применяем манифест debug-агента:

```
kubectl apply -f strace/agent_daemonset.yml
daemonset.apps/debug-agent created
```

4. Запустим под с приложением:

```
kubectl apply -f strace/nginx.yaml
pod/nginx created
```

5. Запустим debug:

```
kubectl-debug nginx --agentless=false --port-forward=true
Forwarding from 127.0.0.1:10027 -> 10027
Forwarding from [::1]:10027 -> 10027
Handling connection for 10027
                             pulling image docker.io/nicolaka/netshoot:latest...
latest: Pulling from nicolaka/netshoot
cbdbe7a5bc2a: Pull complete
fa7edde5704a: Pull complete
d142e371ed28: Pull complete
7bc9cb006bce: Pull complete
a4d2c327d444: Pull complete
428e55c983a8: Pull complete
1209022df24d: Pull complete
b74093e72c31: Pull complete
Digest: sha256:04786602e5a9463f40da65aea06fe5a825425c7df53b307daa21f828cfe40bf8
Status: Downloaded newer image for nicolaka/netshoot:latest
starting debug container...
container created, open tty...
bash-5.0#
```

```
ash-5.0# strace -p 1
strace: attach: ptrace(PTRACE_SEIZE, 1): Operation not permitted
```

Видим, что не хватает привелегий. Меняем tag имиджа на latest.

```yaml
containers:
  - image: aylei/debug-agent:latest
```
```
kubectl apply -f strace/agent_daemonset.yml
daemonset.apps/debug-agent configured
```
```
kubectl-debug nginx --agentless=false --port-forward=true
Forwarding from [::1]:10027 -> 10027
Forwarding from 127.0.0.1:10027 -> 10027
Handling connection for 10027
                             pulling image docker.io/nicolaka/netshoot:latest...
latest: Pulling from nicolaka/netshoot
cbdbe7a5bc2a: Pull complete
fa7edde5704a: Pull complete
d142e371ed28: Pull complete
7bc9cb006bce: Pull complete
a4d2c327d444: Pull complete
428e55c983a8: Pull complete
1209022df24d: Pull complete
b74093e72c31: Pull complete
Digest: sha256:04786602e5a9463f40da65aea06fe5a825425c7df53b307daa21f828cfe40bf8
Status: Downloaded newer image for nicolaka/netshoot:latest
starting debug container...
container created, open tty...
bash-5.0#
```

Проверяем:

```
bash-5.0# strace -p 1
strace: Process 1 attached
rt_sigsuspend([], 8
```

### iptables-tailer

Один из полезных инструментов, который был упомянут, но не показан на лекции - это `kube-iptables-tailer`. Он предназначен для того, чтобы выводить информацию об отброшенных iptables пакетах в журнал событий Kubernetes ( kubectl get events )
Основной кейс - сообщить разработчикам сервисов о проблемах с NetworkPolicy.

1. Установим netperf-operator

 - Это Kubernetes-оператор, который позволяет запускать тесты пропускной способности сети между нодами кластера
 - Сам проект - не очень production-grade, но иногда выручает

```
kubectl apply -f https://raw.githubusercontent.com/piontec/netperf-operator/master/deploy/crd.yaml
customresourcedefinition.apiextensions.k8s.io/netperfs.app.example.com created
kubectl apply -f https://raw.githubusercontent.com/piontec/netperf-operator/master/deploy/rbac.yaml
role.rbac.authorization.k8s.io/netperf-operator created
rolebinding.rbac.authorization.k8s.io/default-account-netperf-operator created
deployment.apps/netperf-operator created
kubectl apply -f https://raw.githubusercontent.com/piontec/netperf-operator/master/deploy/cr.yaml
netperf.app.example.com/example created
```
Проверяем:

```
kubectl describe netperf.app.example.com/example
Name:         example
Namespace:    default
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"app.example.com/v1alpha1","kind":"Netperf","metadata":{"annotations":{},"name":"example","namespace":"default"}}
API Version:  app.example.com/v1alpha1
Kind:         Netperf
Metadata:
  Creation Timestamp:  2020-09-13T14:17:45Z
  Generation:          4
  Resource Version:    13469
  Self Link:           /apis/app.example.com/v1alpha1/namespaces/default/netperfs/example
  UID:                 729c57b8-5f7c-41ad-8611-5ee88cc54c32
Spec:
  Client Node:
  Server Node:
Status:
  Client Pod:          netperf-client-5ee88cc54c32
  Server Pod:          netperf-server-5ee88cc54c32
  Speed Bits Per Sec:  8942.17
  Status:              Done
Events:                <none>
```
Видим статус `Done` и скорость `Speed Bits Per Sec:  8942.17`

2. Добавляем сетевую политику для Calico, чтобы ограничить доступ к подам Netperf и включить логирование в iptables:

```
kubectl apply -f kit/netperf-calico-policy.yaml
networkpolicy.crd.projectcalico.org/netperf-calico-policy created
```

Перезапускаем тест:

```
kubectl delete -f kit/deploy/cr.yaml
netperf.app.example.com "example" deleted

kubectl apply -f kit/deploy/cr.yaml
netperf.app.example.com/example created
```

Проверяем:

```
kubectl describe netperf.app.example.com/example
Name:         example
Namespace:    default
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"app.example.com/v1alpha1","kind":"Netperf","metadata":{"annotations":{},"name":"example","namespace":"default"}}
API Version:  app.example.com/v1alpha1
Kind:         Netperf
Metadata:
  Creation Timestamp:  2020-09-13T14:28:49Z
  Generation:          3
  Resource Version:    16596
  Self Link:           /apis/app.example.com/v1alpha1/namespaces/default/netperfs/example
  UID:                 d9113fb5-450a-41a7-9b2c-7359138d99eb
Spec:
  Client Node:
  Server Node:
Status:
  Client Pod:          netperf-client-7359138d99eb
  Server Pod:          netperf-server-7359138d99eb
  Speed Bits Per Sec:  0
  Status:              Started test
Events:                <none>
```
Видим, что тест висит в статусе Started test. Вероятно в сетевой политике есть ошибка.

3. Подключимся к ноде, чтобы посмотреть в чем дело:

`gcloud compute ssh gke-dev-dev-dc63acf8-t53h`

```
sudo journalctl -k | grep calico
Sep 13 14:28:52 gke-dev-dev-dc63acf8-t53h kernel: calico-packet: IN=califa8af9931bb OUT=cali99a7f9ac281 MAC=ee:ee:ee:ee:ee:ee:26:0d:35:67:3b:75:08:00 SRC=10.0.4.13 DST=10.0.4.12 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=56977 DF PROTO=TCP SPT=58445 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
Sep 13 14:28:53 gke-dev-dev-dc63acf8-t53h kernel: calico-packet: IN=califa8af9931bb OUT=cali99a7f9ac281 MAC=ee:ee:ee:ee:ee:ee:26:0d:35:67:3b:75:08:00 SRC=10.0.4.13 DST=10.0.4.12 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=56978 DF PROTO=TCP SPT=58445 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
Sep 13 14:28:55 gke-dev-dev-dc63acf8-t53h kernel: calico-packet: IN=califa8af9931bb OUT=cali99a7f9ac281 MAC=ee:ee:ee:ee:ee:ee:26:0d:35:67:3b:75:08:00 SRC=10.0.4.13 DST=10.0.4.12 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=56979 DF PROTO=TCP SPT=58445 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
Sep 13 14:28:59 gke-dev-dev-dc63acf8-t53h kernel: calico-packet: IN=califa8af9931bb OUT=cali99a7f9ac281 MAC=ee:ee:ee:ee:ee:ee:26:0d:35:67:3b:75:08:00 SRC=10.0.4.13 DST=10.0.4.12 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=56980 DF PROTO=TCP SPT=58445 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
Sep 13 14:29:07 gke-dev-dev-dc63acf8-t53h kernel: calico-packet: IN=califa8af9931bb OUT=cali99a7f9ac281 MAC=ee:ee:ee:ee:ee:ee:26:0d:35:67:3b:75:08:00 SRC=10.0.4.13 DST=10.0.4.12 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=56981 DF PROTO=TCP SPT=58445 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
Sep 13 14:29:24 gke-dev-dev-dc63acf8-t53h kernel: calico-packet: IN=califa8af9931bb OUT=cali99a7f9ac281 MAC=ee:ee:ee:ee:ee:ee:26:0d:35:67:3b:75:08:00 SRC=10.0.4.13 DST=10.0.4.12 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=62700 DF PROTO=TCP SPT=47587 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
```

Не очень удобно.

4. Установим iptables-tailer

Предваритеьно исправим его манифест:

```yaml
env:
  - name: "JOURNAL_DIRECTORY"
    value: "/var/log/journal"
  - name: "IPTABLES_LOG_PREFIX"
    value: "calico-packet:"
```

```
kubectl apply -f kit/deploy/kit-serviceaccount.yaml
serviceaccount/kube-iptables-tailer created
kubectl apply -f kit/deploy/kit-clusterrole.yaml
clusterrole.rbac.authorization.k8s.io/kube-iptables-tailer created
kubectl apply -f kit/deploy/kit-clusterrolebinding.yaml
clusterrolebinding.rbac.authorization.k8s.io/kube-iptables-tailer created
kubectl apply -f kit/deploy/iptables-tailer.yaml
daemonset.extensions/kube-iptables-tailer created
```

Снова перезапустим тест:

```
kubectl delete -f kit/deploy/cr.yaml
netperf.app.example.com "example" deleted
```
```
kubectl apply -f kit/deploy/cr.yaml
netperf.app.example.com/example created
```

Проверяем:

```
kubectl describe po netperf-server-b2306feabaed
Name:           netperf-server-b2306feabaed
Namespace:      default
Priority:       0
Node:           gke-dev-dev-775f4ceb-4rsd/10.132.0.56
Start Time:     Sun, 13 Sep 2020 17:47:10 +0300
Labels:         app=netperf-operator
                netperf-type=server
Annotations:    cni.projectcalico.org/podIP: 10.0.5.3/32
                kubernetes.io/limit-ranger: LimitRanger plugin set: cpu request for container netperf-server-b2306feabaed
Status:         Running
IP:             10.0.5.3
Controlled By:  Netperf/example
Containers:
  netperf-server-b2306feabaed:
    Container ID:   docker://5460dd42c64460bf57088b48961273a9b1fdd52476198b95eb595a2fc5b9bcd9
    Image:          tailoredcloud/netperf:v2.7
    Image ID:       docker-pullable://tailoredcloud/netperf@sha256:0361f1254cfea87ff17fc1bd8eda95f939f99429856f766db3340c8cdfed1cf1
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Sun, 13 Sep 2020 17:47:13 +0300
    Ready:          True
    Restart Count:  0
    Requests:
      cpu:        100m
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-vgpxn (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-vgpxn:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-vgpxn
    Optional:    false
QoS Class:       Burstable
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason      Age    From                                Message
  ----     ------      ----   ----                                -------
  Normal   Scheduled   5m38s  default-scheduler                   Successfully assigned default/netperf-server-b2306feabaed to gke-dev-dev-775f4ceb-4rsd
  Normal   Pulling     5m37s  kubelet, gke-dev-dev-775f4ceb-4rsd  Pulling image "tailoredcloud/netperf:v2.7"
  Normal   Pulled      5m35s  kubelet, gke-dev-dev-775f4ceb-4rsd  Successfully pulled image "tailoredcloud/netperf:v2.7"
  Normal   Created     5m35s  kubelet, gke-dev-dev-775f4ceb-4rsd  Created container netperf-server-b2306feabaed
  Normal   Started     5m35s  kubelet, gke-dev-dev-775f4ceb-4rsd  Started container netperf-server-b2306feabaed
  Warning  PacketDrop  5m33s  kube-iptables-tailer                Packet dropped when receiving traffic from 10.0.4.15
  Warning  PacketDrop  3m19s  kube-iptables-tailer                Packet dropped when receiving traffic from client (10.0.4.15)
```

Обратим внимание на Events, паеты дропаются.


### Задание со ⭐

- Исправим ошибку в сетевой политике, чтобы Netperf снова начал работать

```yaml
ingress:
  - action: Allow
    source:
      selector: app == "netperf-operator"
  - action: Log
  - action: Deny
egress:
  - action: Allow
    destination:
      selector: app == "netperf-operator"
  - action: Log
  - action: Deny
```
Также необходимо попраить iptables-tailer.yaml:

```yaml
env:
  - name: "POD_IDENTIFIER"
    value: "name"
# - name: "POD_IDENTIFIER_LABEL"
#   value: "netperf-type"
```

Результат:

````
Events:
  Type     Reason      Age    From                                Message
  ----     ------      ----   ----                                -------
  Normal   Scheduled   3m22s  default-scheduler                   Successfully assigned default/netperf-server-1419bead3dad to gke-dev-dev-775f4ceb-4rsd
  Normal   Pulled      3m21s  kubelet, gke-dev-dev-775f4ceb-4rsd  Container image "tailoredcloud/netperf:v2.7" already present on machine
  Normal   Created     3m21s  kubelet, gke-dev-dev-775f4ceb-4rsd  Created container netperf-server-1419bead3dad
  Normal   Started     3m21s  kubelet, gke-dev-dev-775f4ceb-4rsd  Started container netperf-server-1419bead3dad
  Warning  PacketDrop  3m20s  kube-iptables-tailer                Packet dropped when receiving traffic from 10.0.4.16
  Warning  PacketDrop  64s    kube-iptables-tailer                Packet dropped when receiving traffic from netperf-client-1419bead3dad (10.0.4.16)
```
