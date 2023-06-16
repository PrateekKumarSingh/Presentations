#Note: The openai-python library support for Azure OpenAI is in preview.
import os
import openai
openai.api_type = "azure"
openai.api_base = os.getenv("OPENAI_ENDPOINT")
openai.api_key = os.getenv("OPENAI_API_KEY")
openai.api_version = "2022-12-01"

response = openai.Embedding.create(
    input="Hello Prateek, how are you?",
    engine="embedding",
)

embeddings = response

print(embeddings)