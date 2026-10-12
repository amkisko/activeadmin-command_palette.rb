.PHONY: release lint lint-biome lint-ruby audit test test-javascript clean

release:
	ruby usr/bin/release.rb

lint-biome:
	npx --yes @biomejs/biome@2.3.8 ci .

lint-ruby:
	bundle exec rubocop
	bundle exec rbs validate

lint: lint-biome lint-ruby

test-javascript:
	node --test --experimental-loader=./spec/javascript/support/stimulus_loader.mjs spec/javascript/command_palette_controller.test.mjs

audit:
	bundle exec bundler-audit check

test: lint test-javascript
	POLYRUN_MERGE_FORMATS=json,lcov,cobertura,console bundle exec polyrun parallel-rspec --workers 5 --merge-failures

clean:
	rm -rf coverage .pray/cache tmp
	rm -f spec/examples.txt *.gem
