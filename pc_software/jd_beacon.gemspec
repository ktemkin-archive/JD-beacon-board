Gem::Specification.new do |s|
  s.name        = "jd_beacon"
  s.version     = "1.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kyle J. Temkin"]
  s.email       = ["ktemkin@binghamton.edu"]
  s.homepage    = "http://github.com/ktemkin/jd-beacon-board"
  s.summary     = "Beacon interfacing for the Junior Design game at Binghamton University"
  s.description = "A simple library for interfacing with custom PCB \"beacon boards\", used for a game originally run at Binghamton University."

  s.required_rubygems_version = ">= 1.3.6"

  #Require-all, which allows us to easily import whole folders.
  s.add_dependency 'require_all', '~>1.2.1'

  #Web front-end libraries.
  s.add_dependency 'sinatra',       '~>1.4.4'
  s.add_dependency 'compass',       '~>0.12.2'
  s.add_dependency 'barista',       '~>1.3.0'
  s.add_dependency 'haml',          '~>4.0.0'
  s.add_dependency 'therubyracer',  '~>0.12.1'

  #Serial port library, for communicating with the beacon board.
  s.add_dependency 'serialport', '~>1.1.0'

  #Binary Data Structure library, for parsing/generating serial communications.
  s.add_dependency 'bindata', '~>1.5.1'
  s.add_dependency 'ruby-wmi', '~>0.4.0'

  # If you need to check in files that aren't .rb files, add them here
  s.files        = Dir["{lib}/**/*.rb"]
  s.require_path = 'lib'

  # If you need an executable, add it here
  s.executables = []

  # If you have C extensions, uncomment this line
  # s.extensions = "ext/extconf.rb"
end
