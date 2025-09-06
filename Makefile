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
ANDROID_DEVICE?=

.PHONY: format lint test coverage coverage-html emulator-start emulator-stop android-run install-hooks hooks build

format:
	$(DART) format .

lint:
	$(FLUTTER) analyze

# Unit/widget tests
test:
	$(FLUTTER) test

# Code generation (drift, etc.)
build:
	$(DART) run build_runner build --delete-conflicting-outputs

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

# Run app on Android (emulator preferred; falls back to any connected device)
android-run:
	@set -e; \
	EMUS=`$(ADB) devices | awk 'NR>1 && $$2=="device" && $$1 ~ /^emulator-/ {print $$1}'`; \
	if [ -z "$$EMUS" ]; then \
		bash scripts/emulator_start.sh $(EMULATOR_AVD); \
	fi; \
	# If a specific ANDROID_DEVICE is provided, use it; otherwise pick the first connected
	if [ -n "$(ANDROID_DEVICE)" ]; then \
		DEV=$(ANDROID_DEVICE); \
	else \
		DEV=`$(ADB) devices | awk 'NR>1 && $$2=="device" {print $$1}' | head -n1`; \
	fi; \
	if [ -z "$$DEV" ]; then \
		echo "No Android device/emulator available" >&2; exit 1; \
	fi; \
	echo "Running on $$DEV"; \
	$(FLUTTER) run -d $$DEV
