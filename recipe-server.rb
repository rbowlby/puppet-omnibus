class PuppetServerOmnibus < FPM::Cookery::Recipe
  homepage 'https://github.com/andytinycat/puppet-omnibus'

  section 'Utilities'
  name 'puppet-server-omnibus'
  version '3.2.3'
  description 'Puppet Server Omnibus package'
  revision 5
  vendor 'fpm'
  maintainer '<github@tinycat.co.uk>'
  license 'Apache 2.0 License'

  source '', :with => :noop

  conflicts 'puppet'
  conflicts 'puppet-server'

  provides 'puppet'
  provides 'puppet-server'
  provides 'facter'
  provides 'hiera'

  omnibus_package true
  omnibus_dir     "/opt/#{name}"
  omnibus_recipes 'libyaml',
                  'ruby',
                  'passenger',
                  'puppet-server'

  # Set up paths to initscript and config files per platform
  platforms [:ubuntu, :debian] do
    config_files '/etc/puppet/puppet.conf',
                 '/etc/init.d/puppet',
                 '/etc/default/puppet'
  end
  platforms [:fedora, :redhat, :centos] do
    config_files '/etc/puppet/puppet.conf',
                 '/etc/puppet/fileserver.conf',
                 '/etc/init.d/puppet',
                 '/etc/init.d/puppetmaster',
                 '/etc/sysconfig/puppet'
                 '/etc/sysconfig/puppetmaster'
  end
  omnibus_additional_paths config_files

  def build
    # Nothing
  end

  def install
    # Set paths to package scripts
    self.class.post_install builddir('post-install')
    self.class.pre_uninstall builddir('pre-uninstall')
  end

end
