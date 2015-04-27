# NowListening

iTunes playing information share (Twitter) appliet

## Requirements

* `iTunes.h` is required. You can generate with `sdef /Applications/iTunes.app | sdp -fh --basename iTunes`
* After create `iTunes.h`, put it in same level of `Put_iTunes.h_here` file.

## Licence

* NYSL (http://www.kmonos.net/nysl/) 0.9981
* __You use AT YOUR OWN RISK__

## Usage

1. Generate `iTunes.h` by `sdef /Applications/iTunes.app | sdp -fh --basename iTunes`.
2. Put `iTunes.h` in same level of `Put_iTunes.h_here` file.
3. Open project with Xcode.
4. `⌘+R` for build and run application.
5. Application will appear in toolbar as `♮`.
6. Push `♮`. If you are listening music with iTunes, title will appear in menu.
7. If you set twitter account in `System preference` > `Internet accounts`, your twitter accounts will appear in choices.
    * You can share your playing information by pushing twitter account name.
    * __Playing information will be shared without confirmations. Please be careful.__
8. You can close application by pushing `Quit` in menu.
