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
