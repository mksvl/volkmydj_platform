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
