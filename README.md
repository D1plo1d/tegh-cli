# QueueTea

A simple command line interface for connecting to 3D printers via the Construct Protocol.


Note: QueueTea requires a Construct Server to connect to and print with. In other words, you're going to need [Pronserve](https://github.com/D1plo1d/Printrun/tree/pronserve) installed on your printer.


## Developers

This is a guide to installing and using queuetea for developers. If you are not a developer you may find this difficult.


Suffice to say, here be dragons.


Good luck and happy printing.


### Installation

1. Install avahi-daemon (Linux) or bonjour (OSX) or bonjour-windows (Windows)
2. Install nodejs and npm
3. Install Coffeescript (`npm install -g coffee-script`)
4. `git clone git://github.com/D1plo1d/queuetea.git;cd queuetea;npm install`

#### Ubuntu Installation (Untested)

These instructions borrow heavily from

1. Install NodeJS: https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager
2. `sudo apt-get install nodejs avahi-daemon libavahi-compat-libdnssd-dev`
3. `sudo npm install -g coffee-script`
4. `git clone git://github.com/D1plo1d/queuetea.git;cd queuetea;npm install`

#### Arch Installation (Untested)

1. `pacman -S avahi nss-mdns nodejs coffee-script`
3. `git clone git://github.com/D1plo1d/queuetea.git;cd queuetea;npm install`


### Usage

`./queuetea`
