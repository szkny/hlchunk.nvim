## TODO:

- [x] when move cursor in visual mode, the selection background color will be hovered

  use when set `virt_text`, use `hl_mode = "combine"` option

- [ ] when one hunk is in another hunk, don't highlight the outer hunk, such as this situation under, when cursor at x, please highlight the inner hunk at right

```
{
    {

    },
 x  {

    }
}
```

- [x] add indent line highlight

- [ ] try to add treesitter support, because the syntax base on regex is so slow and not accurate

- [ ] set the indent more highlighting support

- [ ] please update README

- [ ] add support for single style of hl_indent