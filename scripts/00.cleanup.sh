#!/bin/bash

echo "*** Cleanup script ***"

echo "Uninstalling Provider..."
helm uninstall provider-dsc -n provider 2>/dev/null
kubectl delete namespace provider

echo "Uninstalling Consumer..."
helm uninstall consumer-dsc -n consumer 2>/dev/null
kubectl delete namespace consumer

echo "uninstalling Trust Anchor..."
helm uninstall trust-anchor-dsc -n trust-anchor 2>/dev/null
kubectl delete namespace trust-anchor

echo "Removing persistent volumes..."
kubectl delete pvc data-data-service-postgis-0 -n provider 2>/dev/null
kubectl delete pvc data-postgresql-0 -n consumer 2>/dev/null
kubectl delete pvc data-trust-anchor-mysql-0 -n trust-anchor 2>/dev/null


while getopts ':f' opt; do
    case $opt in
        f)
            volumes=$(docker ps -a --format '{{ .ID }}' | xargs -I {} docker inspect -f '{{ .Name }}{{ range .Mounts }}{{ printf "\n " }}{{ .Type }} {{ if eq .Type "bind" }}{{ .Source }}{{ end }}{{ .Name }} => {{ .Destination }}{{ end }}' {} | sed 's/ => \/.*//g' | tr -d '\n' | sed -E 's/\/k3s-maven-plugin(.*)(\/.+ ).*/\1/gm' | sed -E 's/( volume )/\n/g' | tail -n +2)
            
            echo "Terminating k3s-maven-plugin container..."
            docker stop k3s-maven-plugin 2>/dev/null
            echo "k3s-maven-plugin container terminated."
            
            echo "Removing k3s-maven-plugin container..."
            docker rm k3s-maven-plugin 2>/dev/null
            echo "k3s-maven-plugin container removed."
            
            echo "Removing k3s-maven-plugin volumes..."
            echo $volumes | xargs -n 1 docker volume rm 2>/dev/null
            echo "k3s-maven-plugin volumes removed."
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done
echo -e "\n*** Cleanup completed! ***"

# if a default KUBECONFIG exists, check if the script is sourced and export default KUBECONFIG in case
if [ -f $HOME/.kube/config ]; then
    if $(return 0 2>/dev/null); then
            echo "Restoring default KUBECONFIG..."
            export KUBECONFIG=$HOME/.kube/config
            echo "KUBECONFIG exported -> $KUBECONFIG"
    else
        echo -e "Please run\n\nexport KUBECONFIG=$HOME/.kube/config\n\nto make kubectl environment available."
    fi
fi