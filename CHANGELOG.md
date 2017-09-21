# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Unreleased as of Sprint 69 ending 2017-09-18

### Fixed
- Fixed bug with initialize-httpd-auth script. [(#22)](https://github.com/ManageIQ/container-httpd/pull/22)
- Fixed httpd startup issue [(#17)](https://github.com/ManageIQ/container-httpd/pull/17)
- Fixed issue where SSSD wasn't started after an auth configmap update. [(#16)](https://github.com/ManageIQ/container-httpd/pull/16)

## Unreleased as of Sprint 68 ending 2017-09-04

### Added
- Authentication
  - Allow oci-systemd hooks to properly engage [(#14)](https://github.com/ManageIQ/container-httpd/pull/14)
- Platform
  - Added support for an httpd authentication configuration map [(#12)](https://github.com/ManageIQ/container-httpd/pull/12)

## Unreleased as of Sprint 67 ending 2017-08-21

### Added
- Platform
  - Foundational update to container-httpd to support external authentication [(#10)](https://github.com/ManageIQ/container-httpd/pull/10)
