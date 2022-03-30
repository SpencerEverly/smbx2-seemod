# Running SMBX2 on Linux and macOS
It's possible to run SMBX2 on Linux and macOS with using of Wine.


## Content
* System requirements
* Install Wine
  * Linux
  * macOS
* Configure and install libraries
* Starting SMBX2
* Using native PGE Editor for Linux and macOS with LunaTester
  * Preparing a config pack
  * Using Editor
  * Troubleshooting


## System requirements
To have SMBX2 working, you need to have your OpenGL working and have all your
video drivers be installed and configured properly.


## Install Wine

### Linux
It's highly recommended to install the newest Wine from the official site:
https://wiki.winehq.org/Download

- Choose your distro in the list (for example, Debian or Ubuntu)
- Follow the guide on the page to add the Wine's repository to your system.
- If you already have the wine installed from system repositories,
  please uninnstall it to get the ability to install newer version.
- Install the Wine and if needed, the winetricks which may be installed
  separately if not came with regular wine installation.

### macOS
**CAUTION:** Since macOS 10.15 (Catalina), it's will be impossible to run a game
because of removed support for 32-bit applications. Wine will not work until a
workaround will be developed to get back an ability to run 32-bit Windows
applications. Therefore you should: use a virtual machine or, alternatively,
use an older macOS version (10.14 Mojave and older).

First off, you will need to have Homebrew be installed.
If you haven't it, please install it:
https://brew.sh/

You will need to install XQuartz which is required for runtime of a Wine:
```
brew install Caskroom/cask/xquartz
```
After XQuartz installation, you will need to log out from your system
and login back to take changes of default X11 server to use the XQuartz.


Install Wine and Wine-Tricks:
```
brew install wine winetricks
```



## Configure and install libraries

After you have installed Wine, you'll need to configure it and install
additional libraries.

Run Wine configurer and set Windows 7 or higher as operating system version:
```
winecfg
```

To get a proper runtime, you need to install DirectX, Quartz and VB6 runtime:
```
winetricks arch=32 d3dx10_43
winetricks arch=32 dsound
winetricks arch=32 quartz
winetricks arch=32 vb6run
```


## Starting SMBX2
After you installed all necesary modules, feel free to run the `SMBX2.exe`
which will start the launcher of the game.




## Using native PGE Editor for Linux and macOS with LunaTester
Since 12'th of May 2019 it's also possible with using of Laboratory builds

Which you can take from here:
(http://wohlsoft.ru/docs/_laboratory/)[https://wohlsoft.ru/docs/_laboratory/]

Or compile by yourself from the source code by yourself:
(https://wohlsoft.ru/pgewiki/Building_PGE_From_sources)[https://wohlsoft.ru/pgewiki/Building_PGE_From_sources]


### Preparing a config pack
To use LunaTester, you need to install a config pack
into your local PGE installation. Most simple way to install everything
is running of "./install.sh" script in the root of SMBX2 folder.

**IMPORTANT NOTE:** on macOS to get the script working you need to install `gsed`
tool, it's possible to do via Homebrew:
```
brew install gnu-sed
```

### Do that manually when can't by script
If you can't use the "./install.sh" script, you can prepare config pack
manually yourself. First what is needed, a take the full copy of config pack
from the `data/PGE/configs` folder and put it into one of next folders:
- `~/.PGE_Project/configs/` on Linux
- `~/Library/Application Support/PGE Project/configs` on macOS

Then, open the `main.ini` inside of copied config pack in any text editor
(for example, `nano`. Don't use built-in `Text Editor` in macOS) and then,
find the next field:
```
application-path = ..
```

Replace it wilth next:
```
application-path = "/path/to/your/SMBX2/data"
```
Where "/path/to/your/SMBX2/data" is a full absulte path
to your SMBX2's data folder.

For example:
```
application-path = "/home/user/SMBX2-Beta4/data"
```

or on MacOS:
```
application-path = "/Users/user/SMBX2-Beta4/data"
```

### Using Editor
After you have made a proper config pack, try to start the Editor and choose the
config "SMBX2" or "SMBX2 \[Wine-Integration\]" config pack you will see in the
list of config packs. If you didn't saw any menus and editor have started with
config pack that isn't an SMBX2, then, open the "Configuration" menu and choose
the "Change configuration..." to get an ability to switch another config pack.

### Troubleshooting
If Editor started with errors of config packs (for example, missing graphics),
please check the `main.ini` of SMBX2-Integration config pack, did you set the
correct path to SMBX2's data folder or not? Also, be sure you have correctly
unpacked your SMBX2 installation and you didn't damaged any content of it.

