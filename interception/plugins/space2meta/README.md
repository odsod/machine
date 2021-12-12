# space2meta

Turn your space key into the meta key (a.k.a. win key or OS key) when chorded
to another key (on key release only).

## Dependencies

- [Interception Tools][interception-tools]

## Building

```
$ git clone git@gitlab.com:interception/linux/plugins/space2meta.git
$ cd space2meta
$ cmake -Bbuild
$ cmake --build build
```

## Execution

`space2meta` is an [_Interception Tools_][interception-tools] plugin. A suggested
`udevmon` job configuration is:


```yaml
- JOB: "intercept -g $DEVNODE | space2meta | uinput -d $DEVNODE"
  DEVICE:
    EVENTS:
      EV_KEY: [KEY_SPACE]

```

To compose functionality with [`caps2esc`], for example, you do:

```yaml
- JOB: "intercept -g $DEVNODE | caps2esc | space2meta | uinput -d $DEVNODE"
  DEVICE:
    EVENTS:
      EV_KEY: [KEY_CAPSLOCK, KEY_ESC, KEY_SPACE]

```

For more information about the [_Interception Tools_][interception-tools], check
the project's website.

## Installation

I'm maintaining an Archlinux package on AUR:

- <https://aur.archlinux.org/packages/interception-space2meta>

I don't use Ubuntu and recommend Archlinux instead, as it provides the AUR, so I
don't maintain PPAs. For more information on Ubuntu/Debian installation check
this:

- <https://askubuntu.com/questions/979359/how-do-i-install-caps2esc>

## Caveats

As always, there's always a caveat:

- visual delay when inserting space.
- `intercept -g` will "grab" the detected devices for exclusive access.
- If you tweak your key repeat settings, check whether they get reset.
  Please check [this report][key-repeat-fix] about the resolution.

## License

<a href="https://gitlab.com/interception/linux/plugins/caps2esc/blob/space2meta/LICENSE.md">
    <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/License_icon-mit-2.svg/120px-License_icon-mit-2.svg.png" alt="MIT">
</a>

Copyright © 2019 Francisco Lopes da Silva

[interception]: https://github.com/oblitum/Interception
[`caps2esc`]: https://gitlab.com/interception/linux/plugins/caps2esc
[interception-tools]: https://gitlab.com/interception/linux/tools
[key-repeat-fix]: https://github.com/oblitum/caps2esc/issues/1
