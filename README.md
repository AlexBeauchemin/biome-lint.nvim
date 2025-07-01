# biome-lint.nvim
Run biome's linter and send diagnostic to quickfix list in neovim

![image](https://github.com/user-attachments/assets/39e1872f-fdde-4e0b-977b-7da0456322dc)

![image](https://github.com/user-attachments/assets/37033e27-6583-4ee7-b062-5bb26e28f4be)

![image](https://github.com/user-attachments/assets/55837eb1-5152-406d-8440-30cec5cb6204)


## Installation

With Lazy.nvim:
```lua
use {
  'AlexBeauchemin/biome-lint.nvim',
  config = function()
    require('biome-lint').setup({
      severity = "error", -- "error", "warn", "info". Default is "error"
    })
  end
} 
```

## How to use

```
:BiomeLint
```

### Inspiration

[tcs.nvim](https://github.com/dmmulroy/tsc.nvim) 
