# create virtual environment
init:
	@python3 -m venv venv/
	@./venv/bin/pip install -U pip
	@./venv/bin/pip install -r requirements.txt

# TLDR: no per-PID .coverage files linger afterwards
test-coverage-unittest:
	@rm -f .coverage*
	@./venv/bin/coverage run --source mycode -m unittest discover
	@ls -la .coverage*

# TLDR: no per-PID .coverage files linger afterwards
test-coverage-pytest:
	@rm -f .coverage*
	@./venv/bin/coverage run --source mycode -m pytest test.py
	@ls -la .coverage*

# TLDR: some per-PID .coverage files linger afterwards
test-pytest-cov:
	@rm -f .coverage*
	@./venv/bin/pytest --cov=mycode test.py
	@ls -la .coverage*

# TLDR: no per-PID .coverage files linger afterwards
test-pytest-cov-no-multiprocessing:
	@rm -f .coverage*
	@JOBLIB_MULTIPROCESSING=0 ./venv/bin/pytest --cov=mycode test.py
	@ls -la .coverage*

# TLDR: the 1st pytest command results in lingering per-PID .coverage files,
#       and causes the 2nd pytest command to consider lines from those files
#       in reports and checks (e.g. min coverage %)
the-issue:
	@rm -f .coverage*
	@./venv/bin/pytest --cov=mycode test.py
	@ls -la .coverage*
	@./venv/bin/pytest --cov=othercode othertest.py
	@ls -la .coverage*

# TLDR: running coverage without pytest-cov shows the issue doesn't occur
the-issue-no-pytest-cov:
	@rm -f .coverage*
	@./venv/bin/coverage run --source mycode -m pytest test.py && ./venv/bin/coverage report
	@ls -la .coverage*
	@./venv/bin/coverage run --source othercode -m pytest othertest.py && ./venv/bin/coverage report
	@ls -la .coverage*
