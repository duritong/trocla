# Generated from trocla-0.1.2.gem by gem2rpm -*- rpm-spec -*-
%global gem_name trocla

Name: rubygem-%{gem_name}
Version: 0.2.0
Release: 1%{?dist}
Summary: Trocla a simple password generator and storage
Group: Development/Languages
License: GPLv3
URL: https://tech.immerda.ch/2011/12/trocla-get-hashed-passwords-out-of-puppet-manifests/
Source0: https://rubygems.org/gems/%{gem_name}-%{version}.gem
Requires: rubygem-moneta
Requires: rubygem-bcrypt
Requires: rubygem-highline
BuildRequires: rubygem-moneta = 0.7.20
BuildRequires: rubygem-bcrypt
BuildRequires: rubygem-highline
BuildRequires: ruby(release)
BuildRequires: rubygems-devel
BuildRequires: ruby
# BuildRequires: rubygem(mocha)
# BuildRequires: rubygem(rspec) => 2.4
# BuildRequires: rubygem(rspec) < 3
# BuildRequires: rubygem(jeweler) => 1.6
# BuildRequires: rubygem(jeweler) < 2
BuildArch: noarch

%description
Trocla helps you to generate random passwords and to store them in various
formats (plain, MD5, bcrypt) for later retrival.


%package doc
Summary: Documentation for %{name}
Group: Documentation
Requires: %{name} = %{version}-%{release}
BuildArch: noarch

%description doc
Documentation for %{name}.

%prep
gem unpack %{SOURCE0}

%setup -q -D -T -n  %{gem_name}-%{version}

gem spec %{SOURCE0} -l --ruby > %{gem_name}.gemspec

%build
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

# %%gem_install compiles any C extensions and installs the gem into ./%%gem_dir
# by default, so that we can move it into the buildroot in %%install
%gem_install

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* \
        %{buildroot}%{gem_dir}/


mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_sysconfdir}
mkdir -p %{buildroot}/%{_sharedstatedir}/%{gem_name}
touch %{buildroot}/%{_sharedstatedir}/%{gem_name}/%{gem_name}_data.yaml

cp -pa .%{_bindir}/* \
        %{buildroot}%{_bindir}/

chmod a+x %{buildroot}%{gem_instdir}/bin/%{gem_name}

cat <<EOF > %{buildroot}/%{_sysconfdir}/%{gem_name}rc.yaml
---
adapter: :YAML
adapter_options:
      :file: '%{_sharedstatedir}/%{gem_name}/%{gem_name}_data.yaml'
EOF

# Run the test suite
%check
pushd .%{gem_instdir}

popd

%files
%dir %{gem_instdir}
%{_bindir}/trocla
%{gem_instdir}/.rspec
%exclude %{gem_instdir}/.travis.yml
%exclude %{gem_instdir}/.rspec
%license %{gem_instdir}/LICENSE.txt
%{gem_instdir}/bin
%{gem_libdir}
%exclude %{gem_cache}
%{gem_spec}
%config(noreplace) %{_sysconfdir}/%{gem_name}rc.yaml
%dir %attr(755, root, root) %{_sharedstatedir}/%{gem_name}
%config(noreplace) %attr(660, root, root) %{_sharedstatedir}/%{gem_name}/%{gem_name}_data.yaml

%files doc
%doc %{gem_docdir}
%doc %{gem_instdir}/.document
%{gem_instdir}/Gemfile
%doc %{gem_instdir}/README.md
%{gem_instdir}/Rakefile
%{gem_instdir}/spec
%{gem_instdir}/trocla.gemspec

%changelog
* Mon Dec 21 2015 mh - 0.2.0-1
- Release of v0.2.0
* Sun Jun 21 2015 mh - 0.1.2-1
- Initial package
