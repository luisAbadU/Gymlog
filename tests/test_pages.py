from fastapi.testclient import TestClient


def test_index_renders_spanish_page(client: TestClient) -> None:
    response = client.get("/")

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/html")
    assert '<html lang="es">' in response.text
    assert "Hola GymLog" in response.text
