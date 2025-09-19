

from fastapi import FastAPI, HTTPException
from sqlmodel import Field, Session, SQLModel, create_engine, select
from typing import Optional, List
from fastapi_mcp import FastApiMCP

# --- Models ---
class ToDo(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    completed: bool = False

# --- DB Setup ---
sqlite_file_name = "todo.db"
engine = create_engine(f"sqlite:///{sqlite_file_name}", echo=False)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

# --- FastAPI App (register endpoints on base_app) ---
base_app = FastAPI()

@base_app.on_event("startup")
def on_startup():
    create_db_and_tables()

@base_app.post("/todos/", response_model=ToDo)
def create_todo(todo: ToDo):
    with Session(engine) as session:
        session.add(todo)
        session.commit()
        session.refresh(todo)
        return todo

@base_app.get("/todos/", response_model=List[ToDo])
def read_todos():
    with Session(engine) as session:
        return session.exec(select(ToDo)).all()

@base_app.get("/todos/{todo_id}", response_model=ToDo)
def read_todo(todo_id: int):
    with Session(engine) as session:
        todo = session.get(ToDo, todo_id)
        if not todo:
            raise HTTPException(status_code=404, detail="ToDo not found")
        return todo

@base_app.put("/todos/{todo_id}", response_model=ToDo)
def update_todo(todo_id: int, updated: ToDo):
    with Session(engine) as session:
        todo = session.get(ToDo, todo_id)
        if not todo:
            raise HTTPException(status_code=404, detail="ToDo not found")
        todo.title = updated.title
        todo.completed = updated.completed
        session.add(todo)
        session.commit()
        session.refresh(todo)
        return todo

@base_app.delete("/todos/{todo_id}")
def delete_todo(todo_id: int):
    with Session(engine) as session:
        todo = session.get(ToDo, todo_id)
        if not todo:
            raise HTTPException(status_code=404, detail="ToDo not found")
        session.delete(todo)
        session.commit()
        return {"ok": True}


# --- Remove manual MCP endpoints: fastapi-mcp will expose all endpoints as MCP tools automatically ---


# --- MCP Integration using fastapi-mcp ---
app = base_app
mcp_app = FastApiMCP(app)
mcp_app.mount_http(app, mount_path="/llm/mcp")

# --- Test endpoint for MCP and API integration ---
@app.get("/health")
def health():
    return {"status": "ok"}

# --- Run with: uvicorn main:app --reload --port 9000 ---