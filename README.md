# Tegh

A simple command line interface for connecting to 3D printers via the Construct Protocol.


Note: Tegh requires a Construct Server to connect to and print with. In other words, you're going to need [construct-daemon](https://github.com/D1plo1d/construct-daemon) installed on your printer.


## Installation

**Windows**: [Tegh Windows Installer][1]

[1]:https://s3.amazonaws.com/tegh_binaries/0.3.0/tegh-0.3.0-setup.exe

**OSX**: `brew tap D1plo1d/tegh; brew install tegh`

**Arch**: `yaourt -S tegh`

**Fedora**: [tegh-0.3.0-1.noarch.rpm][2314]

[2314]:https://s3.amazonaws.com/tegh_binaries/0.3.0/tegh-0.3.0-1.noarch.rpm

**Ubuntu:**

1. [Install NodeJS from ppa:chris-lea/node.js][2]
[2]: https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager#ubuntu-mint
2. Install [tegh-0.3.0.deb][3]
[3]: https://s3.amazonaws.com/tegh_binaries/0.3.0/tegh-0.3.0.deb


## Useage

### Windows

Open program files / open all programs / open the Tegh folder / run Tegh

### Linux / OSX

To launch tegh from the command line type:

`tegh`

That's it. No need to configure anything at all. Tegh will automatically detect all the compatible printers on the network and let you choose one to connect to.


## Development

See the [Developers Guide](https://github.com/D1plo1d/tegh/wiki/Developers-Guide)




