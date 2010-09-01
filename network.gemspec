# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name         = "alovak-network"
  s.version      = "1.2.0"
  s.author       = "Pavel Gabriel"
  s.homepage     = "http://github.com/alovak/network/"
  s.summary      = "HTTP/HTTPS communication module based on ruby net/http, net/https modules"
  s.description  = "HTTP/HTTPS communication module with logging, filtering and easy SSL configuration"
  s.email        = "alovak@gmail.com"
  s.require_path = "lib"
  s.has_rdoc     = false
  s.files        = ["lib/network/connection.rb", "lib/network.rb"]
  s.test_files   = ["test/network/test_network.rb", "test/network/test_connection.rb", "test/test_helper.rb"]
  s.rubygems_version = "1.3.0"
  s.add_dependency("mocha", [">= 0.9.7"])
end
