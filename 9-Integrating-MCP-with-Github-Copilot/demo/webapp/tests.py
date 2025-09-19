import pytest
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError

BASE_URL = "http://127.0.0.1:5000"

@pytest.fixture(scope="session")
def browser():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        yield browser
        browser.close()

@pytest.fixture
def page(browser):
    context = browser.new_context()
    page = context.new_page()
    try:
        page.goto(BASE_URL, timeout=5000)
    except PlaywrightTimeoutError:
        pytest.fail(f"Could not load {BASE_URL}. Is the server running?")
    yield page
    context.close()

def get_todo_items(page):
    return page.query_selector_all("li")

def test_empty_state(page):
    assert page.is_visible("text=No todos found") or len(get_todo_items(page)) == 0

def test_add_todo(page):
    page.fill("input[name='title']", "Test Todo 1")
    page.click("button[type='submit']")
    page.wait_for_selector("li:has-text('Test Todo 1')")
    assert any("Test Todo 1" in item.inner_text() for item in get_todo_items(page)), "New todo not found in list"

def test_add_duplicate_todo(page):
    page.fill("input[name='title']", "Test Todo 1")
    page.click("button[type='submit']")
    assert page.is_visible("text=already exists") or len([item for item in get_todo_items(page) if "Test Todo 1" in item.inner_text()]) == 1

def test_add_empty_todo(page):
    page.fill("input[name='title']", "")
    page.click("button[type='submit']")
    assert page.is_visible("text=Title required") or page.is_visible("text=Please enter a todo")

def test_complete_todo(page):
    todo = page.query_selector("li:has-text('Test Todo 1')")
    assert todo, "Todo to complete not found"
    complete_btn = todo.query_selector("input[type='checkbox'], button.complete")
    assert complete_btn, "No complete button/checkbox found"
    complete_btn.click()
    assert "completed" in todo.get_attribute("class") or todo.is_visible("text=Completed")

def test_delete_todo(page):
    todo = page.query_selector("li:has-text('Test Todo 1')")
    assert todo, "Todo to delete not found"
    delete_btn = todo.query_selector("button.delete")
    assert delete_btn, "No delete button found"
    delete_btn.click()
    page.wait_for_timeout(500)
    assert not page.is_visible("li:has-text('Test Todo 1')"), "Todo was not deleted"

def test_cleanup(page):
    for todo in get_todo_items(page):
        delete_btn = todo.query_selector("button.delete")
        if delete_btn:
            delete_btn.click()
    page.wait_for_timeout(500)
    assert len(get_todo_items(page)) == 0 or page.is_visible("text=No todos found")