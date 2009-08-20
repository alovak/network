# -*- encoding: utf-8 -*-
 
Gem::Specification.new do |s|
  s.name         = "network"
  s.version      = "1.0.0"
  s.author       = "Pavel Gabriel"
  s.homepage     = "http://github.com/alovak/network/"
  s.summary      = "HTTP/HTTPS communication module based on ruby net/http, net/https modules"
  s.description  = File.read(File.join(File.dirname(__FILE__), 'README'))
  s.description  = "HTTP/HTTPS communication module based on ruby net/http, net/https modules"
  s.email        = "alovak@gmail.com"
  s.require_path = "lib"
  s.has_rdoc     = false
  s.files        = Dir['**/**'] 
  s.test_files   = Dir["test/**/test*.rb"]
  s.rubygems_version = "1.3.0"
  s.add_dependency("mocha", ["= 0.9.7"])
  s.add_dependency("turn",  [">= 0.6.0"])
end

