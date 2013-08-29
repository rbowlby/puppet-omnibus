class Passenger < FPM::Cookery::Recipe
  description 'Passenger'

  name 'passenger'
  version '4.0.14'
  homepage 'https://www.phusionpassenger.com/'
  source "nothing", :with => :noop

  platforms [:fedora, :redhat, :centos] do
        build_depends 'apr-util-devel', 'apr-devel','httpd-devel', 'ruby-devel',
                      'zlib-devel', 'openssl-devel', 'libcurl-devel', 'gcc-c++'
  end

  def build
    # Install gems using the gem command from destdir
    gem_install 'passenger',   '4.0.14'

    # build mod_passenger apache ext
    cleanenv_safesystem "#{destdir}/bin/passenger-install-apache2-module --auto"
  end

  def install
  end

  def gem_install(name, version = nil)
    v = version.nil? ? '' : "-v #{version}"
    cleanenv_safesystem "#{destdir}/bin/gem install --no-ri --no-rdoc #{v} #{name}"
  end

end
