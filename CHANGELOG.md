# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
- Chore: iOS | Update `ZXingObjC` pod to use the latest version.

## [1.0.10]
- Chore: iOS | Use `podspec` element instead of it being a `framework` attribute.

## [1.0.9]

# 16-12-2022
- Fix: Android | Remove dependency to jcenter from Gradle (https://outsystemsrd.atlassian.net/browse/RMET-2036).

## [1.0.8]
- Fix: iOS | Reading PDF417 code types causes a crash (https://outsystemsrd.atlassian.net/browse/RMET-746).

## [1.0.7]

- Feat: review of error codes and messages. (https://outsystemsrd.atlassian.net/browse/RMET-1726)

## [1.0.6]

- Fix: In Android added null check to avoid crash when the callbackContext is null (https://outsystemsrd.atlassian.net/browse/RMET-1675)
## [1.0.5]

- Fix: In iOS when cancelling the barcode scanner view, send an ERROR instead of a NO_RESULT (https://outsystemsrd.atlassian.net/browse/RMET-1261)

## [1.0.4]
- Chore: New plugin release to include metadata tag for MABS 7.2.0 compatibility

## [1.0.3]
- Chore: New plugin release to include metadata tag in Extensability Configurations in the OS wrapper

## [1.0.2]
- Added android:exported tag for Android 12 property and MABS8

## [1.0.1]
## 2021-07-13
- Migrating package upload to newer Saucelabs API [RMET-761](https://outsystemsrd.atlassian.net/browse/RMET-761)


## [1.0.0]
## 2021-05-14
- Implementation of parameters [RMET-722](https://outsystemsrd.atlassian.net/browse/RMET-722)
## 2021-05-07
- Implementation of the Barcode Plugin for Android [RMET-594](https://outsystemsrd.atlassian.net/browse/RMET-594)
## 2021-05-05
- Added pipeline configurations to repo (CI folder) [RMET-597](https://outsystemsrd.atlassian.net/browse/RMET-597)
## 2021-04-26
- Created ios implementation for plugin [RMET-593](https://outsystemsrd.atlassian.net/browse/RMET-593)
- Created js layer for plugin [RMET-595](https://outsystemsrd.atlassian.net/browse/RMET-595)
- Created repository for plugin [RMET-592](https://outsystemsrd.atlassian.net/browse/RMET-592)

