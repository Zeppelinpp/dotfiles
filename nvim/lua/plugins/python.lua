return {
  -- Configure pyright to disable type checking and warnings
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {
          -- Use ruff only as a formatter, disable all linting
          init_options = {
            settings = {
              lint = {
                enable = false,
              },
            },
          },
        },
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "off",
                diagnosticMode = "openFilesOnly",
                diagnosticSeverityOverrides = {
                  reportGeneralTypeIssues = "none",
                  reportOptionalMemberAccess = "none",
                  reportOptionalSubscript = "none",
                  reportPrivateImportUsage = "none",
                  reportUnusedImport = "none",
                  reportUnusedClass = "none",
                  reportUnusedFunction = "none",
                  reportUnusedVariable = "none",
                  reportWildcardImportFromLibrary = "none",
                  reportUntypedFunctionDecorator = "none",
                  reportUntypedClassDecorator = "none",
                },
              },
            },
          },
        },
      },
    },
  },
}
