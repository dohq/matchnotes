# Variables
FLUTTER?=flutter
DART?=dart
LCOV?=lcov
GENHTML?=genhtml
COVERAGE_DIR=coverage
COVERAGE_LCOV=$(COVERAGE_DIR)/lcov.info
COVERAGE_HTML_DIR=$(COVERAGE_DIR)/html
EMULATOR_AVD?=Pixel_8a_API_34
ADB?=adb

.PHONY: format lint test coverage coverage-html emulator-start emulator-stop install-hooks hooks

format:
	$(DART) format .

lint:
	$(FLUTTER) analyze

# Unit/widget tests
test:
	$(FLUTTER) test

# Generate lcov.info under coverage/
coverage:
	$(FLUTTER) test --coverage
	@echo "Coverage written to $(COVERAGE_LCOV)"

# Generate HTML report at coverage/html/
coverage-html: coverage
	$(LCOV) --list $(COVERAGE_LCOV) >/dev/null || (echo "lcov not found or invalid lcov.info" && exit 1)
	mkdir -p $(COVERAGE_HTML_DIR)
	$(GENHTML) $(COVERAGE_LCOV) --output-directory $(COVERAGE_HTML_DIR)
	@echo "Open $(COVERAGE_HTML_DIR)/index.html"

# Android Emulator controls (Linux)
emulator-start:
	bash scripts/emulator_start.sh $(EMULATOR_AVD)

emulator-stop:
	bash scripts/emulator_stop.sh

# Git hooks setup
hooks/.stamp:
	mkdir -p hooks
	mkdir -p .githooks
	cp scripts/pre-commit .githooks/pre-commit
	chmod +x .githooks/pre-commit
	git config core.hooksPath .githooks
	touch hooks/.stamp

install-hooks: hooks/.stamp
	@echo "Git hooks installed (pre-commit)" 
