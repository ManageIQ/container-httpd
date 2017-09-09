#!/usr/bin/bash

export PATH=$PATH:/opt/rubies/ruby-2.3.1/bin
cd /opt/rh/auth-api
bundle exec ruby ./auth_api_service.rb
