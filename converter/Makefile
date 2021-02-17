PIPENV_PARAMS := PIPENV_VENV_IN_PROJECT=true PIPENV_DONT_LOAD_ENV=1 PIPENV_IGNORE_VIRTUALENVS=1

default:
	@ install-deps

.PHONY: install-deps
install-deps:
	$(PIPENV_PARAMS) pipenv sync --dev

.PHONY: pipenv-lock
pipenv-lock:
	$(PIPENV_PARAMS) \
		PIPENV_TIMEOUT=3600 \
		PIPENV_INSTALL_TIMEOUT=3600 \
		PIP_NO_CACHE_DIR=1 \
		pipenv lock --clear --verbose

INPUT_FILENAME := ""

.PHONY: run
run:
	$(PIPENV_PARAMS) pipenv run python converter.py "$(INPUT_FILENAME)"