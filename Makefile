
-include local.mk
-include xul.mk
-include b2g.mk

GAIA_SRC_DIR?=../gaia
DIST_NAME?=gaia-email

GAIA_DIR?=`pwd`
STAGE_DIR?=$(GAIA_DIR)$(SEP)build_stage
export STAGE_DIR

APP_DIR?=$(GAIA_DIR)/gaia-email
export APP_DIR

LATEST_COMMIT=$(shell git -C $(GAIA_SRC_DIR) rev-parse --verify HEAD)
LATEST_BRANCH=$(shell git -C $(GAIA_SRC_DIR) rev-parse --abbrev-ref HEAD)

# Depends on stuff in xul.mk
define run-js-command
  $(2) $(XULRUNNERSDK) $(XPCSHELLSDK) \
    -f "build/xpcshell-commonjs.js" \
    -e "run('$(strip $1)');"
endef


define BUILD_CONFIG
{ \
  "GAIA_DIR" : "$(GAIA_DIR)", \
  "APP_DIR" : "$(APP_DIR)"
}
endef

export BUILD_CONFIG





.PHONY: help sync-shared sync-locales sync-email dist clean
.DEFAULT_GOAL=help

help:
	@echo Read the Makefile for now

sync-shared:
	@cp $(GAIA_SRC_DIR)/.jshintrc ./.jshintrc

	@cp -r $(GAIA_SRC_DIR)/shared/locales/date ./gaia-email/shared/locales

	@cp -r $(GAIA_SRC_DIR)/shared/style/action_menu* ./gaia-email/shared/style
	@cp -r $(GAIA_SRC_DIR)/shared/style/buttons* ./gaia-email/shared/style
	@cp -r $(GAIA_SRC_DIR)/shared/style/confirm* ./gaia-email/shared/style
	@cp -r $(GAIA_SRC_DIR)/shared/style/input_areas* ./gaia-email/shared/style
	@cp -r $(GAIA_SRC_DIR)/shared/style/headers* ./gaia-email/shared/style
	@cp -r $(GAIA_SRC_DIR)/shared/style/progress_activity* ./gaia-email/shared/style
	@cp -r $(GAIA_SRC_DIR)/shared/style/switches* ./gaia-email/shared/style
	@cp -r $(GAIA_SRC_DIR)/shared/style/status* ./gaia-email/shared/style
	@cp -r $(GAIA_SRC_DIR)/shared/style/tabs* ./gaia-email/shared/style
	@cp -r $(GAIA_SRC_DIR)/shared/style/value_selector* ./gaia-email/shared/style

	@cp -r $(GAIA_SRC_DIR)/shared/js/l10n.js ./gaia-email/shared/js/l10n.js
	@cp -r $(GAIA_SRC_DIR)/shared/js/l10n_date.js ./gaia-email/shared/js/l10n_date.js
	@cp -r $(GAIA_SRC_DIR)/shared/js/mime_mapper.js ./gaia-email/shared/js/mime_mapper.js
	@cp -r $(GAIA_SRC_DIR)/shared/js/gesture_detector.js ./gaia-email/shared/js/gesture_detector.js
	@cp -r $(GAIA_SRC_DIR)/shared/js/notification_helper.js ./gaia-email/shared/js/notification_helper.js
	@cp -r $(GAIA_SRC_DIR)/shared/js/accessibility_helper.js ./gaia-email/shared/js/accessibility_helper.js
	@cp -r $(GAIA_SRC_DIR)/shared/js/font_size_utils.js ./gaia-email/shared/js/font_size_utils.js

	@echo Synced shared resources from $(GAIA_SRC_DIR): $(LATEST_COMMIT)
	@echo UPDATE THE REPO WITH: git commit -am \"Autosync shared from mozilla-b2g/gaia, branch $(LATEST_BRANCH): $(LATEST_COMMIT)\"

sync-locales:
	@cp -r $(GAIA_SRC_DIR)/apps/email/locales ./gaia-email
	@echo Synced locales from $(GAIA_SRC_DIR)/apps/email: $(LATEST_COMMIT)
	@echo UPDATE THE REPO WITH: git commit -am \"Autosync locales from mozilla-b2g/gaia, branch $(LATEST_BRANCH): $(LATEST_COMMIT)\"

sync-email:
	@cp -r $(GAIA_SRC_DIR)/apps/email/autoconfig ./gaia-email
	@cp -r $(GAIA_SRC_DIR)/apps/email/js ./gaia-email
	@cp -r $(GAIA_SRC_DIR)/apps/email/locales ./gaia-email
	@cp -r $(GAIA_SRC_DIR)/apps/email/sounds ./gaia-email
	@cp -r $(GAIA_SRC_DIR)/apps/email/style ./gaia-email
	@cp -r $(GAIA_SRC_DIR)/apps/email/index.html ./gaia-email/index.html
	@cp -r $(GAIA_SRC_DIR)/apps/email/manifest.webapp ./gaia-email/manifest.webapp
	@cp -r $(GAIA_SRC_DIR)/apps/email/build ./

	@echo Synced email files resources from $(GAIA_SRC_DIR)/apps/email: $(LATEST_COMMIT)
	@echo UPDATE THE REPO WITH: git commit -am \"Autosync email from mozilla-b2g/gaia, branch $(LATEST_BRANCH): $(LATEST_COMMIT)\"

dist: b2g_sdk
	# @mkdir -p dist
	@$(call run-js-command,build)
	# @rm -rf dist/$(DIST_NAME)
	# @cp -r ./gaia-email dist/$(DIST_NAME)
	# @cd dist
	# @zip -r $(DIST_NAME).zip $(DIST_NAME)/*
	# @cd ..

clean:
	rm -rf dist

# clean out build products and tools
really-clean: clean
	rm -rf b2g-* .b2g-* b2g_sdk node_modules b2g

