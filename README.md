# avy-dashboard

avy keys is a simple function (and one defvar) that allows you to jump directly to a file rather than jump to a section and then
move up and down through the buffer. If you're used to avy, jumping is much more efficient.

Because we know the backing information for the various jump targets, we can do an exact search, find the start position, and use
avy to generate the jump targets from there.

Currently nothing is particularly configurable, which I may or may not fix. This is definitely fragile and relies on dashboard
maintaining the same backing information
