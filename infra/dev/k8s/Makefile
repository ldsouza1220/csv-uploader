NAMESPACE := dev
HELM_DIR := ../../helm

.PHONY: all setup install upgrade uninstall clean port-forward tunnel hosts help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all          Start minikube and install everything"
	@echo "  setup        Start minikube and create namespace"
	@echo "  install      Install all Helm charts"
	@echo "  upgrade      Upgrade all Helm charts"
	@echo "  uninstall    Uninstall all Helm charts"
	@echo "  clean        Uninstall charts and delete namespace"
	@echo "  port-forward Open port-forward to all services"
	@echo "  tunnel       Start minikube tunnel for ingress"
	@echo "  hosts        Show /etc/hosts entries needed"
	@echo ""

all: setup install
	@echo ""
	@echo "Done! Next steps:"
	@echo "  1. Add hosts: make hosts"
	@echo "  2. Start tunnel: make tunnel"
	@echo ""

setup:
	@echo "Starting minikube..."
	minikube start
	minikube addons enable metrics-server
	minikube addons enable ingress
	@echo "Waiting for ingress controller..."
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=120s || true
	@echo "Creating namespace..."
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "Adding Helm repos..."
	helm repo add minio https://charts.min.io/ || true
	helm repo update

install: install-minio install-csv-uploader install-panda-secret
	@echo ""
	@echo "All apps installed!"
	@echo "Run 'make hosts' to see /etc/hosts entries"
	@echo "Run 'make tunnel' to start ingress"

install-minio:
	@echo "Installing MinIO..."
	helm install minio minio/minio -n $(NAMESPACE) -f values/minio.yaml --wait

install-csv-uploader:
	@echo "Installing csv-uploader..."
	helm install csv-uploader $(HELM_DIR)/csv-uploader -n $(NAMESPACE) -f values/csv-uploader.yaml

install-panda-secret:
	@echo "Installing panda-secret..."
	helm install panda-secret $(HELM_DIR)/panda-secret -n $(NAMESPACE) -f values/panda-secret.yaml

upgrade:
	helm upgrade minio minio/minio -n $(NAMESPACE) -f values/minio.yaml
	helm upgrade csv-uploader $(HELM_DIR)/csv-uploader -n $(NAMESPACE) -f values/csv-uploader.yaml
	helm upgrade panda-secret $(HELM_DIR)/panda-secret -n $(NAMESPACE) -f values/panda-secret.yaml

uninstall:
	helm uninstall csv-uploader -n $(NAMESPACE) || true
	helm uninstall panda-secret -n $(NAMESPACE) || true
	helm uninstall minio -n $(NAMESPACE) || true

clean: uninstall
	kubectl delete namespace $(NAMESPACE) || true

hosts:
	@echo ""
	@echo "Add to /etc/hosts:"
	@echo "127.0.0.1 csv.local pandas.local minio.local minio-api.local"
	@echo ""
	@echo "Run: echo '127.0.0.1 csv.local pandas.local minio.local minio-api.local' | sudo tee -a /etc/hosts"
	@echo ""

tunnel:
	@echo "Starting minikube tunnel (requires sudo)..."
	@echo ""
	@echo "URLs:"
	@echo "  http://csv.local        - CSV Uploader"
	@echo "  http://pandas.local     - Panda Secret"
	@echo "  http://minio.local      - MinIO Console"
	@echo "  http://minio-api.local  - MinIO S3 API"
	@echo ""
	minikube tunnel

port-forward:
	@echo "Starting port-forwards (Ctrl+C to stop)..."
	@echo "  csv-uploader: http://localhost:8000"
	@echo "  panda-secret: http://localhost:8080"
	@echo "  MinIO console: http://localhost:9001 (minioadmin/minioadmin123)"
	@kubectl port-forward -n $(NAMESPACE) svc/minio-console 9001:9001 &
	@kubectl port-forward -n $(NAMESPACE) svc/panda-secret 8080:8080 &
	@kubectl port-forward -n $(NAMESPACE) svc/csv-uploader 8000:8000
