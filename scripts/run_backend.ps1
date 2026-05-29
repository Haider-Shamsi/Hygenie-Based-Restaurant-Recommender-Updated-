# Run Django server using the project venv to avoid system Python mismatches.
$python = Join-Path $PSScriptRoot "..\.venv\Scripts\python.exe"
& $python ..\manage.py runserver 0.0.0.0:8000
