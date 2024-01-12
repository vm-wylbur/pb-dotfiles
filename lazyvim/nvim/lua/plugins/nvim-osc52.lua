-- TODO: only needed on headless linux boxen
if vim.fn.hostname() == "scott" then
return {
  "ojroques/nvim-osc52",
  opts = {
    silent = true, 
  }
}
else
  return { } 
end 
-- done.
