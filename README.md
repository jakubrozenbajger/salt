# salt - simple Agnoster-like theme
This is a fork of [AgnosterZak](https://github.com/zakaziko99/agnosterzak-ohmyzsh-theme)

It currently shows:
- Timestamp
- Current directory
- Git status
- Virtualenv status
- User & Host status

## Preview
![Preview](img/prompt.png)


## Requirements
 - Powerline fonts

## Installing

```shell script
source salt.zsh-theme
```

or using plugin manager 

```shell script
zinit light rozenj/salt
```

### Settings
|Variable                   |Default value  |
|---------------------------|---------------|
|`SALT_PROMPT_TIME`         |`false`        |
|`SALT_PROMPT_VI`           |`true`         |
|`SALT_PROMPT_VENV`         |`true`         |
|`SALT_PROMPT_GIT`          |`true`         |
|`SALT_SEGMENT_SEPARATOR`   |<empty>        |
|`SALT_ENDL_SEPARATOR`      |<empty>        |


#### Git icons
|Icon|Meaning
|----|-------|
|`✔`|clean directory
|`☀`|new untracked files preceeded by their number
|`✚`|added files from the new untracked ones preceeded by their number
|`‒`|deleted files preceeded by their number
|`●`|modified files preceeded by their number
|`±`|added files from the modifies or delete ones preceeded by their number
|`⚑`|ready to commit
|`⚙`|sets of stashed files preceeded by their number
|`☊`|branch has a stream, preceeded by his remote name
|`↑`|commits ahead on the current branch comparing to remote, preceeded by their number
|`↓`|commits behind on the current branch comparing to remote, preceeded by their number
|`<B>`|bisect state on the current branch
|`>M<`|Merge state on the current branch
|`>R>`|Rebase state on the current branch
