.DEFAULT_GOAL := local
.PHONY: help install update update_documentation qa build build_local run clean clean_rm clean_temp_dir clean_logs clean_build
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

clean: clean_rm clean_temp_dir clean_logs clean_build 

clean_rm:
	rm -rf build
	mkdir build

clean_temp_dir:
	rm -rf .dart_tool

clean_logs:
	rm -rf logs/

clean_build:
	flutter clean && cd android && ./gradlew clean && cd -

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

## Build

qa: test

build:
	flutter build apk --release

build_local:
	flutter build apk --debug

build_bundle_rm_init:
	@echo ""
	@echo "Starting bundle creation process... removing previous build"
	@echo ""
	rm -rf build
	mkdir build

build_bundle_flutter_build:
	@echo ""
	@echo "Building bundle to upload to Play Store..."
	@echo ""
	flutter build appbundle --release

build_bundle_zip:
	@echo ""
	@echo "Zipping native libs to upload as debug symbols to Play Store..."
	@echo ""
	zip -r build/app/outputs/bundle/release/native-debug-symbols.zip build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/

build_bundle_ls:
	@echo ""
	@echo "Bundle size:"
	@echo ""
	ls -lh build/app/outputs/bundle/release/app-release.aab
	ls -lh build/app/outputs/bundle/release/native-debug-symbols.zip

build_bundle_finished:
	@echo ""
	@echo "Bundle creation finished."
	@echo ""

build_bundle: build_bundle_rm_init build_bundle_flutter_build build_bundle_zip build_bundle_ls build_bundle_finished

publish: build_bundle

generate_keystore:
	keytool -genkey -v -keystore ${HOME}/.ssh/upload-keystore.jks \
        -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
        -alias upload

sign_apk:
	flutter build apk --release --keystore=${HOME}/.ssh/upload-keystore.jks --keystore-password=${PASSWORD} --key-alias=upload --key-password=${PASSWORD}

sign_bundle:
	flutter build appbundle --release --keystore=${HOME}/.ssh/upload-keystore.jks --keystore-password=${PASSWORD} --key-alias=upload --key-password=${PASSWORD}

generate_icons:
	flutter pub get && flutter pub run flutter_launcher_icons:main

create_android_avd:
	 # ${HOME}/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager "system-images;android-27;google_apis_playstore;x86"
	 ${HOME}/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager "system-images;android-34;google_apis_playstore;arm64-v8a"

## Deployment

deploy_local: build_local

deploy_prod: build_bundle

deploy: deploy_prod

## Application Specific Commands

run: clean_logs
	flutter run
