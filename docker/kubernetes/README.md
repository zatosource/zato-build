# Run Zato in a local Kubernetes

## Start a local Kubernetes

- Start a local Kubernetes using minikube
```
$ minikube start
```

## Deploy Zato to Kubernetes

- Switch to Minikube context
```
kubectl config use-context minikube
```
- Install [Dockerize](https://github.com/powerman/dockerize#installation). It will be used to create the zato-k8.yaml.
- Edit the file **environment**.
- Generate the zato-k8.yaml with your values from **environment**.
```
dockerize -env environment -template zato-k8.yaml.template:zato-k8.yaml
```
- Deploy Zato in to Kubernetes
```
$ kubectl apply -f zato-k8.yaml
```
- Check if the deploy was make
```
$ kubectl get pods --namespace=zato
NAME                         READY   STATUS              RESTARTS   AGE
bootstrap-6fb6c85c4c-4nx6l   0/1     ContainerCreating   0          22s
postgres-57cf76f654-qcb2g    0/1     ContainerCreating   0          22s
redis-5c46c79bd7-tt6cs       0/1     ContainerCreating   0          22s
scheduler-9db4bb4d6-zgcmm    0/1     ContainerCreating   0          22s
server-85bcf4ccbd-2lw45      0/1     ContainerCreating   0          22s
server-85bcf4ccbd-gqbs2      0/1     ContainerCreating   0          22s
webadmin-54688f5445-n4xkz    0/1     ContainerCreating   0          22s
```

## Next steps

- Switch to Minikube context
```
kubectl config use-context minikube
```
- Check log of Zato server 1 (the Zato Server container name will be different)
```
$ kubectl logs --namespace=zato server-85bcf4ccbd-2lw45
```
- Check access to Zato servers
```
$ curl http://$(docker-machine ip default):17010/zato/ping
{"zato_env": {"details": "", "result": "ZATO_OK", "cid": "93bf40452dc0cc2a9d548614"}, "zato_ping_response": {"pong": "zato"}}
```
- Get Zato's Web Admin interface URL
```
$ minikube service --namespace zato webadmin --url
```
