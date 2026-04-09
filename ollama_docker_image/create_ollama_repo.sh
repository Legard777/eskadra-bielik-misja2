gcloud artifacts repositories create $OLLAMA_REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --description="$OLLAMA_REPO_DESCRIPTION" \
    --project=$PROJECT_ID