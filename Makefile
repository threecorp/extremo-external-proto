.DEFAULT_GOAL := help

SHELL := /bin/bash

format-shown:  ## Preview next formatting code
	@buf format -d


format:  ## Format proto files to properly
	@buf format -w


lint:  ## Lint proto files and validate build
	@buf lint
	@buf build


protocol:  ## Generate code (go, ts, dart) from .proto schema
	@make clean
	@buf build --path extremo
	# NOTE: unlike the internal extremo-proto monorepo, this is a STANDALONE Go
	# module that external consumers `go get`. We do NOT `--include-imports
	# --include-wkt`: generated code references upstream Go packages for
	# google.* / buf.validate.* (see go.mod), so `externalgo/` contains only our
	# `extremo/*` packages and `go build ./...` stays clean.
	@buf generate --path extremo
	@-go tool fix -force context externalgo
	@-make gomodule
	@-tree externalgo


generate: protocol  ## Alias: protocol task


gomodule:  ## Tidy up Golang dependencies
	@go mod tidy


clean-go:  ## Clean generated go code
	rm -rf externalgo/*


clean-dart:  ## Clean generated dart code
	rm -rf lib/*


clean-ts:  ## Clean generated ts code
	rm -rf externaltsnode/*


clean-docs:  ## Clean generated API reference docs
	rm -rf docs/*


clean: | clean-go clean-dart clean-ts clean-docs  ## Clean generated code


help:  ## Show all of tasks
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'
