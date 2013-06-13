# Tegh

A simple command line interface for connecting to 3D printers via the Construct Protocol.


Note: Tegh requires a Construct Server to connect to and print with. In other words, you're going to need [Pronserve](https://github.com/kliment/Printrun/tree/experimental) installed on your printer.


## Installation: Normal People Edition

If you are normal peoples or a lazy developer like me then these are the 
install docs for you! Hopefully your OS is listed below!

### OSX / Homebrew

`brew install https://raw.github.com/D1plo1d/homebrew/18bb5a9abe996f97175fed87a164faf038b21ce4/Library/Formula/tegh.rb --HEAD`


## Developers

This is a guide to installing and using Tegh for developers. If you are not a developer you may find this difficult.


Suffice to say, here be dragons.


Good luck and happy printing.


### Installation

1. Install nodejs and npm
2. Install Coffeescript (`npm install -g coffee-script`)
3. `git clone git://github.com/D1plo1d/Tegh.git;cd Tegh;npm install`

#### Ubuntu Installation (Untested)

1. Install NodeJS: https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager#ubuntu-mint
2. `sudo apt-get install nodejs`
3. `sudo npm install -g coffee-script`
4. `git clone git://github.com/D1plo1d/Tegh.git;cd Tegh;npm install`

*Note:* If you are using vagrant to test Ubuntu you will need to use
`npm install --no-bin-link` instead of `npm install`.

#### Arch Installation (Untested)

1. `pacman -S nodejs coffee-script`
2. `git clone git://github.com/D1plo1d/Tegh.git;cd Tegh;npm install`


#### Windows Installation (Work in progress)

1. Install nodejs and npm using the MSI installer
2. Reboot
3. Download this repository and open it in cmd as administrator
4. `npm install`


### Usage

#### Linux/OSX

`./bin/tegh`

#### Windows

`node "./node_modules/coffee-script/bin/coffee" ./src/queue_tea.coffee`
