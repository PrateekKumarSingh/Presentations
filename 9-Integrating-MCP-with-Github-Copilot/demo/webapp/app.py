from flask import Flask, render_template, request, redirect, url_for
import requests

app = Flask(__name__)
FASTAPI_URL = "http://127.0.0.1:9000/todos/"

@app.route('/')
def index():
    resp = requests.get(FASTAPI_URL)
    todos = resp.json()
    return render_template('index.html', todos=todos)

@app.route('/add', methods=['POST'])
def add_todo():
    title = request.form.get('title')
    if title:
        requests.post(FASTAPI_URL, json={"title": title, "completed": False})
    return redirect(url_for('index'))

@app.route('/complete/<int:todo_id>', methods=['POST'])
def complete_todo(todo_id):
    # Get the todo to update
    todo = requests.get(f"{FASTAPI_URL}{todo_id}").json()
    todo['completed'] = True
    requests.put(f"{FASTAPI_URL}{todo_id}", json=todo)
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True, port=5000)
