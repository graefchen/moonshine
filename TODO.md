# TODO's

> [!note]
> Lua is tiny and does not have a good file-system library inbuild thath allows changing the directory (`chdir`) getting the current directory (`pwd`), maging an directory (`mkdir`), removing an directory (`rmdir`) and many more.
> And because of that I am in the need find a decent solution to solve this problem.
>
> The solution I thought of was to use a _shell script_ (can be `bash`, `elvish`, `nushell`, etc.) that lets you deal with those problems, but also write a (hopefully) _minimal_ INI-parser, described in the [ini-lua section](#ini.lua).

## ini.lua

Useful references:

- https://gitlab.com/whoatemybutter/pyini
- https://en.wikipedia.org/wiki/INI_file

```ìni
[site]
files=file1,file2,file3
```
