# GRAPHICS::FRAMEBUFFER TESTS

[![Graphics::Framebuffer Logo](../GFB.png?raw=true "Graphics::Framebuffer")](https://youtu.be/qU5IFmtHmUo)

# ENVIRONMENT VARIABLES FOR TESTING

* GFB_NOACCEL=1
* GFB_NOSPLASH=1
* GFB_DELAY=0.25
* GFB_IGNORE_X=1
* GFB_SMALL=1

For "make test" you can set these variables to change the test behavior.

For example:
```
    GFB_IGNORE_X=1 make test
```
