from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from azure.identity import ClientSecretCredential
from azure.monitor.query import LogsQueryClient
from datetime import timedelta
from constants import tenant_id, client_id, client_secret
import ast


app = FastAPI()

# add CORS middleware
origins = [
    "http://localhost",
    "http://localhost:8080",
    "http://localhost:3000",
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# azure app registration details
workspace_id = "728517f8-64f8-498c-9aa1-a1ab80cda3d8"
kql_query = """
InsightsMetrics
| where Namespace == "Processor" and Name contains "UtilizationPercentage"
| make-series Cpu = round(avg(Val),2) on TimeGenerated from ago(1d) to now() step 1h  by Computer
"""

app = FastAPI()

# create a credential objects
credential = ClientSecretCredential(
    tenant_id=tenant_id, client_id=client_id, client_secret=client_secret
)

# create a log query client object and auth using credential
client = LogsQueryClient(credential)


@app.get("/api/cpu-metrics")
def query_log_analytics():
    return "Hello World"
    # response = client.query_workspace(
    #     workspace_id=workspace_id, # your log analytics workspace id
    #     query=kql_query,
    #     timespan=timedelta(days=1),
    # )

    # data = response.tables
    # results = {}
    # for row in data:
    #     for item in row.rows:
    #         key = item[0]
    #         metrics = ast.literal_eval(item[1])
    #         timestamps = ast.literal_eval(item[2])
    #         results[key] = {'metrics': metrics,
    #                         'timestamps': [t.split('.')[0] for t in timestamps]}
    # return results
