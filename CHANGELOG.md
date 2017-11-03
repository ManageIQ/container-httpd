# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Gaprindashvili Beta1

### Added
- Renaming auth_api to dbus_api service to reflect the new ManageIQ/dbus_api_service [(#28)](https://github.com/ManageIQ/container-httpd/pull/28)
- Updated container-httpd to include files only it can serve. [(#24)](https://github.com/ManageIQ/container-httpd/pull/24)
- Added support for the auth-api service in the httpd pod. [(#15)](https://github.com/ManageIQ/container-httpd/pull/15)
- Allow oci-systemd hooks to properly engage [(#14)](https://github.com/ManageIQ/container-httpd/pull/14)
- Added support for an httpd authentication configuration map [(#12)](https://github.com/ManageIQ/container-httpd/pull/12)
- Foundational update to container-httpd to support external authentication [(#10)](https://github.com/ManageIQ/container-httpd/pull/10)

### Fixed
- initialize-httpd-auth.service was no longer honoring ext-auth environment. [(#25)](https://github.com/ManageIQ/container-httpd/pull/25)
- httpd service waits for /etc/container-env file to be created [(#20)](https://github.com/ManageIQ/container-httpd/pull/20)
- Fixed bug with initialize-httpd-auth script. [(#22)](https://github.com/ManageIQ/container-httpd/pull/22)
- Fixed httpd startup issue [(#17)](https://github.com/ManageIQ/container-httpd/pull/17)
- Fixed issue where SSSD wasn't started after an auth configmap update. [(#16)](https://github.com/ManageIQ/container-httpd/pull/16)

## Initial changelog added
