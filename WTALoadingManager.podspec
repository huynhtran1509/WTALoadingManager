Pod::Spec.new do |s|
  s.name         = "WTALoadingManager"
  s.version      = "0.0.3"
  s.summary      = "WTALoadingManager wraps boilerplate loading and network logic."
  s.homepage     = "https://github.com/willowtreeapps/WTALoadingManager"
  s.license      = 'MIT'
  s.author       = { "WillowTree Apps" => "" }
  s.source       = { :git => "git@github.com:willowtreeapps/WTALoadingManager.git", :tag => s.version }
  s.source_files = 'Classes', 'Classes/**/*.{h,m}'
  s.requires_arc = true
end
