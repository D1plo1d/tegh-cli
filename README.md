# Tegh

A simple command line interface for controlling 3D printers via the Construct Protocol.

Note: Tegh requires a Construct Server to connect to and print with. In other words, you're going to need [construct-daemon](https://github.com/D1plo1d/construct-daemon) installed on your printer.


## Features

* **WiFi 3D Printer Control** - No need to tether your laptop to the 3D printer for hours anymore. Print from anywhere in the house.
* **Network Discoverablity** - All 3D printers with construct-daemon on the network will show up automatically.
* **Queue your Print Jobs** - Add as many print jobs as you want. It's easy to manage your prints whether printing is fully or semi-autonomously. Try it out with the Makerbot ABP for extra-awesome automation!
* **Automatic Slicing** - Slicing is done by CuraEngine automatically. Just configure your printers' profiles in the `~/.construct/cura_engine` directory and it will automatically slice any 3D models added to the queue.


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

**Everything Except Windows**: `tegh`

**Windows**: Open program files / open all programs / open the Tegh folder / run Tegh


## Development

See the [Developers Guide](https://github.com/D1plo1d/tegh/wiki/Developers-Guide)




