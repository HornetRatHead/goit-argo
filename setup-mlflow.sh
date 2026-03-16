#!/bin/bash

echo "🚀 Починаємо підйом інфраструктури MLflow..."

# 1. Запуск Minikube з достатніми ресурсами
minikube start --memory 4096 --cpus 2

# 2. Очікування готовності нод
echo "⏳ Чекаємо, поки Kubernetes стане Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s

# 3. Завантаження образів у Minikube (щоб уникнути ImagePullBackOff)
echo "📦 Завантажуємо образи в кластер..."
# Ці образи мають бути у твоєму локальному Docker (ми їх pull-или раніше)
minikube image load ghcr.io/mlflow/mlflow:latest
minikube image load minio/minio:latest
minikube image load bitnami/postgresql:latest

# 4. Перевірка наявності прав (ClusterRoleBinding)
# Ми робимо це silent, щоб не було помилок, якщо вони вже існують
kubectl create clusterrolebinding argocd-application-controller-admin \
    --clusterrole=cluster-admin \
    --serviceaccount=infra-tools:argocd-application-controller 2>/dev/null || echo "✅ RBAC вже налаштовано"

# 5. Примусовий рестарт ArgoCD контролера (StatefulSet), щоб він підхопив права
echo "🔄 Рестартуємо ArgoCD контролер..."
kubectl rollout restart statefulset argocd-application-controller -n infra-tools

# 6. Примусова синхронізація аплікації
echo "🔄 Синхронізуємо MLflow через ArgoCD..."
kubectl patch application mlflow -n infra-tools --type merge -p '{"metadata": {"annotations": {"argocd.argoproj.io/refresh": "hard"}}}'

# 7. Видалення старих подів (щоб вони перестворилися з локальними образами)
echo "🧹 Очищуємо старі поди в mlflow-app..."
kubectl delete pods -n mlflow-app --all 2>/dev/null || echo "Namespace mlflow-app ще порожній"

echo "🎯 Готово! Перевіряємо статус подів через 10 секунд..."
sleep 10
kubectl get pods -n mlflow-app
