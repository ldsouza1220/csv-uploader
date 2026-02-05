# Dev Environment (Minikube + Helm)

Local Kubernetes environment for development and testing.

## Quick Start

```bash
make all
```

Then set up ingress access:

```bash
# Add hosts entries
echo '127.0.0.1 csv.local pandas.local minio.local minio-api.local' | sudo tee -a /etc/hosts

# Start tunnel (keep running)
make tunnel
```

Apps available at:
- http://csv.local - CSV Uploader
- http://pandas.local - Panda Secret
- http://minio.local - MinIO Console (minioadmin/minioadmin123)

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make all` | Start minikube + install everything |
| `make install` | Install all Helm charts |
| `make upgrade` | Upgrade all Helm charts |
| `make uninstall` | Uninstall all Helm charts |
| `make clean` | Uninstall + delete namespace |
| `make tunnel` | Start minikube tunnel for ingress |
| `make hosts` | Show /etc/hosts entries needed |
| `make port-forward` | Alternative: use port-forwarding |

## Alternative: Port Forwarding

If you prefer not to use ingress:

```bash
make port-forward
```

- http://localhost:8000 - CSV Uploader
- http://localhost:8080 - Panda Secret
- http://localhost:9001 - MinIO Console

## Structure

```
values/
├── minio.yaml         # Object storage (S3-compatible)
├── csv-uploader.yaml  # CSV upload application
└── panda-secret.yaml  # Demo application
```

## Cleanup

```bash
make clean
minikube stop
```
