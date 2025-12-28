help:
	@echo "Usage make [target] "
	@echo
	@echo "[target]:"
	@egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'

clean: ## Clean application for fresh install (safe, project-scoped)
	# Stop Gradle daemons
	sh -c 'cd android; ./gradlew --stop || true'

	# --- iOS ---
	rm -rf ~/Library/Developer/Xcode/DerivedData/*
	sh -c 'cd ios; pod deintegrate || true'
	rm -rf ios/Pods ios/build ios/Podfile.lock

	# --- Android (project-scoped) ---
	# Remove module & project build outputs and local Gradle cache
	sh -c 'cd android; rm -rf app/build app/.cxx .cxx build .gradle'

	# --- JS workspace ---
	rm -rf node_modules
	rm -f yarn.lock  # let your package manager regenerate this
.PHONY: clean

## Optional helpers if you want to run them individually
clean-android:
	sh -c 'cd android; ./gradlew --stop || true'
	sh -c 'cd android; rm -rf app/build app/.cxx .cxx build .gradle'
.PHONY: clean-android

clean-ios:
	rm -rf ~/Library/Developer/Xcode/DerivedData/*
	sh -c 'cd ios; pod deintegrate || true'
	rm -rf ios/Pods ios/build ios/Podfile.lock
.PHONY: clean-ios

clean-js:
	rm -rf node_modules
	rm -f yarn.lock
.PHONY: clean-js

# Use this only when native headers/Prefab/transform paths get corrupted
# e.g. "Imported target ReactAndroid::jsi includes non-existent path ..."
deep-clean-android-cache: ## Heavy: wipes global Gradle caches
	# Stop all daemons first
	sh -c 'cd android; ./gradlew --stop || true'
	# Global Gradle caches (repopulates on next build)
	rm -rf ~/.gradle/caches ~/.gradle/daemon ~/.gradle/native ~/.gradle/kotlin
.PHONY: deep-clean-android-cache

bootstrap: ## Bootstrap application
	make clean
	make update-deps
.PHONY: bootstrap

update-deps: ## Update application dependencies.
	yarn install
	sh -c 'cd ios; RCT_NEW_ARCH_ENABLED=1 pod install'
	sh -c 'cd android; ./gradlew clean'
.PHONY: update-deps

watchman-restart: ## Restart watchman
	watchman watch-del .
	watchman watch-project .
.PHONY: watchman-restart

.DEFAULT_GOAL := help
