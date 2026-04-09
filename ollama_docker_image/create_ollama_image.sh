gcloud builds submit ollama_docker_image \
   --tag $REGION-docker.pkg.dev/$PROJECT_ID/$OLLAMA_REPO_NAME/ollama \
   --machine-type e2-highcpu-32