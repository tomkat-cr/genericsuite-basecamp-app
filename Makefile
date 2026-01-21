.DEFAULT_GOAL := local
.PHONY: help install update update_documentation qa build build_local run clean
SHELL := /bin/bash

## General Commands

help:
	cat Makefile

## Install dependecies

install:
	flutter pub get

update:
	flutter pub upgrade

## Cleaning

clean: clean_rm clean_temp_dir clean_logs unbuild 

clean_rm:
	rm -rf build/* build/.*

clean_temp_dir:
	rm -rf .dart_tool

clean_logs:
	rm -rf logs/

clean_build: unbuild
	

fresh: clean install

## CLI Utilities

install_tools:
	xcode-select --install
	brew install --cask android-sdk
	cd /tmp && curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.38.6-stable.zip
	mkdir -p "${HOME}/flutter"
	unzip flutter_macos_arm64_3.38.6-stable.zip -d "${HOME}/flutter"
	export PATH=$PATH:"${HOME}/flutter/bin"
	flutter pub global activate

update_documentation:
	sh scripts/run_docs_converter.sh

## Automated Testing

test:
	# TODO: implement flutter test	

## Development Commands

qa: test

build:
	flutter build apk --release

build_local:
	flutter build apk --debug

build_bundle:
	rm -rf build/app/outputs/bundle/release/app-release.aab && \
	flutter build appbundle --release && \
	cd build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/ && \
	zip -r ../../../../../../../outputs/bundle/release/native-debug-symbols.zip . && \
	cd - && \
	ls -lh build/app/outputs/bundle/release/app-release.aab && \
	ls -lh build/app/outputs/bundle/release/native-debug-symbols.zip

generate_keystore:	
	keytool -genkey -v -keystore ${HOME}/.ssh/upload-keystore.jks \
        -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
        -alias upload

unbuild:
	flutter clean && cd android && ./gradlew clean && cd -

## Deployment

deploy_local: build_local

deploy_prod: build

deploy: deploy_prod

## Application Specific Commands

run: clean_logs
	flutter run
