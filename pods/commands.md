- kubectl apply -f pod.yaml
- kubectl get pods
- kubectl get pods -o wide
- kubectl describe pods  web
- kubectl delete -f pod.yaml
- kubectl logs web #pod name
- kubectl exec -it (pod-name) -c (container-name)
- 
# to apply the change to a pods you should delete the old version and apply again.