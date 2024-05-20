return {
	"colepeters/spacemacs-theme.vim",
	-- dev = true,
	-- branch = "dev",
	lazy = false,
	priority = 1000,
	config = function()
		vim.cmd("colorscheme spacemacs-theme")
	end,
}
