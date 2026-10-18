============================= test session starts =============================
platform win32 -- Python 3.14.3, pytest-9.1.1, pluggy-1.6.0 -- C:\Users\Vimomo\Desktop\enrolment-app-open-ai\.venv\Scripts\python.exe
cachedir: .pytest_cache
rootdir: C:\Users\Vimomo\Desktop\enrolment-app-open-ai
configfile: pyproject.toml
plugins: anyio-4.14.2, platformdirs-4.13.0
collecting ... collected 7 items

tests/lab11/post_commit/test_api_students.py::test_service_health PASSED [ 14%]
tests/lab11/post_commit/test_api_students.py::test_students_exist PASSED [ 28%]
tests/lab11/post_commit/test_api_students.py::test_student_by_id PASSED  [ 42%]
tests/lab11/post_commit/test_api_students.py::test_students_by_subject PASSED [ 57%]
tests/lab11/post_commit/test_token_auth.py::test_valid_token_decodes PASSED [ 71%]
tests/lab11/post_commit/test_token_auth.py::test_expired_token_rejected PASSED [ 85%]
tests/lab11/post_commit/test_token_auth.py::test_invalid_signature_rejected PASSED [100%]

============================== warnings summary ===============================
tests/lab11/post_commit/test_token_auth.py::test_invalid_signature_rejected
  C:\Users\Vimomo\Desktop\enrolment-app-open-ai\.venv\Lib\site-packages\jwt\api_jwt.py:370: InsecureKeyLengthWarning: The HMAC key is 12 bytes long, which is below the minimum recommended length of 32 bytes for SHA256. See RFC 7518 Section 3.2.
    decoded = self.decode_complete(

-- Docs: https://docs.pytest.org/en/stable/how-to/capture-warnings.html
======================== 7 passed, 1 warning in 0.52s =========================
