set -e

gcloud auth configure-docker
docker build -t gcr.io/$1/demoapp:0.0.5 demo_app
docker push gcr.io/$1/demoapp:0.0.5