# Copied from gaia Makefile, may need periodic refreshes, has local modifications

node_modules:
	npm install && npm rebuild
	@echo "node_modules installed."
	touch -c $@

NPM_INSTALLED_PROGRAMS = node_modules/.bin/mozilla-download node_modules/.bin/jshint
$(NPM_INSTALLED_PROGRAMS): package.json node_modules

b2g: $(NPM_INSTALLED_PROGRAMS)
	DEBUG=* ./node_modules/.bin/mozilla-download \
  --verbose \
  --product b2g \
  --channel tinderbox \
  --branch mozilla-central $@

B2G_SDK_TMP := .b2g.tmp
.INTERMEDIATES: $(B2G_SDK_TMP)
.PHONY: b2g_sdk b2g
b2g_sdk: $(NPM_INSTALLED_PROGRAMS)
ifndef USE_LOCAL_XULRUNNER_SDK
ifneq ($(B2G_SDK_URL),$(shell test -d $(XULRUNNER_DIRECTORY) && cat $(B2G_SDK_URL_FILE) 2> /dev/null))
	rm -rf $(XULRUNNER_DIRECTORY)
	mkdir -p "$(XULRUNNER_DIRECTORY)"
	@echo "Downloading B2G SDK..."
	$(DOWNLOAD_CMD) "$(B2G_SDK_URL)"
ifeq ($(B2G_SDK_EXT),dmg)
# it's a nasty mac disk image
	@mkdir -p $(B2G_SDK_TMP)
	hdiutil attach $(B2G_SDK_FILE_NAME) -readonly -nobrowse -mount required -mountpoint $(B2G_SDK_TMP)
	cp -Rf $(B2G_SDK_TMP)/* "$(XULRUNNER_DIRECTORY)"
	ln -sf "$(XULRUNNER_DIRECTORY)/B2G.app/Contents/MacOS" "$(XULRUNNER_DIRECTORY)/b2g"
	umount $(B2G_SDK_TMP)
else ifeq ($(B2G_SDK_EXT),tar.bz2)
	tar xjf "$(B2G_SDK_FILE_NAME)" -C "$(XULRUNNER_DIRECTORY)"
else
	unzip -q "$(B2G_SDK_FILE_NAME)" -d "$(XULRUNNER_DIRECTORY)"
endif
	@rm -rf $(B2G_SDK_TMP) $(B2G_SDK_FILE_NAME)
	@echo $(B2G_SDK_URL) > $(B2G_SDK_URL_FILE)
endif # B2G SDK is up to date
endif # USE_LOCAL_XULRUNNER_SDK
	@test -f $(XPCSHELLSDK)
