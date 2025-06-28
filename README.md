# biome-lint.nvim
Run biome's linter and send diagnostic to quickfix list in neovim

## Installation

```lua
use {
  'AlexBeauchemin/biome-lint.nvim',
  config = function()
    require('biome-lint').setup()
  end
} 
```

## How to use

```
:BiomeLint
```
