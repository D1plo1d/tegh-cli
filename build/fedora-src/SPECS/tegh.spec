Name:      tegh
Version:   0.2.0
Release:   1%{?dist}
Summary:   Tea Earl Grey Hot. A 3D Printer Client.
License:   MIT
Requires:  nodejs-devel >= 0.10.5, npm
BuildArch: noarch
URL:       https://github.com/D1plo1d/tegh
Source0:   https://github.com/D1plo1d/tegh/archive/master.tar.gz


%description
A simple command line interface for connecting to 3D printers via the Construct Protocol.

# %_datadir /usr/share/
# %_bindir /usr/bin

%build
#nothing to do

%define _use_internal_dependency_generator 0

%install
mkdir -p %{buildroot}%{_bindir}/
mkdir -p %{buildroot}%{_datadir}/%{name}/

cd %{_builddir}/../../../
rm -f "%{_topdir}/BUILD/master.tar.gz"
tar --exclude="./build" --exclude="./.git" --exclude="./bin/packages" -cpzf "/tmp/tegh-fedora-build.tar.gz" "./"
mv "/tmp/tegh-fedora-build.tar.gz" "%{_topdir}/SOURCES/master.tar.gz"

cp -pr src package.json %{buildroot}%{_datadir}/%{name}/
mkdir %{buildroot}%{_datadir}/%{name}/bin
cp bin/tegh %{buildroot}%{_datadir}/%{name}/bin/tegh

echo `%{_datadir}`
echo "node %{_datadir}/%{name}/bin/tegh" > %{buildroot}%{_bindir}/tegh


%clean
rm -rf %buildroot


%post
cd %{_datadir}/%{name}/
npm install


%files
%defattr(755,root,root,755)
%{_bindir}/*
%{_datadir}/%{name}/


%changelog
* Wed Jul 03 2013 D1plo1d <d1plo1d@d1plo1d.com> - 0.2.0-rc4
- Initial version of the package

