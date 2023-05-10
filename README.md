# YetAnotherScoreboard

[![Steam Workshop](https://img.shields.io/static/v1?message=workshop&logo=steam&labelColor=gray&color=blue&logoColor=white&label=steam%20)](https://steamcommunity.com/sharedfiles/filedetails/?id=2521826524)
[![Steam Downloads](https://img.shields.io/steam/downloads/2521826524)](https://steamcommunity.com/sharedfiles/filedetails/?id=2521826524)
[![Steam Favorites](https://img.shields.io/steam/favorites/2521826524)](https://steamcommunity.com/sharedfiles/filedetails/?id=2521826524)
[![MegaLinter](https://github.com/GenZmeY/KF2-YetAnotherScoreboard/actions/workflows/mega-linter.yml/badge.svg?branch=master)](https://github.com/GenZmeY/KF2-YetAnotherScoreboard/actions/workflows/mega-linter.yml)
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/GenZmeY/KF2-YetAnotherScoreboard)](https://github.com/GenZmeY/KF2-YetAnotherScoreboard/tags)
[![GitHub](https://img.shields.io/github/license/GenZmeY/KF2-YetAnotherScoreboard)](LICENSE)

## Description
Yet another scoreboard...
Based on the scoreboard from [ClassicHUD](https://steamcommunity.com/sharedfiles/filedetails/?id=1963099942) and heavily modified.

## Usage
[See steam workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=2521826524)

***

**Note:** If you want to build/test/brew/publish a mutator without git-bash and/or scripts, follow [these instructions](https://tripwireinteractive.atlassian.net/wiki/spaces/KF2SW/pages/26247172/KF2+Code+Modding+How-to) instead of what is described here.

## Build
1. Install [Killing Floor 2](https://store.steampowered.com/app/232090/Killing_Floor_2/), Killing Floor 2 - SDK and [git for windows](https://git-scm.com/download/win);
2. open git-bash and go to any folder where you want to store sources:  
`cd <ANY_FOLDER_YOU_WANT>`  
3. Clone this repository and go to the source folder:  
`git clone https://github.com/GenZmeY/KF2-YetAnotherScoreboard && cd KF2-YetAnotherScoreboard`
4. Download dependencies:  
`git submodule init && git submodule update`  
5. Compile:  
`./tools/builder -c`  
5. The compiled files will be here:  
`C:\Users\<USERNAME>\Documents\My Games\KillingFloor2\KFGame\Unpublished\BrewedPC\Script\`

## Testing
Open git-bash in the source folder and run command:  
`./tools/builder -t`  
(or `./tools/builder -ct` if you haven't compiled the mutator yet)  

A local single-user test will be launched with parameters from `test.cfg` (edit this file if you want to test mutator with different parameters).

## Bug reports
If you find a bug, go to the [issue page](https://github.com/GenZmeY/KF2-YetAnotherScoreboard/issues) and check if there is a description of your bug. If not, create a new issue.  
Describe what the bug looks like and how reproduce it.  
Attach screenshots if you think it might help.

If it's a crash issue, be sure to include the `Launch.log` files. You can find them here:  
`C:\Users\<USERNAME>\Documents\My Games\KillingFloor2\KFGame\Logs\`  
Please note that these files are overwritten every time you start the game/server. Therefore, you must take these files immediately after the game crashes in order not to lose information.

## License
[![license](https://www.gnu.org/graphics/gplv3-with-text-136x68.png)](LICENSE)
[![license](https://www.gnu.org/graphics/lgplv3-with-text-154x68.png)](https://github.com/GenZmeY/KF2-BoxPainterLib/blob/master/LICENSE)
