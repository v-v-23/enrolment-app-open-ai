import os

import requests


DATABASE_SERVICE_URL = os.getenv("DATABASE_SERVICE_URL", "http://localhost:5002")


def test_service_health():
    response = requests.get(f"{DATABASE_SERVICE_URL}/", timeout=5)
    assert response.status_code == 200


def test_students_exist():
    response = requests.get(f"{DATABASE_SERVICE_URL}/students", timeout=5)
    assert response.status_code == 200
    students = response.json()
    assert len(students) > 0


def test_student_by_id():
    response = requests.get(f"{DATABASE_SERVICE_URL}/students/1", timeout=5)
    assert response.status_code == 200


def test_students_by_subject():
    response = requests.get(
        f"{DATABASE_SERVICE_URL}/students/by-subject",
        params={"subject_code": "ASD101"},
        timeout=5,
    )
    assert response.status_code == 200