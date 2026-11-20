# gbak

A "unikernel" for the Game Boy Advance (GBA).

It is done in the context of the `GameBoy Advance` UserGroup at Epitech (by [Yann MAGNIN](https://github.com/YannMAGNIN)). The subject is also in this repo ([subject.pdf](./subject.pdf)).

This project requires Zig `0.17.x`.

## SDK

gbak has a related SDK (`gbasdk`) to check information about cartridges.

**Building**

```sh
cd sdk
zig build
./zig-out/bin/gbasdk --help
```
