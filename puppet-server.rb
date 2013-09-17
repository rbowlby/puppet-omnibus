class PuppetServerGem < FPM::Cookery::Recipe
  description 'Puppet Server gem stack'

  name 'puppet'
  version '3.2.3'

  source "nothing", :with => :noop

  platforms [:ubuntu, :debian] do
    build_depends 'libaugeas-dev', 'pkg-config'
    depends 'libaugeas0', 'pkg-config'
  end

  platforms [:fedora, :redhat, :centos] do
    build_depends 'augeas-devel', 'pkgconfig'
    depends 'augeas-libs', 'pkgconfig'
  end

  def build
    # Install gems using the gem command from destdir
    gem_install 'facter',      '1.7.1'
    gem_install 'json_pure',   '1.6.3'
    gem_install 'hiera',       '1.2.1'
    gem_install 'deep_merge',  '1.0.0'
    gem_install 'rgen',        '0.6.5'
    gem_install 'ruby-augeas', '0.4.1'
    gem_install 'ruby-shadow', '2.2.0'
    gem_install 'gpgme',       '2.0.2'
    gem_install name,          version

    # install puppetdb-terminus gem, not in rubygems yet
    system "curl -L https://github.com/puppetlabs/puppetdb/tarball/master | tar zx --directory=#{builddir}"
    system "git clone https://github.com/puppetlabs/puppetdb"
    Dir.chdir("#{builddir}/puppetdb"){
      system "gem build contrib/gem/puppetdb-terminus.gemspec"
    }
    cleanenv_safesystem "#{destdir}/bin/gem install --no-ri --no-rdoc #{builddir}/puppetdb/puppetdb-terminus-1.0.gem"
    system "cp -R #{destdir}/lib/ruby/gems/1.9.1/gems/puppetdb-terminus-1.0/puppet/lib/puppet/* #{destdir}/lib/ruby/gems/1.9.1/gems/puppet-3.2.3/lib/puppet/"

    # Download init scripts and conf
    build_files
  end

  def install
    # Install init-script and puppet.conf
    install_files

    # Provide 'safe' binaries in /opt/<package>/bin like Vagrant does
    rm_rf "#{destdir}/../bin"
    destdir('../bin').mkdir
    destdir('../bin').install workdir('omnibus.bin'), 'puppet'
    destdir('../bin').install workdir('omnibus.bin'), 'facter'
    destdir('../bin').install workdir('omnibus.bin'), 'hiera'

    # Symlink binaries to PATH using update-alternatives
    with_trueprefix do
      create_post_install_hook
      create_pre_uninstall_hook
    end
  end

  private

  def gem_install(name, version = nil)
    v = version.nil? ? '' : "-v #{version}"
    cleanenv_safesystem "#{destdir}/bin/gem install --no-ri --no-rdoc #{v} #{name}"
  end

  platforms [:ubuntu, :debian] do
    def build_files
      system "curl -O https://raw.github.com/puppetlabs/puppet/#{version}/ext/debian/puppet.conf"
      system "curl -O https://raw.github.com/puppetlabs/puppet/#{version}/ext/debian/puppet.init"
      system "curl -O https://raw.github.com/puppetlabs/puppet/#{version}/ext/debian/puppet.default"
      # Set the real daemon path in initscript defaults
      system "echo DAEMON=#{destdir}/bin/puppet >> puppet.default"
    end
    def install_files
      etc('puppet').mkdir
      etc('puppet').install builddir('puppet.conf') => 'puppet.conf'
      etc('init.d').install builddir('puppet.init') => 'puppet'
      etc('default').install builddir('puppet.default') => 'puppet'
      chmod 0755, etc('init.d/puppet')
    end
  end

  platforms [:fedora, :redhat, :centos] do
    def build_files
      system "curl -O https://raw.github.com/puppetlabs/puppet/#{version}/ext/redhat/puppet.conf"
      system "curl -O https://raw.github.com/puppetlabs/puppet/#{version}/ext/redhat/fileserver.conf"
      system "curl -O https://raw.github.com/puppetlabs/puppet/#{version}/ext/redhat/client.init"
      system "curl -O https://raw.github.com/puppetlabs/puppet/#{version}/ext/redhat/client.sysconfig"
      system "curl -O https://raw.github.com/puppetlabs/puppet/#{version}/ext/redhat/server.init"
      system "curl -O https://raw.github.com/puppetlabs/puppet/#{version}/ext/redhat/server.sysconfig"
      # Set the real daemon path in initscript defaults
      system "echo PUPPETD=#{destdir}/bin/puppet >> client.sysconfig"
    end
    def install_files
      etc('puppet').mkdir
      etc('puppet/manifests').mkdir
      etc('puppet').install builddir('puppet.conf') => 'puppet.conf'
      etc('puppet').install builddir('fileserver.conf') => 'fileserver.conf'
      etc('init.d').install builddir('client.init') => 'puppet'
      etc('init.d').install builddir('server.init') => 'puppetmaster'
      etc('sysconfig').install builddir('client.sysconfig') => 'puppet'
      etc('sysconfig').install builddir('server.sysconfig') => 'puppetmaster'
      chmod 0755, etc('init.d/puppet')
      chmod 0755, etc('init.d/puppetmaster')
    end
  end

  def create_post_install_hook
    File.open(builddir('post-install'), 'w', 0755) do |f|
      f.write <<-__POSTINST
#!/bin/sh
set -e

BIN_PATH="#{destdir}/bin"
BINS="puppet facter hiera"

for BIN in $BINS; do
  /bin/sh -c "sleep 15 && update-alternatives --install /usr/bin/$BIN $BIN $BIN_PATH/$BIN 100" &
done

exit 0
      __POSTINST
    end
  end

  def create_pre_uninstall_hook
    File.open(builddir('pre-uninstall'), 'w', 0755) do |f|
      f.write <<-__PRERM
#!/bin/sh
set -e

BIN_PATH="#{destdir}/bin"
BINS="puppet facter hiera"

if [ $1 -eq 0 ]; then
  for BIN in $BINS; do
    update-alternatives --remove $BIN $BIN_PATH/$BIN
  done
fi

exit 0
      __PRERM
    end
  end

end
