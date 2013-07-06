# Tegh

A simple command line interface for connecting to 3D printers via the Construct Protocol.


Note: Tegh requires a Construct Server to connect to and print with. In other words, you're going to need [Pronserve](https://github.com/kliment/Printrun/tree/experimental) installed on your printer.


## Installation

### Windows

Download the [Tegh Windows Installer][1]

[1]:https://s3.amazonaws.com/tegh_binaries/tegh-0.2.0-rc4-installer.exe

### OSX / Homebrew

`brew install http://git.io/Tgf1Kg --HEAD`

### Arch

`yaourt -S tegh`

### Ubuntu

1. [Install NodeJS from ppa:chris-lea/node.js][2]
[2]: https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager#ubuntu-mint
2. Install [tegh-x.y.z.deb][3]
[3]: https://s3.amazonaws.com/tegh_binaries/tegh-0.2.0-rc4.deb

## Useage

### Windows

Open program files / open all programs / open the Tegh folder / run Tegh

### Linux / OSX

To launch tegh from the command line type:

`tegh`

That's it. No need to configure anything at all. Tegh will automatically detect all the compatible printers on the network and let you choose one to connect to.


## Development

### Installing from Source

1. Install nodejs and npm
2. Install Coffeescript (`npm install -g coffee-script`)
3. `git clone git://github.com/D1plo1d/Tegh.git;cd Tegh;npm install`

*Note:* If you are using vagrant to test Ubuntu you will need to use
`npm install --no-bin-link` instead of `npm install`.


### Running Tegh

#### Linux/OSX

`./bin/tegh`

#### Windows

`node "./node_modules/coffee-script/bin/coffee" ./src/tegh.coffee`


### Packaging

#### Windows

1. Download [node.exe][10] and save it as bin/node.exe
[10]: http://nodejs.org/dist/latest/node.exe
1. Spin up a Windows VM
3. Share tegh's folder with the VM
4. Install [InnoSetup](http://www.jrsoftware.org/isinfo.php)
5. Open bin/windows.iss with InnoSetup and compile it

This generates a install script in bin/setup.exe


