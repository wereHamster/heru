
TESTS=$(shell find test/unit/ -type f -name '*.coffee')

.PHONY: test
test: $(TESTS)
	@./node_modules/.bin/mocha --no-colors --compilers coffee:coffee-script \
		-u exports -R dot $(TESTS)
